-- Docu Referencing
-- Requirements
	-- Redstone Card, 2 Redstone IR Augments, 1 Controller Augment, 2 Adapters

-- How it works?
	-- uses Redstone Input to GO or halt if active ( redsignal)
	-- uses redstone Output to Trigger something (like a signal block redout redsiglock)
	-- uses redstone Input to ensure consist has cleared before going back to normal for multi-locos (redblockclear)
	-- Cobbled together by andrboot, with code from LtBrandon & Gazer29 & DonSpruce

-- Redstone Refence using Redstone Card on computer NOT redstone block
	-- Bottom (bottom), Number: 0
	-- Top (top), Number: 1
	-- Back (back), Number: 2
	-- Front (front), Number: 3
	-- Right (right), Number: 4
	-- Left (left), Number: 5
	--Created by Don_Spruce

---- Variables Start
local event = require("event")
local component = require("component")
local DetectorAugments = component.list("ir_augment_detector")
local ControllerAugments = component.list("ir_augment_control")
local rs = component.redstone
--- Redstone Varaibles for intput/output
local redsignal = 2
local redsiglock = 3
local redblockclear = 1
local WantedSpeed = 10
local Deadzone = 1
local Threshold = 20 	-- Above this speed difference, SetChange = 1.0
--- Varibles Finish


event.listen("ir_train_overhead", function(name, address, augment_type, uuid)
    -- Only run for ir_train_overhead with augment type of DETECTOR
    if name ~= "ir_train_overhead" or augment_type ~= "DETECTOR" then
        return
    end

    -- Get the detector
    local Detector = component.proxy(address)
    local DetectorInfo = Detector.info()

    -- Sleep till train clears if it is active
    while rs.getInput(redblockclear) > 1 do
        os.sleep(0.5)
        DetectorInfo.id = "cake"
    end

    -- Loop over all the controllers to update them
    for ControllerUUID, ControllerName in pairs(ControllerAugments) do
        local Controller = component.proxy(ControllerUUID)
        -- Check to see if the stock is a loco or not
        if string.find(DetectorInfo.id, "locomotives") then
            -- print("do stuff")
            Controller.setThrottle(0)
            Controller.setBrake(1)

            -- Check to see if next block is clear and wait until it is
            while rs.getInput(redsignal) == 0 do
                os.sleep(0.5)
            end

            rs.setOutput(redsiglock,15)

            -- Old speed Controls	        	Controller.setThrottle(0.25)
            --old Speed Controls                Controller.setBrake(0)
            -- New Fancy Code to ensure train is actually moving
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

            rs.setOutput(redsiglock,0)
        end
    end
end)
