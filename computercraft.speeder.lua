--# IRSignal Speeder Throttle
--#
--# Created by: Andrboot
--# Version: 0.3
--#
--# Requirements/Setup:
--# Control Augment to be ABOVE CC
--# Redstone input from the 'rear' to detect consist above
--# Redstone Input from the "RIGHT" to detect Loco past
--# 
--# Variable speed 
--#
--#
local speed=0.65

while true do
    if redstone.getInput("back") then
--# Ignores if trains overapssing
        if redstone.getInput("right") then
            os.reboot()
        end
--# Halts the consist	
	peripheral.call("top", "setThrottle", speed)
        peripheral.call("top", "setBrake", "0")

    end
      
        os.pullEvent("redstone")
    print("test")
    
end
