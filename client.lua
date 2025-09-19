local isOpen = false
local activeTab = 1
local index = 1
local scrollOffset = 0

local Settings = { side = 'left', noclipBind = { code = nil, label = 'CAPS' }, freecamBind = { code = nil, label = 'F6' } }
local rebinding = nil -- 'noclip' | 'freecam' | nil

local tabs = { 'List', 'Safe', 'Risky', 'Vehicle', 'Triggers', 'Settings' }

local tabItems = {
  [1] = {
    { label = 'Test control', description = 'Control test', type = 'action', cmd = 'testcontrol' },
    { label = 'Safe Explosion', description = 'Non-lethal fx', type = 'action', cmd = 'safeexplosion' },
    { label = 'Copy plate', description = 'Copy nearby plate', type = 'action', cmd = 'copyplate' },
    { label = 'Bug vehicle', description = 'Attach a bug', type = 'action', cmd = 'bugvehicle' },
    { label = 'Military convoy', description = 'Spawn convoy', type = 'action', cmd = 'spawnconvoy' },
    { label = 'Attach to car', description = 'Attach to car', type = 'action', cmd = 'attachtocar' },
    { label = 'Take control', description = 'Take control of vehicle', type = 'toggle', value = false },
    { label = 'Kick from vehicle', description = 'Kick target from vehicle', type = 'toggle', value = false },
    { label = 'NPC vehicle hijack', description = 'NPC hijack', type = 'action', cmd = 'npchijack' },
    { label = 'Hijack vehicle', description = 'Hijack target', type = 'action', cmd = 'hijack' },
    { label = 'Delete vehicle', description = 'Delete vehicle', type = 'action', cmd = 'delveh' },
  },
  [2] = {
    { label = 'Godmode', description = 'Safe: player godmode', type = 'action', cmd = 'godmode' },
    { label = 'Heal', description = 'Restore health/armor', type = 'action', cmd = 'heal' },
  },
  [3] = {
    { label = 'Explode', description = 'Risky: explode near', type = 'action', cmd = 'explode' },
  },
  [4] = {
    { label = 'Flip vehicle', description = 'Flip upright', type = 'action', cmd = 'flipveh' },
  },
  [5] = {
    { label = 'Trigger A', description = 'Run trigger A', type = 'action', cmd = 'trigA' },
  },
  [6] = {
    { label = 'Menu side', description = 'Left or Right placement', type = 'choice', options = { 'left', 'right' }, idx = 1 },
    { label = 'Noclip keybind', description = 'Rebind noclip toggle', type = 'rebind', which = 'noclip' },
    { label = 'Freecam keybind', description = 'Rebind freecam toggle', type = 'rebind', which = 'freecam' },
  }
}

local function currentItems()
  return tabItems[activeTab] or {}
end

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
  rowH = 26,
  thumbH = 34,
  maxVisible = 12
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
    local h = ry(24)
    local bg = i == activeTab and {26,32,48,230} or {18,18,22,220}
    drawPanel(curX, y, w, h, table.unpack(bg))
    drawText(curX + rx(pad), y + ry(4), name, 0.28, false, 200,205,220,255, 4)
    curX = curX + w + rx(8)
  end
end

