local UI = {}

UI.state = {
\topen = false,
\ttabs = {"List", "Safe", "Risky", "Vehicle", "Triggers"},
\tcurrentTab = 1,
\titems = {},
\tindex = 1,
\tscrollOffset = 0,
\tmaxVisible = 12,
\tkeybinds = {
\t\t{"Keybinds", ""},
\t\t{"Freecam", "Caps"},
\t\t{"Noclip", "~o~Caps"},
\t},
\tspectators = {
\t\t{"Spectators", "0"}
\t},
\tdescription = "",
}

UI.colors = {
\tbackground = {18,18,18,240},
\tpanel = {40,40,40,255},
\theader = {18,18,18,230},
\ttext = {235,235,235,255},
\ttextDim = {170,170,170,255},
\taccent = {71,133,255,255},
\thighlight = {90,140,255,220},
\tgood = {120,200,120,255},
}

UI.layout = {
\t-- Main menu metrics (normalized safezone units)
\tx = 0.10, y = 0.18, w = 0.28, h = 0.52,
\tradius = 0.004,
\trowH = 0.028,
\trowPad = 0.004,
\tsidebarW = 0.012, -- ~11 px
\tfooterH = 0.026,
\tlogoW = 0.171, -- scale to keep aspect ~371x105
\tlogoH = 0.048,
}

-- Populate demo items
for i=1,24 do
\tUI.state.items[i] = { label = ("Test control %02d"):format(i), desc = "Control dependent features" }
end

-- Draw helpers -------------------------------------------------------------

local function drawRect(x, y, w, h, r, g, b, a)
\tDrawRect(x + w*0.5, y + h*0.5, w, h, r, g, b, a)
end

local function drawText(txt, x, y, scale, color, center, font)
\tSetTextFont(font or 4)
\tSetTextScale(scale, scale)
\tSetTextColour(color[1], color[2], color[3], color[4])
\tSetTextCentre(center or false)
\tSetTextDropshadow(0, 0, 0, 0, 0)
\tSetTextOutline()
\tBeginTextCommandDisplayText('STRING')
\tAddTextComponentSubstringPlayerName(txt)
\tEndTextCommandDisplayText(x, y)
end

-- Rounded rectangle using 3x3 slices (cheap approximation)
local function roundedRect(x, y, w, h, radius, color)
\tlocal r,g,b,a = table.unpack(color)
\tlocal cr = radius
\t-- center
\tdrawRect(x+cr, y, w-2*cr, h, r,g,b,a)
\t-- sides
\tdrawRect(x, y, cr, h-2*cr, r,g,b,a)
\tdrawRect(x+w-cr, y, cr, h-2*cr, r,g,b,a)
\t-- corners (use squares to approximate)
\tdrawRect(x, y, cr, cr, r,g,b,a)
\tdrawRect(x+w-cr, y, cr, cr, r,g,b,a)
\tdrawRect(x, y+h-cr, cr, cr, r,g,b,a)
\tdrawRect(x+w-cr, y+h-cr, cr, cr, r,g,b,a)
end

-- Border
local function roundedRectBordered(x,y,w,h,radius, bgColor, borderColor, borderW)
\troundedRect(x - borderW, y - borderW, w + borderW*2, h + borderW*2, radius + borderW, borderColor)
\troundedRect(x, y, w, h, radius, bgColor)
end

-- Texture handling ---------------------------------------------------------
local bannerDict = 'phx_menu_banner'
local bannerName = 'banner'
local bannerLoaded = false

local function ensureBanner()
\tif bannerLoaded then return true end
\tif not CreateRuntimeTxd then return false end
\tlocal txd = CreateRuntimeTxd(bannerDict)
\tlocal dui = CreateDui('nui://game/ui/close.png', 371, 105) -- temporary
\t-- Try load file from asset path
\tlocal path = 'assets/banner.png'
\t-- LoadFile is not available; use CreateRuntimeTextureFromImage for FiveM
\tlocal success = pcall(function()
\t\tCreateRuntimeTextureFromImage(txd, bannerName, path)
\tend)
\tif not success then
\t\t-- fallback: simple color texture
\t\tCreateRuntimeTexture(txd, bannerName, 371,105)
\tend
\tbannerLoaded = true
\treturn true
end

