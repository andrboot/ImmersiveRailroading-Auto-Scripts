--# IRTag Detector
--
--
-- Created by: andrboot
-- Version 0.1
--
--# Requirements
-- Detector Augment to be above
-- Detectoraugment to be 'behind' with redstone
-- Redstone output from the 'right' as output
-- Redstsone output from Bottom as 'train over'
-- Variable - Tag

local detection="_taghere_"
while true do
	if redstone.getInput("bottom") then
            os.reboot()
        end
	if string.find( peripheral.call("top",getTag"), detection) then
		redstone.setOutput("right", true)
		os.sleep(1)
		redstone.setOutput("right", false)
	end
	os.pullEvent("redstone")
end


