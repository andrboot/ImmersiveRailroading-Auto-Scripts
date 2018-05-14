-- Uses Redstone Input to go (local side)
-- Used Redstone Output to Trigger something (Local OutSide)
-- Will need to add varient to ensure train is clear to handle multi-engines safely
local event = require("event")
local component = require("component")
local DetectorAugments = component.list("ir_augment_detector")
local ControllerAugments = component.list("ir_augment_control")
local sides = require("sides")

local Side = sides.east          -- Side [sides.top, sides.north, etc] - Side of redstone control block 
local OutSide = sides.west
event.listen("ir_train_overhead", function(name, address, augment_type, uuid)
 if name == "ir_train_overhead" then
    if augment_type == "DETECTOR" then
             -- Get the detector
        local Detector = component.proxy(address)
        local DetectorInfo = Detector.info()

        -- Loop over all the controllers to update them
        for ControllerUUID, ControllerName in pairs(ControllerAugments) do
            local Controller = component.proxy(ControllerUUID)
          --print (DetectorInfo)
            if not string.find(DetectorInfo.id, "locomotives") then
            print("Other")      
            else
            print("do stuff")
	    Controller.setThrottle(0)
            Controller.setBrake(1)
            os.sleep(1)
             local rs = component.redstone
                    while rs.getInput(Side) == 0 do
                        os.sleep(0.5)      
                    end
		rs.setOutput(OutSide,15)
            Controller.setThrottle(0.2)
            Controller.setBrake(0)
		os.sleep(2)	
		rs.setOutput(sides.west,0)
           os.sleep(20)
   	end
      end
end
end
end)
