-- PHX Menu (test implementation per request)

-- state
local isOpen = false
local activeTab = 1
local index = 1
local scrollOffset = 0

-- settings
local settings = {
  dockRight = true,
}

-- tabs
local tabs = { 'List', 'Safe', 'Risky', 'Vehicle', 'Triggers', 'Settings' }

-- helpers for creating items
local function action(label, description, command)
  return { label = label, description = description, command = command }
end

local function toggleItem(label, description, key)
  return { label = label, description = description, toggle = false, _settingKey = key }
end

-- per-tab items (test placeholders as requested)
local tabItems = {
  List = {
    action('Test control', 'Control test'),
    action('Safe Explosion', 'Non-lethal fx'),
    action('Copy plate', 'Copy nearby plate'),
    action('Bug vehicle', 'Attach a bug'),
    action('Military convoy', 'Spawn convoy'),
    toggleItem('Attach to car', 'Attach to car'),
    toggleItem('Take control', 'Take control of vehicle'),
    action('Fly vehicle', 'Vehicle flight mode'),
    action('Kick from vehicle', 'Kick from vehicle'),
    action('NPC vehicle hijack', 'NPC hijack'),
    action('Hijack vehicle', 'Hijack target'),
    action('Delete vehicle', 'Delete vehicle'),
  },
  Safe = {
    action('Heal', 'Restore health'),
    action('Armor', 'Give armor'),
    action('Clean', 'Clean ped and vehicle'),
  },
  Risky = {
    action('Explode Nearby', 'Explode close entity (test)'),
    action('Chaos Mode', 'Enable chaos (test)'),
  },
  Vehicle = {
    action('Repair vehicle', 'Fix current vehicle'),
    action('Flip vehicle', 'Flip upright'),
    toggleItem('Attach to car', 'Attach to car'),
    toggleItem('Take control', 'Take control of vehicle'),
  },
  Triggers = {
    action('Trigger A', 'Test trigger A'),
    action('Trigger B', 'Test trigger B'),
    action('Trigger C', 'Test trigger C'),
  },
  Settings = {
    toggleItem('Dock menu to right', 'Position the menu on the right', 'dockRight'),
  },
}

-- mapping helpers
local function getActiveTabName()
  return tabs[activeTab]
end

local function getActiveItems()
  local name = getActiveTabName()
  local list = tabItems[name]
  return list or {}
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

local function drawText(x, y, text, scale, alignRight, r, g, b, a, font, wrapToX)
  SetTextFont(font or 4)
  SetTextScale(scale or 0.35, scale or 0.35)
  SetTextColour(r or 220, g or 230, b or 245, a or 255)
  SetTextOutline()
  SetTextJustification(alignRight and 2 or 0)
  if wrapToX then SetTextWrap(x, wrapToX) elseif alignRight then SetTextWrap(0.0, x) end
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
  gap = 12, -- slightly smaller gaps
  sidebarW = 10,
  sidebarH = 400, -- smaller sidebar height
  bannerW = 371,
  bannerH = 105,
  rowH = 34, -- smaller rows
  thumbH = 30, -- smaller thumb height
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

local function drawTabs(x, y, totalWidth)
  local count = #tabs
  local gapW = rx(6)
  local available = totalWidth - gapW * (count - 1)
  local eachW = available / count
  local h = ry(26)
  local curX = x
  for i, name in ipairs(tabs) do
    local bg = i == activeTab and {26,32,48,230} or {18,18,22,220}
    drawPanel(curX, y, eachW, h, table.unpack(bg))
    local pad = rx(6)
    drawText(curX + pad, y + ry(5), name, 0.30, false, 200,205,220,255, 4, curX + eachW - pad)
    curX = curX + eachW + gapW
  end
end

