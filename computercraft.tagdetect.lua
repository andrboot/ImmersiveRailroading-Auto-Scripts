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
-- Variable - None - need to manually update tag line


while true do
	if redstone.getInput("bottom") then
            os.reboot()
        end
	if redstone.getOutput("back") then
		if string.find(peripheral.call("top","getTag"), "_taggoeshere_") then
			redstone.setOutput("right", true)
			os.sleep(1)
			redstone.setOutput("right", false)
			os.sleep(5)
		else
		end
	end
	os.pullEvent("redstone")
end


