local event = require("event")
local component = require("component")
local DetectorAugments = component.list("ir_augment_detector")
local ControllerAugments = component.list("ir_augment_control")
local sides = require("sides")

local Side = sides.top          -- Side [sides.top, sides.north, etc] - Side of redstone control block 

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
          if DetectorInfo.pressure then
            Controller.setThrottle(0)
            Controller.setBrake(1)
            os.sleep(15)
            computer.beep(500,0.25)
             local rs = component.redstone
                    while rs.getInput(Side) == 0 do
                        os.sleep(0.5)      
                    end
            computer.beep(450,0.25)
            Controller.setThrottle(0.6)
            Controller.setBrake(0)
          -- os.sleep(40)
   
        else
            if not string.find(DetectorInfo.id, "locomotives") then
            print("Other")      
            else
            print("do stuff")
               Controller.horn()
              Controller.setThrottle(0)
              Controller.setBrake(1)
              os.sleep(30)
               local rs = component.redstone
                    while rs.getInput(Side) == 0 do
                        os.sleep(0.5)      
                    end
              Controller.horn()
              Controller.setThrottle(0.6)
              Controller.setBrake(0)
              --os.sleep(40)
              end
        
        end
  end
end
end
end)
--print (component.ir_augment_detector.info().pressure )
