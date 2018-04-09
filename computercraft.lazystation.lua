-- Lazy ComputerCraft Station basically a timer
-- Also allows you to define the speed aka redstone output for the augment
-- New IR 1.x will require you to invert redstone on control to use brake augment
pulseLength = 500 -- In ticks
clockSpeed = 1500 -- In ticks
while true do
    while rs.getInput("front") do -- Remove "not" if you want to enable the clock when supplying a signal
        sleep((clockSpeed - pulseLength) /20)
        rs.setAnalogOutput("back", 3)
        sleep(pulseLength / 20)
        rs.setOutput("back", false)
    end
    event = os.pullEvent("redstone")
end
