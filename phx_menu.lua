local isOpen = false
local activeTabIndex = 1
local index = 1
local scrollOffset = 0

-- menu side: 'left' or 'right'
local menuSide = 'right'

local tabs = { 'List', 'Safe', 'Risky', 'Vehicle', 'Triggers', 'Settings' }

-- items per tab
local itemsByTab = {
  List = {
    { label = 'Test control', description = 'Control test', type = 'action', command = 'phx_testcontrol' },
    { label = 'Safe Explosion', description = 'Non-lethal fx', type = 'action', command = 'phx_safe_explosion' },
    { label = 'Copy plate', description = 'Copy nearby plate', type = 'action', command = 'phx_copy_plate' },
    { label = 'Bug vehicle', description = 'Attach a bug', type = 'action', command = 'phx_bug_vehicle' },
    { label = 'Military convoy', description = 'Spawn convoy', type = 'action', command = 'phx_military_convoy' },
    { label = 'Attach to car', description = 'Attach to car', type = 'toggle', toggle = false },
    { label = 'Take control', description = 'Take control of vehicle', type = 'toggle', toggle = false },
    { label = 'Fly vehicle', description = 'Vehicle flight mode', type = 'action', command = 'phx_fly_vehicle' },
    { label = 'Kick from vehicle', description = 'Kick from vehicle', type = 'action', command = 'phx_kick_vehicle' },
    { label = 'NPC vehicle hijack', description = 'NPC hijack', type = 'action', command = 'phx_npc_hijack' },
    { label = 'Hijack vehicle', description = 'Hijack target', type = 'action', command = 'phx_hijack' },
    { label = 'Delete vehicle', description = 'Delete vehicle', type = 'action', command = 'phx_delete_vehicle' },
  },
  Safe = {
    { label = 'Smoke puff', description = 'Visual only smoke', type = 'action', command = 'phx_safe_smoke' },
    { label = 'Flash light', description = 'Visual flash', type = 'action', command = 'phx_safe_flash' },
    { label = 'Sparks', description = 'Non-lethal sparks', type = 'action', command = 'phx_safe_sparks' },
    { label = 'Screen shock', description = 'Shake screen', type = 'action', command = 'phx_safe_shock' },
    { label = 'Honk spam', description = 'Honk nearby cars', type = 'action', command = 'phx_safe_honk' },
    { label = 'Light show', description = 'Vehicle lights', type = 'action', command = 'phx_safe_lights' },
  },
  Risky = {
    { label = 'EMP pulse', description = 'Disable nearby cars', type = 'action', command = 'phx_risky_emp' },
    { label = 'Oil slick', description = 'Slippery road', type = 'action', command = 'phx_risky_oil' },
    { label = 'Spike strip', description = 'Spawn spikes', type = 'action', command = 'phx_risky_spikes' },
    { label = 'Flashbang', description = 'Dazzle players', type = 'action', command = 'phx_risky_flashbang' },
    { label = 'Gas leak', description = 'Toxic cloud', type = 'action', command = 'phx_risky_gas' },
    { label = 'Siren storm', description = 'Sirens everywhere', type = 'action', command = 'phx_risky_sirens' },
  },
  Vehicle = {
    { label = 'Refuel vehicle', description = 'Fill fuel', type = 'action', command = 'phx_vehicle_refuel' },
    { label = 'Repair vehicle', description = 'Repair engine/body', type = 'action', command = 'phx_vehicle_repair' },
    { label = 'Clean vehicle', description = 'Wash dirt', type = 'action', command = 'phx_vehicle_clean' },
    { label = 'Flip vehicle', description = 'Upright vehicle', type = 'action', command = 'phx_vehicle_flip' },
    { label = 'Boost car', description = 'Temporary boost', type = 'action', command = 'phx_vehicle_boost' },
    { label = 'Freeze car', description = 'Stop instantly', type = 'action', command = 'phx_vehicle_freeze' },
  },
  Triggers = {
    { label = 'Start event A', description = 'Trigger A', type = 'action', command = 'phx_trig_a' },
    { label = 'Start event B', description = 'Trigger B', type = 'action', command = 'phx_trig_b' },
    { label = 'Start event C', description = 'Trigger C', type = 'action', command = 'phx_trig_c' },
    { label = 'Stop event A', description = 'Stop A', type = 'action', command = 'phx_stop_a' },
    { label = 'Stop event B', description = 'Stop B', type = 'action', command = 'phx_stop_b' },
    { label = 'Stop event C', description = 'Stop C', type = 'action', command = 'phx_stop_c' },
  },
}