local function drawBanner(x, y, w, h)
\tif ensureBanner() then
\t\tDrawSprite(bannerDict, bannerName, x + w*0.5, y + h*0.5, w, h, 0.0, 255,255,255,255)
\telse
\t\troundedRect(x, y, w, h, UI.layout.radius, {60,120,255,255})
\t\tdrawText('PHX', x + w*0.5, y + h*0.25, 0.6, UI.colors.text, true, 4)
\tend
end

-- Input -------------------------------------------------------------------
local function handleInput()
\t-- Up
\tif IsControlJustPressed(0, 172) then
\t\tUI.state.index = UI.state.index - 1
\t\tif UI.state.index < 1 then UI.state.index = #UI.state.items end
\t\tif UI.state.index <= UI.state.scrollOffset then
\t\t\tUI.state.scrollOffset = UI.state.index - 1
\t\tend
\tend
\t-- Down
\tif IsControlJustPressed(0, 173) then
\t\tUI.state.index = UI.state.index + 1
\t\tif UI.state.index > #UI.state.items then UI.state.index = 1 end
\t\tif UI.state.index > UI.state.scrollOffset + UI.state.maxVisible then
\t\t\tUI.state.scrollOffset = UI.state.index - UI.state.maxVisible
\t\tend
\tend
\t-- Tab
\tif IsControlJustPressed(0, 37) then
\t\tUI.state.currentTab = UI.state.currentTab % #UI.state.tabs + 1
\t\tUI.state.index = 1
\t\tUI.state.scrollOffset = 0
\tend
\t-- Toggle
\tif IsControlJustPressed(0, 191) then
\t\t-- no-op: hook actions here
\tend
\t-- Close (Esc)
\tif IsControlJustPressed(0, 177) then
\t\tUI.state.open = false
\tend
end

-- Panels ------------------------------------------------------------------
local function drawSidebar(x, y, h)
\troundedRect(x, y, UI.layout.sidebarW, h, UI.layout.radius, UI.colors.panel)

\t-- moving highlight block height equals row height
\tlocal visibleIndex = UI.state.index - UI.state.scrollOffset
\tif visibleIndex >= 1 and visibleIndex <= UI.state.maxVisible then
\t\tlocal hy = y + (UI.layout.rowH + UI.layout.rowPad) * (visibleIndex-1)
\t\troundedRect(x, hy, UI.layout.sidebarW, UI.layout.rowH, UI.layout.radius, UI.colors.highlight)
\tend
end

local function drawTabs(x, y, w)
\tlocal tabW = (w - UI.layout.sidebarW - 0.01) / #UI.state.tabs
\tfor i, name in ipairs(UI.state.tabs) do
\t\tlocal tx = x + UI.layout.sidebarW + 0.005 + (i-1) * tabW
\t\tlocal color = i == UI.state.currentTab and UI.colors.highlight or UI.colors.panel
\t\troundedRect(tx, y, tabW - 0.006, UI.layout.rowH, UI.layout.radius, color)
\t\tdrawText(name, tx + (tabW-0.006)/2, y + 0.0065, 0.28, UI.colors.text, true, 4)
\tend
end

