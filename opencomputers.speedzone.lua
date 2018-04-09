-- Created by LtBrandon
-- Tweaked by Gazer29
-- Tweaked by Andrboot
-- Enables you to setup a speed zone in a line, and use 1 track for 2-way directions based on a speed
-- Runs as a system event so no screen/monitor is needed, but needs to run of a install/hdd not just a eeprom
local event = require("event")
local component = require("component")
local DetectorAugments = component.list("ir_augment_detector")
local ControllerAugments = component.list("ir_augment_control")

local WantedSpeed = 10
local Deadzone = 1
local Direction = "south"	 -- Direction of main travel
local Threshold = 20 	-- Above this speed difference, SetChange = 1.0
local OtherDirectionThrottle = 1.0		

-- Listen for the Train Overhead event
event.listen("ir_train_overhead", function(name, address, augment_type, uuid)

  if name == "ir_train_overhead" then
    if augment_type == "DETECTOR" then

        -- Get the detector
        local Detector = component.proxy(address)
        local DetectorInfo = Detector.info()

        -- Loop over all the controllers to update them
        for ControllerUUID, ControllerName in pairs(ControllerAugments) do
            local Controller = component.proxy(ControllerUUID)

        --Added by Gazer29 to brake/accelerate proportional to the speed difference
           if DetectorInfo then
             Difference = DetectorInfo.speed - WantedSpeed
             if Difference < 0 then
               Difference = Difference * -1
               end
             SetChange = Difference / Threshold
             if Difference > Threshold then
               SetChange = 1.0
               end
             print("Diff:", Difference, "  Speed:", DetectorInfo.speed, "  SetChange:", SetChange)
             end

            -- If we're within a certain range of WantedSpeed then don't do anything
              if not string.find(DetectorInfo.direction, Direction) then
                Controller.setThrottle(OtherDirectionThrottle)
                Controller.setBrake(0.0)
                print("OtherDirection")
            else
             if DetectorInfo and math.abs(DetectorInfo.speed - WantedSpeed) > Deadzone then
                -- If we're too far above or below WantedSpeed then speed up or slow down
                if DetectorInfo.speed < WantedSpeed then
                    Controller.setThrottle(SetChange)
                    Controller.setBrake(0.0)
                    print("inc")
                else
                    Controller.setThrottle(0.040)
                    Controller.setBrake(SetChange)
                    print("dec")
                end
            else
                Controller.setThrottle(0.066)
                Controller.setBrake(0.0)
                print("ok")
                
            end
        end
        end
    end
end
end)

