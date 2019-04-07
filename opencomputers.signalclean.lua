local event = require("event")
local component = require("component")
local DetectorAugments = component.list("ir_augment_detector")
local ControllerAugments = component.list("ir_augment_control")
local rs = component.redstone
fs = require("filesystem")
serialization = require("serialization")
local redsignal = 2
local redsiglock = 3
local redblockclear = 1
local WantedSpeed = 2
local Deadzone = 1
local Throttle = 0
local ocsignaltype = 0

event.listen("ir_train_overhead", function(name, address, augment_type, uuid)
    if name ~= "ir_train_overhead" or augment_type ~= "DETECTOR" then
        return
    end
    local Detector = component.proxy(address)
    while rs.getInput(redblockclear) > 1 do
      os.exit(0)
    end
    for ControllerUUID, ControllerName in pairs(ControllerAugments) do
      local Controller = component.proxy(ControllerUUID)
      if string.find(Detector.info().id, "locomotives") then
          Controller.setThrottle(0)
          Controller.setBrake(1)
          if ocsignaltype == 1 then
            os.sleep(15)
          end
          while rs.getInput(redsignal) == 0 do
            os.sleep(0.5)
          end
          rs.setOutput(redsiglock,15)
          Controller.setBrake(0)
          os.sleep(0.1)
          rs.setOutput(redsiglock,0)
          if  (rs.getInput(redblockclear) < 1) then
		Throttle = 0 
		repeat
			if component.ir_augment_detector.info().throttle <= 0.4 then
              		Throttle = Throttle + 0.005
        	      	Controller.setThrottle(Throttle)
			end
		until component.ir_augment_detector.info().speed >= 5
	end
            
          end
        end
      
end)
