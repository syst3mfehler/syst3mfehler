local isOpen = false
local activeTab = 1
local index = 1
local scrollOffset = 0

local tabs = { 'List', 'Safe', 'Risky', 'Vehicle', 'Triggers' }

local items = {
  { label = 'Test control', description = 'Control test', toggle = false },
  { label = 'Safe Explosion', description = 'Non-lethal fx', toggle = false },
  { label = 'Copy plate', description = 'Copy nearby plate', toggle = false },
  { label = 'Bug vehicle', description = 'Attach a bug', toggle = false },
  { label = 'Military convoy', description = 'Spawn convoy', toggle = false },
  { label = 'Attach to car', description = 'Attach to car', toggle = false },
  { label = 'Take control', description = 'Take control of vehicle', toggle = false },
  { label = 'Fly vehicle', description = 'Vehicle flight mode', toggle = true },
  { label = 'Kick from vehicle', description = 'Kick from vehicle', toggle = false },
  { label = 'NPC vehicle hijack', description = 'NPC hijack', toggle = false },
  { label = 'Hijack vehicle', description = 'Hijack target', toggle = false },
  { label = 'Delete vehicle', description = 'Delete vehicle', toggle = false },
}

-- screen helpers
local scrW, scrH = 1920.0, 1080.0
local function refreshRes()
  local w, h = GetActiveScreenResolution()
  scrW, scrH = w * 1.0, h * 1.0
end

local function rx(px) return px / scrW end
local function ry(py) return py / scrH end

-- draw helpers
local function drawRectTL(x, y, w, h, r, g, b, a)
  DrawRect(x + w * 0.5, y + h * 0.5, w, h, r or 255, g or 255, b or 255, a or 255)
end

local function drawPanel(x, y, w, h, r, g, b, a)
  drawRectTL(x, y, w, h, r, g, b, a)
  local br = {60,60,70,255}
  local bw = rx(1)
  drawRectTL(x, y, w, bw, table.unpack(br))
  drawRectTL(x, y + h - bw, w, bw, table.unpack(br))
  drawRectTL(x, y, bw, h, table.unpack(br))
  drawRectTL(x + w - bw, y, bw, h, table.unpack(br))
end

local function drawText(x, y, text, scale, alignRight, r, g, b, a, font)
  SetTextFont(font or 4)
  SetTextScale(scale or 0.35, scale or 0.35)
  SetTextColour(r or 220, g or 230, b or 245, a or 255)
  SetTextOutline()
  SetTextJustification(alignRight and 2 or 0)
  if alignRight then SetTextWrap(0.0, x) end
  SetTextEntry('STRING')
  AddTextComponentString(text)
  DrawText(x, y)
end

-- banner runtime texture
local bannerDict = 'phx_txd'
local bannerName = 'banner'
local bannerReady = false

local function tryLoadBanner()
  if bannerReady then return end
  local txd = CreateRuntimeTxd(bannerDict)
  local tex = CreateRuntimeTextureFromImage(txd, bannerName, 'banner.png')
  bannerReady = tex ~= nil
end

-- layout constants (pixels)
local base = {
  menuX = 120,
  menuY = 120,
  gap = 16,
  sidebarW = 11,
  sidebarH = 429,
  bannerW = 371,
  bannerH = 105,
  rowH = 36,
  thumbH = 34,
  maxVisible = 9
}

-- input & menu state
local function toggleMenu()
  isOpen = not isOpen
  if isOpen then refreshRes(); tryLoadBanner() end
end

RegisterCommand('openmenu', function()
  if not isOpen then index = 1; scrollOffset = 0 end
  toggleMenu()
end)
RegisterKeyMapping('openmenu', 'Open PHX Menu', 'keyboard', 'F5')

-- rendering
local function drawBanner(x, y)
  local w = rx(base.bannerW)
  local h = ry(base.bannerH)
  local cx = x + w * 0.5
  local cy = y + h * 0.5
  drawPanel(x, y, w, h, 11, 18, 28, 230)
  if bannerReady then
    DrawSprite(bannerDict, bannerName, cx, cy, w, h, 0.0, 255,255,255,255)
  else
    for i=0,10 do
      local t = i/10
      drawRectTL(x, y + h * t, w, h/10.0, 10, 24 + math.floor(110*t), 45 + math.floor(120*t), 220)
    end
  end
end

