--# IRSignal Start/Stop script
--#
--# Created by: Andrboot
--# Version: 0.3
--#
--# Requirements/Setup:
--# Control Augment to be ABOVE CC
--# Redstone input from the 'rear' to detect consist above
--# Redstone Input from the "LEFT" to indicate a clear track
--# Redstone Input from the "RIGHT" to detect Loco past
--# 
--# Variable Signal Type 0 = Signal, 1 = Station
--#
--#
local type=0

while true do
    if redstone.getInput("back") then
--# Ignores if trains overapssing
        if redstone.getInput("right") then
            os.reboot()
        end
--# Halts the consist	
	peripheral.call("top", "setThrottle", "0")
        peripheral.call("top", "setBrake", "1")
--# Sleeps if its a Station Type
        if redstone.getInput("left") then
	        if type == 1 then
	            os.sleep(15)
        	end
		os.sleep(1)
--# Throttle code to make it nice and firey		
local Throttle = 0
       		peripheral.call("top", "setBrake", "0")
		repeat
			Throttle = Throttle + 0.005
			peripheral.call("top", "setThrottle", Throttle)
			os.sleep(0.1)
		until Throttle >= 0.4

			
        end
    end
      
        os.pullEvent("redstone")
    print("test")
    
end
