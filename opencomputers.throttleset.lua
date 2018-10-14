-- Docu Referencing
-- Requirements
	-- Redstone Card, 2 Redstone IR Augments, 1 Controller Augment, 2 Adapters

-- How it works?
	-- uses Redstone Input to GO or halt if active ( redsignal)
	-- uses redstone Output to Trigger something (like a signal block redout redsiglock)
	-- uses redstone Input to ensure consist has cleared before going back to normal for multi-locos (redblockclear)
	-- Uses Variable to determine if this is a station block or a signal block to ensure smooth running (signal.type 0 = Signal, 1 = Station)
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
local WantedSpeed = 2
local Deadzone = 1
local Threshold = 20 	-- Above this speed difference, SetChange = 1.0
local Throttle = 10
local ocsignaltype = 0
--- Varibles Finish


event.listen("ir_train_overhead", function(name, address, augment_type, uuid)
    -- Only run for ir_train_overhead with augment type of DETECTOR
    if name ~= "ir_train_overhead" or augment_type ~= "DETECTOR" then
        return
    end
--    print("event triggered") --debug print
    -- Get the detector
    local Detector = component.proxy(address)
    -- Sleep till train clears if it is active
		while rs.getInput(redblockclear) > 1 do
			os.exit(0)
		end
		-- Loop over all the controllers to update them
		for ControllerUUID, ControllerName in pairs(ControllerAugments) do
			local Controller = component.proxy(ControllerUUID)
			-- Check to see if the stock is a loco or not
			if string.find(Detector.info().id, "locomotives") then
				Controller.setThrottle(0.1)


						
				end
			
		end
end)

