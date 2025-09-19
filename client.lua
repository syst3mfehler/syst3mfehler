local isOpen = false
local activeTab = 1
local index = 1

local tabs = { 'List', 'Safe', 'Risky', 'Vehicle', 'Triggers' }

local items = {
  { label = 'Test control', description = 'Run a harmless control check', toggle = false },
  { label = 'Safe Explosion', description = 'Small non-lethal explosion effect', toggle = false },
  { label = 'Copy plate', description = 'Copy nearby vehicle plate', toggle = false },
  { label = 'Bug vehicle', description = 'Attach a bug to the target vehicle', toggle = false },
  { label = 'Military convoy', description = 'Spawn a small convoy for events', toggle = false },
  { label = 'Attach to car', description = 'Attach to selected vehicle', toggle = false },
  { label = 'Take control', description = 'Take control of the vehicle', toggle = false },
  { label = 'Fly vehicle', description = 'Toggle vehicle flight mode', toggle = true },
  { label = 'Kick from vehicle', description = 'Force player out of vehicle', toggle = false },
  { label = 'NPC vehicle hijack', description = 'Simulate NPC hijack event', toggle = false },
  { label = 'Hijack vehicle', description = 'Hijack target vehicle', toggle = false },
  { label = 'Delete vehicle', description = 'Delete current vehicle', toggle = false },
}

local function sendState()
  local state = {
    open = isOpen,
    tabs = (function()
      local t = {}
      for i, name in ipairs(tabs) do t[i] = { name = name } end
      return t
    end)(),
    activeTab = activeTab - 1,
    items = items,
    index = index - 1,
    description = items[index] and items[index].description or ''
  }
  SendNUIMessage({ type = 'state', state = state })
end

local function toggleMenu()
  isOpen = not isOpen
  SetNuiFocus(isOpen, isOpen)
  SendNUIMessage({ type = 'toggle', show = isOpen })
  if isOpen then
    sendState()
  end
end

RegisterCommand('openmenu', function()
  if not isOpen then index = 1 end
  toggleMenu()
end)
RegisterKeyMapping('openmenu', 'Open PHX Menu', 'keyboard', 'F5')

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
        if index < 1 then index = #items end
        sendState()
      end
      if IsControlJustPressed(0, 173) then -- down
        index = index + 1
        if index > #items then index = 1 end
        sendState()
      end
      if IsControlJustPressed(0, 37) then -- tab key
        activeTab = activeTab + 1
        if activeTab > #tabs then activeTab = 1 end
        index = 1
        sendState()
      end
      if IsControlJustPressed(0, 191) then -- enter
        if items[index] and items[index].toggle ~= nil then
          items[index].toggle = not items[index].toggle
          sendState()
        end
      end
      if IsControlJustPressed(0, 177) then -- backspace/esc
        toggleMenu()
      end
    end
  end
end)

