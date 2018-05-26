local event = require("event")
local component = require("component")
local DetectorAugments = component.list("ir_augment_detector")
local ControllerAugments = component.list("ir_augment_control")

event.listen("ir_train_overhead", function(name, address, augment_type, uuid)
 if name == "ir_train_overhead" then
    if augment_type == "DETECTOR" then
             -- Get the detector
        local Detector = component.proxy(address)
        local DetectorInfo = Detector.info()
  local DetectorCons = Detector.consist()

        -- Loop over all the controllers to update them
        for ControllerUUID, ControllerName in pairs(ControllerAugments) do
            local Controller = component.proxy(ControllerUUID)
          --print (DetectorInfo)


 if not string.find(DetectorInfo.id, "locomotives") then
    print("other")
  else
  print("magic")
    if DetectorCons.cars < 10 then
      print("small car")
      Controller.setThrottle(-0.06)
    else
      print("large car")
    end
  end 
end
end
end
end)
