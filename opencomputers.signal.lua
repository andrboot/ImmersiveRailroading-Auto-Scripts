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
fs = require("filesystem")
serialization = require("serialization")
--- Redstone Varaibles for intput/output
local redsignal = 2
local redsiglock = 3
local redblockclear = 1
local WantedSpeed = 2
local Deadzone = 1
local Threshold = 20  -- Above this speed difference, SetChange = 1.0
local Throttle = 0
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
    --    if ocsignaltype == 0 then
    --                print("Waiting for next block to be clear, currently: ", rs.getInput(redsignal))
    --      if  rs.getInput(redsignal) > 0 then
    --        while rs.getInput(redblockclear) == 0 do
    --          rs.setOutput(redsiglock,15)
    --          os.sleep(0.1)
    --          rs.setOutput(redsiglock,0)
    --                  print("Waiting for next block to be clear, currently: ", rs.getInput(redsignal))
    --          os.sleep(0.5)
    --        end 
    --            while rs.getInput(redblockclear) > 1 do
    --        --        print("sleeping while waiting for `redblockclear`") --debug print
    --              os.sleep(0.5)
    --            end
    --      end
    --    end
        -- Check to see if next block is clear and wait until it is
          Controller.setThrottle(0)
          Controller.setBrake(1)
          if ocsignaltype == 1 then
            os.sleep(15)
          end
          while rs.getInput(redsignal) == 0 do
    --                print("Waiting for next block to be clear, currently: ", rs.getInput(redsignal))
            os.sleep(0.5)
          end
    --            print("redsiglock triggered")
          rs.setOutput(redsiglock,15)
    --            print("Setting brakes to 0")
          Controller.setBrake(0)
          os.sleep(0.1)
          rs.setOutput(redsiglock,0)
          while Detector.info() and (rs.getInput(redblockclear) < 1) do

            if Detector.info().speed <= WantedSpeed - Deadzone then
              Throttle = Throttle + 0.005
              Controller.setThrottle(Throttle)
	     
            end
--            Controller.setThrottle(Throttle)

    --                print("Speed at: ", Detector.info().speed, ", Setting Throttle to: ", Throttle)

            
          end
        end
      
    end
end)