local function drawButtons(x, y, w, list)
  local h = ry(base.rowH * math.min(base.maxVisible, #list))
  drawPanel(x, y, w, h, 18,18,22,230)
  local start = scrollOffset + 1
  local finish = math.min(#list, scrollOffset + base.maxVisible)
  for i = start, finish do
    local rowY = y + ry((i - start) * base.rowH)
    local selected = (i == index)
    if selected then drawRectTL(x, rowY, w, ry(base.rowH), 58, 130, 220, 60) end
    drawText(x + rx(12), rowY + ry(5), list[i].label, 0.28, false, 231,236,247,255, 4)
    if list[i].type == 'toggle' then
      local tW, tH = rx(30), ry(16)
      local tX = x + w - tW - rx(12)
      local tY = rowY + ry(4)
      drawPanel(tX, tY, tW, tH, 24,24,28,220)
      local dotX = tX + rx((list[i].value and 16) or 2)
      drawRectTL(dotX, tY + ry(2), rx(12), ry(12), list[i].value and 34 or 150, list[i].value and 210 or 160, list[i].value and 166 or 180, 255)
    elseif list[i].type == 'choice' then
      local label = list[i].options[list[i].idx or 1]
      drawText(x + w - rx(12), rowY + ry(5), tostring(label), 0.28, true, 200,205,220,255, 4)
    end
  end
end

local function drawSidebar(x, y, listHeight, listCount)
  drawPanel(x, y, rx(base.sidebarW), ry(base.sidebarH), 18,18,22,230)
  local total = math.max(listCount, 1)
  local track = base.sidebarH - base.thumbH
  local offsetPx = total <= 1 and 0 or math.floor(((index - 1) / (total - 1)) * track)
  drawRectTL(x + rx(1), y + ry(offsetPx), rx(9), ry(base.thumbH), 60,140,255,255)
end

local function drawFooter(x, y, w, listCount)
  local leftW = rx(90)
  local rightW = rx(80)
  local h = ry(28)
  drawPanel(x, y, leftW, h, 18,18,22,230)
  drawText(x + rx(10), y + ry(6), 'BETA', 0.34, false, 207,233,255,255, 4)
  drawPanel(x + w - rightW, y, rightW, h, 18,18,22,230)
  local txt = string.format('%d/%d', index, listCount)
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
  drawText(x + rx(168), y + ry(68), Settings.noclipBind.label or 'CAPS', 0.30, false, 220,230,245,255, 4)

  local sy = y + ry(112)
  drawPanel(x, sy, rx(240), ry(120), 18,18,22,230)
  drawText(x + rx(12), sy + ry(10), 'Spectators', 0.34, false, 150,160,180,255, 4)
  drawText(x + rx(12), sy + ry(44), '0 spectators', 0.30, false, 150,160,180,255, 4)
end

local function drawBottomDescription(list)
  local w = rx(420)
  local h = ry(36)
  local x = 0.5 - w * 0.5
  local y = 1.0 - ry(50) - h
  drawPanel(x, y, w, h, 18,18,22,230)
  local desc = list[index] and list[index].description or ''
  drawText(x + rx(12), y + ry(8), desc, 0.34, false, 231,236,247,255, 4)
end

local function drawMenu()
  local list = currentItems()
  if #list == 0 then index = 1; scrollOffset = 0 end
  if index > #list then index = #list end
  if index < 1 then index = 1 end
  if index <= scrollOffset then scrollOffset = math.max(0, index - 1) end
  if index > scrollOffset + base.maxVisible then scrollOffset = index - base.maxVisible end

  local anchorX
  if Settings.side == 'right' then
    anchorX = 1.0 - rx(base.menuX) - rx(base.bannerW)
  else
    anchorX = rx(base.menuX) + rx(base.sidebarW) + rx(base.gap)
  end

  local menuY = ry(base.menuY)
  drawBanner(anchorX, menuY)
  drawTabs(anchorX, menuY + ry(base.bannerH + 8))

  local listY = menuY + ry(base.bannerH + 8 + 26)
  local listW = rx(base.bannerW)
  drawButtons(anchorX, listY, listW, list)
  drawFooter(anchorX, listY + ry(base.rowH * math.min(base.maxVisible, #list)) + ry(8), listW, #list)

  local sidebarX = anchorX - rx(base.gap) - rx(base.sidebarW)
  drawSidebar(sidebarX, listY, ry(base.rowH * math.min(base.maxVisible, #list)), #list)

  drawKeyPanels()
  drawBottomDescription(list)
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
        local list = currentItems()
        if index < 1 then index = #list end
        if index <= scrollOffset then scrollOffset = math.max(0, index - 1) end
      end
      if IsControlJustPressed(0, 173) then
        index = index + 1
        local list = currentItems()
        if index > #list then index = 1 end
        if index > scrollOffset + base.maxVisible then scrollOffset = index - base.maxVisible end
      end
      if IsControlJustPressed(0, 37) then
        activeTab = activeTab + 1
        if activeTab > #tabs then activeTab = 1 end
        index = 1; scrollOffset = 0
      end
      if IsControlJustPressed(0, 44) then -- Q = previous tab
        activeTab = activeTab - 1
        if activeTab < 1 then activeTab = #tabs end
        index = 1; scrollOffset = 0
      end
      if IsControlJustPressed(0, 191) then
        local list = currentItems()
        local it = list[index]
        if it then
          if it.type == 'toggle' then
            it.value = not it.value
          elseif it.type == 'action' then
            if it.cmd then ExecuteCommand(it.cmd) end
          elseif it.type == 'choice' then
            it.idx = (it.idx or 1) + 1
            if it.idx > #it.options then it.idx = 1 end
            Settings.side = it.options[it.idx]
          elseif it.type == 'rebind' then
            rebinding = it.which
          end
        end
      end
      if IsControlJustPressed(0, 177) then
        isOpen = false
      end

      drawMenu()
    end
  end
end)