-- Settings screen items (rendered when Settings tab active)
local settingsItems = {
  { key = 'menu_side', label = 'Menu side', description = 'Side of screen for the menu', type = 'toggle' },
  { key = 'open_key', label = 'Open menu', description = 'Keybind: F5', type = 'info' },
  { key = 'nav_key', label = 'Navigate', description = 'Up/Down, Left/Right, TAB tabs', type = 'info' },
  { key = 'select_key', label = 'Select', description = 'Enter', type = 'info' },
  { key = 'back_key', label = 'Close', description = 'Backspace', type = 'info' },
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

local function drawText(x, y, text, scale, alignRight, r, g, b, a, font, wrapRight)
  SetTextFont(font or 4)
  SetTextScale(scale or 0.32, scale or 0.32)
  SetTextColour(r or 220, g or 230, b or 245, a or 255)
  SetTextOutline()
  SetTextJustification(alignRight and 2 or 0)
  if wrapRight ~= nil then
    SetTextWrap(x, wrapRight)
  elseif alignRight then
    SetTextWrap(0.0, x)
  end
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
  menuY = 120,
  gap = 12,
  sidebarW = 11,
  sidebarH = 400,
  bannerW = 371,
  bannerH = 105,
  rowH = 32,
  thumbH = 30,
  maxVisible = 9
}

-- compute sidebar X depending on side
local function computeMenuX()
  local marginPx = 36
  if menuSide == 'right' then
    local totalPx = base.sidebarW + base.gap + base.bannerW
    return 1.0 - rx(totalPx + marginPx)
  else
    return rx(marginPx)
  end
end

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
  local tabCount = #tabs
  local spacingPx = 6
  local totalSpacingPx = spacingPx * (tabCount - 1)
  local eachPx = math.floor((base.bannerW - totalSpacingPx) / tabCount)
  if eachPx < 60 then eachPx = 60 end
  local curX = x
  for i, name in ipairs(tabs) do
    local w = rx(eachPx)
    local h = ry(22)
    local bg = i == activeTabIndex and {26,32,48,230} or {18,18,22,220}
    drawPanel(curX, y, w, h, table.unpack(bg))
    local pad = rx(6)
    drawText(curX + pad, y + ry(4), name, 0.28, false, 200,205,220,255, 4, curX + w - pad)
    curX = curX + w + rx(spacingPx)
  end
end

local function getCurrentItems()
  local tabName = tabs[activeTabIndex]
  if tabName == 'Settings' then
    return settingsItems
  end
  return itemsByTab[tabName] or {}
end