local function drawTabs(x, y)
  local curX = x
  for i, name in ipairs(tabs) do
    local pad = 8
    local w = rx(64 + (#name*7))
    local h = ry(28)
    local bg = i == activeTab and {26,32,48,230} or {18,18,22,220}
    drawPanel(curX, y, w, h, table.unpack(bg))
    drawText(curX + rx(pad), y + ry(6), name, 0.32, false, 200,205,220,255, 4)
    curX = curX + w + rx(8)
  end
end

local function drawButtons(x, y, w)
  local h = ry(base.rowH * math.min(base.maxVisible, #items))
  drawPanel(x, y, w, h, 18,18,22,230)
  local start = scrollOffset + 1
  local finish = math.min(#items, scrollOffset + base.maxVisible)
  for i = start, finish do
    local rowY = y + ry((i - start) * base.rowH)
    local selected = (i == index)
    if selected then drawRectTL(x, rowY, w, ry(base.rowH), 58, 130, 220, 70) end
    drawText(x + rx(12), rowY + ry(8), items[i].label, 0.34, false, 231,236,247,255, 4)
    if items[i].toggle ~= nil then
      local tW, tH = rx(34), ry(18)
      local tX = x + w - tW - rx(12)
      local tY = rowY + ry(9)
      drawPanel(tX, tY, tW, tH, 24,24,28,220)
      local dotX = tX + rx(items[i].toggle and 18 or 2)
      drawRectTL(dotX, tY + ry(2), rx(14), ry(14), items[i].toggle and 34 or 150, items[i].toggle and 210 or 160, items[i].toggle and 166 or 180, 255)
    end
  end
end

local function drawSidebar(x, y)
  drawPanel(x, y, rx(base.sidebarW), ry(base.sidebarH), 18,18,22,230)
  local total = math.max(#items, 1)
  local track = base.sidebarH - base.thumbH
  local offsetPx = total <= 1 and 0 or math.floor(((index - 1) / (total - 1)) * track)
  drawRectTL(x + rx(1), y + ry(offsetPx), rx(9), ry(base.thumbH), 60,140,255,255)
end

local function drawFooter(x, y, w)
  local leftW = rx(90)
  local rightW = rx(80)
  local h = ry(28)
  drawPanel(x, y, leftW, h, 18,18,22,230)
  drawText(x + rx(10), y + ry(6), 'BETA', 0.34, false, 207,233,255,255, 4)
  drawPanel(x + w - rightW, y, rightW, h, 18,18,22,230)
  local txt = string.format('%d/%d', index, #items)
  drawText(x + w - rx(10), y + ry(6), txt, 0.34, true, 220,230,245,255, 4)
end

local function drawKeyPanels()
  local x = rx(24)
  local y = ry(92)
  drawPanel(x, y, rx(240), ry(96), 18,18,22,230)
  drawText(x + rx(12), y + ry(10), 'Keybinds', 0.34, false, 150,160,180,255, 4)
  drawText(x + rx(12), y + ry(40), 'Freeroam', 0.30, false, 150,160,180,255, 4)
  drawRectTL(x + rx(160), y + ry(34), rx(52), ry(24), 26,28,32,230)
  drawText(x + rx(168), y + ry(40), 'OFF', 0.30, false, 220,230,245,255, 4)
  drawText(x + rx(12), y + ry(68), 'Noclip', 0.30, false, 150,160,180,255, 4)
  drawRectTL(x + rx(160), y + ry(62), rx(52), ry(24), 26,28,32,230)
  drawText(x + rx(168), y + ry(68), 'CAPS', 0.30, false, 220,230,245,255, 4)

  local sy = y + ry(112)
  drawPanel(x, sy, rx(240), ry(120), 18,18,22,230)
  drawText(x + rx(12), sy + ry(10), 'Spectators', 0.34, false, 150,160,180,255, 4)
  drawText(x + rx(12), sy + ry(44), '0 spectators', 0.30, false, 150,160,180,255, 4)
end

local function drawBottomDescription()
  local w = rx(420)
  local h = ry(36)
  local x = 0.5 - w * 0.5
  local y = 1.0 - ry(50) - h
  drawPanel(x, y, w, h, 18,18,22,230)
  local desc = items[index] and items[index].description or ''
  drawText(x + rx(12), y + ry(8), desc, 0.34, false, 231,236,247,255, 4)
end

local function drawMenu()
  local menuX = rx(base.menuX)
  local menuY = ry(base.menuY)
  local sidebarX = menuX
  local sidebarY = menuY
  drawSidebar(sidebarX, sidebarY)

  local rightX = sidebarX + rx(base.sidebarW) + rx(base.gap)
  drawBanner(rightX, menuY)
  drawTabs(rightX, menuY + ry(base.bannerH + 10))

  local listY = menuY + ry(base.bannerH + 10 + 36)
  local listW = rx(base.bannerW)
  drawButtons(rightX, listY, listW)
  drawFooter(rightX, listY + ry(base.rowH * math.min(base.maxVisible, #items)) + ry(10), listW)

  drawKeyPanels()
  drawBottomDescription()
end

-- input thread
CreateThread(function()
  while true do
    Wait(0)
    if isOpen then
      DisableControlAction(0, 1, true)
      DisableControlAction(0, 2, true)
      DisableControlAction(0, 24, true)
      DisableControlAction(0, 25, true)

      if IsControlJustPressed(0, 172) then
        index = index - 1
        if index < 1 then index = #items end
        if index <= scrollOffset then scrollOffset = math.max(0, index - 1) end
      end
      if IsControlJustPressed(0, 173) then
        index = index + 1
        if index > #items then index = 1 end
        if index > scrollOffset + base.maxVisible then scrollOffset = index - base.maxVisible end
      end
      if IsControlJustPressed(0, 37) then
        activeTab = activeTab + 1
        if activeTab > #tabs then activeTab = 1 end
        index = 1; scrollOffset = 0
      end
      if IsControlJustPressed(0, 191) then
        if items[index] and items[index].toggle ~= nil then
          items[index].toggle = not items[index].toggle
        end
      end
      if IsControlJustPressed(0, 177) then
        isOpen = false
      end

      drawMenu()
    end
  end
end)

