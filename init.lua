local mq = require('mq')
local ImGui = require('ImGui')

-- Variables
local running = false
local skill_up_count = 0
local pick_lock_skill = 'Pick Lock'
local lockpick_name = "Lockpicks"
local isOpen = true

-- Helper function to check for an unslotted item
local function findUnslottedItem(itemName)
    for invSlot = 0, 32 do
        local item = mq.TLO.Me.Inventory(invSlot)
        if item() and item.Name():lower() == itemName:lower() then
            return item  -- Found the unslotted item
        end

        if item() and item.Container() > 0 then  -- This is a bag
            for bagSlot = 1, item.Container() do
                local bagItem = item.Item(bagSlot)
                if bagItem() and bagItem.Name():lower() == itemName:lower() then
                    return bagItem
                end
            end
        end
    end
    return nil  -- Item not found
end

-- Function to retrieve lockpicks
local function fetchLockpicks()
    local item = findUnslottedItem(lockpick_name)

    if not item then
        print("No lockpicks found in inventory or bags. Please acquire lockpicks to continue.")
        running = false
        return
    end

    local itemSlot = item.ItemSlot()
    local itemSlot2 = item.ItemSlot2()

    if itemSlot >= 23 and itemSlot <= 32 then
        -- Bag slots (23-32)
        local bagSlot = itemSlot - 22
        mq.cmd('/itemnotify in pack' .. bagSlot .. ' ' .. (itemSlot2 + 1) .. ' leftmouseup')
    elseif itemSlot >= 0 and itemSlot <= 22 then
        -- Main inventory slots (0-22)
        mq.cmd('/itemnotify ' .. itemSlot .. ' leftmouseup')
    end
end

-- Lockpicking routine
local function performLockpicking()
    while running and mq.TLO.Skill(pick_lock_skill).SkillCap() >= mq.TLO.Me.Skill(pick_lock_skill)() do
        if not mq.TLO.Cursor() or not mq.TLO.Cursor.Name() or not mq.TLO.Cursor.Name():find(lockpick_name) then
            fetchLockpicks()
            if not running then return end
        end

        if not mq.TLO.Switch.ID() then
            mq.cmd('/doortarget')
            mq.delay(1000, function() return mq.TLO.Switch.ID() end)
        end

        if mq.TLO.Switch.ID() then
            mq.cmd('/click left door')
        end

        mq.doevents()
    end
end

-- Event handler for skill-ups
mq.event('Skillup', 'You have become better at #1#! (#2#)', function(_, skillgained, newskillamt)
    skill_up_count = skill_up_count + 1
    local green = "\ag"  -- Green color code
    local red = "\ar"    -- Red color code
    local reset = "\ax"  -- Reset to default color

    -- Construct the colored message
    local message = string.format('%s%d %sskill-ups. %s%s%s is now at %s%s.', red, skill_up_count, reset, green, skillgained, reset, red, newskillamt, reset)

    -- Print the message
    print(message)
end)


-- GUI rendering
local function render_gui()

        isOpen, _ = ImGui.Begin("Lockpick Trainer", isOpen, 2)

        ImGui.SetWindowSize(175, 100)

        if not isOpen then
            mq.cmd('/squelch /autoinv')
            mq.exit()
        end

        if ImGui.Button(running and 'Stop' or 'Start') then
            running = not running
            if running then
                    print('Starting lockpicking...')
            running = true
            else
                print('Stopping lockpicking...')
                running = false
                mq.cmd('/squelch /autoinv')
            end
        end
        ImGui.Text(string.format('Skill Ups: %d', skill_up_count))
        ImGui.Text(string.format('Current Skill: %d/%d',
            mq.TLO.Me.Skill(pick_lock_skill)(),
            mq.TLO.Skill(pick_lock_skill).SkillCap()))
    ImGui.End()
end

-- Register GUI and Main Loop
mq.imgui.init('LockpickGUI', render_gui)

while true do

    if running then
        performLockpicking()
    end

    mq.doevents()
    mq.delay(200)
end