local function drawButtons(x, y, w)
  local items = getCurrentItems()
  local h = ry(base.rowH * math.min(base.maxVisible, #items))
  drawPanel(x, y, w, h, 18,18,22,230)
  local start = scrollOffset + 1
  local finish = math.min(#items, scrollOffset + base.maxVisible)
  for i = start, finish do
    local rowY = y + ry((i - start) * base.rowH)
    local selected = (i == index)
    if selected then drawRectTL(x, rowY, w, ry(base.rowH), 58, 130, 220, 70) end
    local padLeft = rx(12)
    local padRight = rx(12)
    local toggleW = rx(34)
    local labelRight = x + w - padRight
    local item = items[i]
    -- reserve space for toggle only if needed
    local hasToggle = item.type == 'toggle'
    if hasToggle then labelRight = labelRight - toggleW - rx(6) end
    drawText(x + padLeft, rowY + ry(7), item.label, 0.32, false, 231,236,247,255, 4, labelRight)
    if hasToggle then
      local tW, tH = rx(34), ry(18)
      local tX = x + w - tW - padRight
      local tY = rowY + ry(7)
      drawPanel(tX, tY, tW, tH, 24,24,28,220)
      local dotX = tX + rx((item.toggle and 18 or 2))
      drawRectTL(dotX, tY + ry(2), rx(14), ry(14), item.toggle and 34 or 150, item.toggle and 210 or 160, item.toggle and 166 or 180, 255)
    end
  end
end

local function drawSidebar(x, y)
  local items = getCurrentItems()
  drawPanel(x, y, rx(base.sidebarW), ry(base.sidebarH), 18,18,22,230)
  local total = math.max(#items, 1)
  local track = base.sidebarH - base.thumbH
  local offsetPx = total <= 1 and 0 or math.floor(((index - 1) / (total - 1)) * track)
  drawRectTL(x + rx(1), y + ry(offsetPx), rx(9), ry(base.thumbH), 60,140,255,255)
end

local function drawFooter(x, y, w)
  local items = getCurrentItems()
  local leftW = rx(90)
  local rightW = rx(80)
  local h = ry(26)
  drawPanel(x, y, leftW, h, 18,18,22,230)
  drawText(x + rx(10), y + ry(5), 'BETA', 0.32, false, 207,233,255,255, 4)
  drawPanel(x + w - rightW, y, rightW, h, 18,18,22,230)
  local txt = string.format('%d/%d', math.min(index, #items), #items)
  drawText(x + w - rx(10), y + ry(5), txt, 0.32, true, 220,230,245,255, 4)
end

local function drawKeyPanels()
  local x = rx(24)
  local y = ry(92)
  -- Keybinds (smaller)
  drawPanel(x, y, rx(200), ry(80), 18,18,22,230)
  drawText(x + rx(10), y + ry(8), 'Keybinds', 0.32, false, 150,160,180,255, 4)
  drawText(x + rx(10), y + ry(34), 'Open: F5', 0.28, false, 150,160,180,255, 4)
  drawText(x + rx(10), y + ry(54), 'Select: Enter', 0.28, false, 150,160,180,255, 4)

  -- Spectators (smaller)
  local sy = y + ry(92)
  drawPanel(x, sy, rx(200), ry(96), 18,18,22,230)
  drawText(x + rx(10), sy + ry(8), 'Spectators', 0.32, false, 150,160,180,255, 4)
  drawText(x + rx(10), sy + ry(38), '0 spectators', 0.28, false, 150,160,180,255, 4)
end

local function drawBottomDescription()
  local items = getCurrentItems()
  local w = rx(420)
  local h = ry(34)
  local x = 0.5 - w * 0.5
  local y = 1.0 - ry(50) - h
  drawPanel(x, y, w, h, 18,18,22,230)
  local desc = items[index] and items[index].description or ''
  drawText(x + rx(12), y + ry(7), desc, 0.32, false, 231,236,247,255, 4, x + w - rx(12))
end

local function drawSettingsList(x, y, w)
  local items = settingsItems
  local h = ry(base.rowH * math.min(base.maxVisible, #items))
  drawPanel(x, y, w, h, 18,18,22,230)
  local start = 1
  local finish = #items
  for i = start, finish do
    local rowY = y + ry((i - start) * base.rowH)
    local selected = (i == index)
    if selected then drawRectTL(x, rowY, w, ry(base.rowH), 58, 130, 220, 70) end
    local padLeft = rx(12)
    local padRight = rx(12)
    local labelRight = x + w - padRight
    local item = items[i]
    local rightText = ''
    if item.key == 'menu_side' then
      rightText = string.upper(menuSide)
    else
      rightText = item.description or ''
    end
    drawText(x + padLeft, rowY + ry(7), item.label, 0.32, false, 231,236,247,255, 4, x + w * 0.55)
    drawText(x + w - padRight, rowY + ry(7), rightText, 0.32, true, 180,190,205,255, 4)
  end
end

local function drawMenu()
  local menuX = computeMenuX()
  local menuY = ry(base.menuY)
  local sidebarX = menuX
  local sidebarY = menuY
  drawSidebar(sidebarX, sidebarY)

  local rightX = sidebarX + rx(base.sidebarW) + rx(base.gap)
  drawBanner(rightX, menuY)
  drawTabs(rightX, menuY + ry(base.bannerH + 8))

  local listY = menuY + ry(base.bannerH + 8 + 28)
  local listW = rx(base.bannerW)
  if tabs[activeTabIndex] == 'Settings' then
    drawSettingsList(rightX, listY, listW)
  else
    drawButtons(rightX, listY, listW)
  end
  drawFooter(rightX, listY + ry(base.rowH * math.min(base.maxVisible, #getCurrentItems())) + ry(8), listW)

  drawKeyPanels()
  drawBottomDescription()
end

local function clampIndex()
  local items = getCurrentItems()
  if #items == 0 then index = 1; scrollOffset = 0; return end
  if index < 1 then index = #items end
  if index > #items then index = 1 end
  if index <= scrollOffset then scrollOffset = math.max(0, index - 1) end
  if index > scrollOffset + base.maxVisible then scrollOffset = math.max(0, index - base.maxVisible) end
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

      -- Up/Down
      if IsControlJustPressed(0, 172) then -- up
        index = index - 1
        clampIndex()
      end
      if IsControlJustPressed(0, 173) then -- down
        index = index + 1
        clampIndex()
      end

      -- Next tab (TAB)
      if IsControlJustPressed(0, 37) then
        activeTabIndex = activeTabIndex + 1
        if activeTabIndex > #tabs then activeTabIndex = 1 end
        index = 1; scrollOffset = 0
      end
      -- Left/Right to change tabs
      if IsControlJustPressed(0, 174) then -- left
        activeTabIndex = activeTabIndex - 1
        if activeTabIndex < 1 then activeTabIndex = #tabs end
        index = 1; scrollOffset = 0
      end
      if IsControlJustPressed(0, 175) then -- right
        activeTabIndex = activeTabIndex + 1
        if activeTabIndex > #tabs then activeTabIndex = 1 end
        index = 1; scrollOffset = 0
      end

      -- Enter
      if IsControlJustPressed(0, 191) then
        local tabName = tabs[activeTabIndex]
        if tabName == 'Settings' then
          local item = settingsItems[index]
          if item and item.key == 'menu_side' then
            menuSide = (menuSide == 'right') and 'left' or 'right'
          end
        else
          local items = getCurrentItems()
          local item = items[index]
          if item then
            if item.type == 'toggle' then
              item.toggle = not item.toggle
            elseif item.type == 'action' and item.command then
              ExecuteCommand(item.command)
            end
          end
        end
      end

      -- Backspace -> close
      if IsControlJustPressed(0, 177) then
        isOpen = false
      end

      drawMenu()
    end
  end
end)