local function drawList(x, y, w, h)
\tlocal startY = y
\tlocal startIndex = UI.state.scrollOffset + 1
\tlocal endIndex = math.min(#UI.state.items, UI.state.scrollOffset + UI.state.maxVisible)

\tfor i = startIndex, endIndex do
\t\tlocal idx = i - startIndex
\t\tlocal rowY = startY + idx * (UI.layout.rowH + UI.layout.rowPad)
\t\tlocal isSelected = (i == UI.state.index)
\t\tlocal bg = isSelected and UI.colors.highlight or UI.colors.panel
\t\troundedRect(x + UI.layout.sidebarW + 0.006, rowY, w - UI.layout.sidebarW - 0.012, UI.layout.rowH, UI.layout.radius, bg)
\t\tdrawText(UI.state.items[i].label, x + UI.layout.sidebarW + 0.014, rowY + 0.0065, 0.28, UI.colors.text, false, 4)
\tend

\t-- Footer beta and index
\tlocal footerY = y + h - UI.layout.footerH
\troundedRect(x, footerY, w, UI.layout.footerH, UI.layout.radius, UI.colors.panel)
\tdrawText("5291  |  BETA", x + 0.008, footerY + 0.005, 0.26, UI.colors.textDim, false, 4)
\tlocal indicator = ("%d/%d"):format(UI.state.index, #UI.state.items)
\tdrawText(indicator, x + w - 0.008, footerY + 0.005, 0.26, UI.colors.textDim, true, 4)
end

local function drawKeybinds(x, y)
\troundedRect(x, y, 0.12, 0.08, UI.layout.radius, UI.colors.panel)
\tfor i, pair in ipairs(UI.state.keybinds) do
\t\tdrawText(pair[1], x + 0.008, y + 0.005 + (i-1)*0.022, 0.26, UI.colors.textDim, false, 4)
\t\tdrawText(pair[2], x + 0.12 - 0.008, y + 0.005 + (i-1)*0.022, 0.26, UI.colors.text, true, 4)
\tend
end

local function drawSpectators(x, y)
\troundedRect(x, y, 0.12, 0.055, UI.layout.radius, UI.colors.panel)
\tfor i, pair in ipairs(UI.state.spectators) do
\t\tdrawText(pair[1], x + 0.008, y + 0.005 + (i-1)*0.022, 0.26, UI.colors.textDim, false, 4)
\t\tdrawText(pair[2], x + 0.12 - 0.008, y + 0.005 + (i-1)*0.022, 0.26, UI.colors.text, true, 4)
\tend
end

local function drawDescription()
\tlocal txt = UI.state.items[UI.state.index] and (UI.state.items[UI.state.index].desc or "") or ""
\tdrawText(txt, 0.5, 0.93, 0.30, UI.colors.text, true, 4)
end

-- Main draw ---------------------------------------------------------------
local function draw()
\tlocal L = UI.layout
\tlocal C = UI.colors

\t-- menu container
\troundedRectBordered(L.x, L.y, L.w, L.h, L.radius, C.background, C.panel, 0.001)

\t-- banner
\tdrawBanner(L.x + 0.006, L.y + 0.006, L.logoW, L.logoH)

\t-- tabs under banner
\tdrawTabs(L.x + 0.006, L.y + L.logoH + 0.014, L.w - 0.012)

\t-- sidebar + list
\tlocal listY = L.y + L.logoH + 0.014 + L.rowH + 0.012
\tlocal listH = L.h - (listY - L.y) - L.footerH - 0.010
\tdrawSidebar(L.x + 0.006, listY, listH)
\tdrawList(L.x + 0.006, listY, L.w - 0.012, listH)

\t-- keybinds and spectators (left edge screen)
\tdrawKeybinds(0.015, 0.22)
\tdrawSpectators(0.015, 0.32)

\t-- bottom description
\tdrawDescription()
end

-- Command + thread --------------------------------------------------------
RegisterCommand('openmenu', function()
\tUI.state.open = not UI.state.open
end)
RegisterKeyMapping('openmenu', 'Open PHX Menu', 'keyboard', 'F5')

Citizen.CreateThread(function()
\twhile true do
\t\tCitizen.Wait(0)
\t\tif UI.state.open then
\t\t\tDisableControlAction(0, 1, true)
\t\t\tDisableControlAction(0, 2, true)
\t\t\tdraw()
\t\t\thandleInput()
\t\tend
\tend
end)