local function drawButtons(x, y, w)
  local items = getActiveItems()
  local visible = math.min(base.maxVisible, #items)
  local h = ry(base.rowH * visible)
  drawPanel(x, y, w, h, 18,18,22,230)
  local start = scrollOffset + 1
  local finish = math.min(#items, scrollOffset + base.maxVisible)
  for i = start, finish do
    local rowY = y + ry((i - start) * base.rowH)
    local selected = (i == index)
    if selected then drawRectTL(x, rowY, w, ry(base.rowH), 58, 130, 220, 70) end
    local pad = rx(10)
    local toggleW = rx(36)
    local rightLimit = x + w - pad - toggleW
    drawText(x + pad, rowY + ry(8), items[i].label, 0.32, false, 231,236,247,255, 4, rightLimit)
    if items[i].toggle ~= nil or items[i]._settingKey then
      local tW, tH = rx(32), ry(16)
      local tX = x + w - tW - pad
      local tY = rowY + ry(9)
      drawPanel(tX, tY, tW, tH, 24,24,28,220)
      local isOn
      if items[i]._settingKey then
        isOn = settings[items[i]._settingKey] == true
      else
        isOn = items[i].toggle == true
      end
      local dotX = tX + rx(isOn and 18 or 2)
      drawRectTL(dotX, tY + ry(2), rx(12), ry(12), isOn and 34 or 150, isOn and 210 or 160, isOn and 166 or 180, 255)
    end
  end
end

local function drawSidebar(x, y)
  drawPanel(x, y, rx(base.sidebarW), ry(base.sidebarH), 18,18,22,230)
  local items = getActiveItems()
  local total = math.max(#items, 1)
  local track = base.sidebarH - base.thumbH
  local offsetPx = total <= 1 and 0 or math.floor(((index - 1) / (total - 1)) * track)
  drawRectTL(x + rx(1), y + ry(offsetPx), rx(8), ry(base.thumbH), 60,140,255,255)
end

local function drawFooter(x, y, w)
  local items = getActiveItems()
  local leftW = rx(80)
  local rightW = rx(70)
  local h = ry(24)
  drawPanel(x, y, leftW, h, 18,18,22,230)
  drawText(x + rx(8), y + ry(4), 'BETA', 0.32, false, 207,233,255,255, 4)
  drawPanel(x + w - rightW, y, rightW, h, 18,18,22,230)
  local txt = string.format('%d/%d', math.min(index, #items), #items)
  drawText(x + w - rx(8), y + ry(4), txt, 0.32, true, 220,230,245,255, 4)
end

local function drawSettingsPanels(x, y, w)
  local panelW = w
  local keyH = ry(80)
  drawPanel(x, y, panelW, keyH, 18,18,22,230)
  drawText(x + rx(10), y + ry(8), 'Keybinds', 0.32, false, 150,160,180,255, 4)
  drawText(x + rx(10), y + ry(30), 'Open Menu: F5', 0.30, false, 200,205,220,255, 4)
  drawText(x + rx(10), y + ry(50), 'Navigate: Arrow Up/Down, Tabs: TAB', 0.30, false, 200,205,220,255, 4)

  local sy = y + keyH + ry(10)
  local spH = ry(60)
  drawPanel(x, sy, panelW, spH, 18,18,22,230)
  drawText(x + rx(10), sy + ry(8), 'Spectators', 0.32, false, 150,160,180,255, 4)
  drawText(x + rx(10), sy + ry(32), '0 spectators', 0.30, false, 150,160,180,255, 4)
end

local function drawBottomDescription()
  local items = getActiveItems()
  local w = rx(420)
  local h = ry(32)
  local x = 0.5 - w * 0.5
  local y = 1.0 - ry(50) - h
  drawPanel(x, y, w, h, 18,18,22,230)
  local desc = items[index] and items[index].description or ''
  drawText(x + rx(12), y + ry(6), desc, 0.32, false, 231,236,247,255, 4, x + w - rx(12))
end

local function drawMenu()
  local listW = rx(base.bannerW)
  local menuY = ry(base.menuY)

  local rightX
  local sidebarX
  if settings.dockRight then
    rightX = 1.0 - rx(base.menuX) - listW
    sidebarX = rightX - rx(base.gap) - rx(base.sidebarW)
  else
    sidebarX = rx(base.menuX)
    rightX = sidebarX + rx(base.sidebarW) + rx(base.gap)
  end

  local sidebarY = menuY
  drawSidebar(sidebarX, sidebarY)

  drawBanner(rightX, menuY)
  local tabsY = menuY + ry(base.bannerH + 8)
  drawTabs(rightX, tabsY, listW)

  local listY = menuY + ry(base.bannerH + 8 + 30)
  local items = getActiveItems()
  local visible = math.min(base.maxVisible, #items)
  drawButtons(rightX, listY, listW)
  drawFooter(rightX, listY + ry(base.rowH * visible) + ry(8), listW)

  if getActiveTabName() == 'Settings' then
    local settingsY = listY + ry(base.rowH * visible) + ry(8 + 30)
    drawSettingsPanels(rightX, settingsY, listW)
  end

  drawBottomDescription()
end

-- execution helpers
local function executeAction(item)
  if item._settingKey then
    settings[item._settingKey] = not settings[item._settingKey]
    return
  end
  if item.command then
    ExecuteCommand(item.command)
  else
    -- test execute: send a generic command with label as argument
    local safeLabel = (item.label or 'action'):gsub('"', "'")
    ExecuteCommand(('phx_test "%s"'):format(safeLabel))
  end
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

      if IsControlJustPressed(0, 172) then -- up
        index = index - 1
        local items = getActiveItems()
        if index < 1 then index = #items end
        if index <= scrollOffset then scrollOffset = math.max(0, index - 1) end
      end
      if IsControlJustPressed(0, 173) then -- down
        index = index + 1
        local items = getActiveItems()
        if index > #items then index = 1 end
        if index > scrollOffset + base.maxVisible then scrollOffset = index - base.maxVisible end
      end
      if IsControlJustPressed(0, 37) then -- tab next
        activeTab = activeTab + 1
        if activeTab > #tabs then activeTab = 1 end
        index = 1; scrollOffset = 0
      end
      if IsControlJustPressed(0, 191) then -- enter
        local items = getActiveItems()
        local item = items[index]
        if item then
          if item._settingKey then
            settings[item._settingKey] = not settings[item._settingKey]
          elseif item.toggle ~= nil then
            item.toggle = not item.toggle
          else
            executeAction(item)
          end
        end
      end
      if IsControlJustPressed(0, 177) then -- backspace/escape
        isOpen = false
      end

      drawMenu()
    end
  end
end)

