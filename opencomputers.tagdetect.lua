-- Docu Referencing
-- Requirements
	-- Redstone Card, 2 Redstone IR Augments, 1 Controller Augment, 2 Adapters

-- How it works?

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
local Throttle = 0
local ocsignaltype = 0
--- Varibles Finish


event.listen("ir_train_overhead", function(name, address, augment_type, uuid)
    -- Only run for ir_train_overhead with augment type of DETECTOR
    if name ~= "ir_train_overhead" or augment_type ~= "DETECTOR" then
        return
    end
  print("event triggered") --debug print
    -- Get the detector
    local Detector = component.proxy(address)
    -- Sleep till train clears if it is active
		while rs.getInput(redblockclear) > 1 do
			os.exit(0)
		end
			-- Check to see if the stock is a loco or not
			if string.find(Detector.info().id, "locomotives") then
				--print("Detector.info().tag)")
				--	print("magic1")
					if string.find(Detector.info().tag, "_space_" ) then
					--print("magic2")
						rs.setOutput(redsignal,15)
						os.sleep(0.5)
						rs.setOutput(redsignal,0)
					end
				end
			
		end
end)

