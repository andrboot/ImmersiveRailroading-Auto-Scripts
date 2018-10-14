-- Created by Don_Bruce
-- Is a basic Redstone FLip-FLop Circit
-- Redstone input comes from the top and flips left/right sides when top is changed
-- Can run on a micro-controller
local redstone = component.list("redstone")()
local signalInput = 1
local rightOutput = 4
local leftOutput = 5

local redstoneThreshold = 1
local redstoneOutput = 15
local redstoneIdle = 0

assert(redstone, "Missing redstone card or block!")
component.invoke(redstone, "setOutput", rightOutput, redstoneOutput)
component.invoke(redstone, "setOutput", leftOutput, redstoneIdle)

computer.beep(500,0.25)
computer.beep(750,0.25)
computer.beep(1000,0.25)

while true do
  local name, _, side, _, value = computer.pullSignal()
  if name == "redstone_changed" and side == signalInput and value >= redstoneThreshold then
    computer.beep(1000, 0.1)
    computer.beep(1000, 0.1)
    computer.beep(1000, 0.1)
    if component.invoke(redstone, "getOutput", rightOutput) == redstoneOutput then
      component.invoke(redstone, "setOutput", rightOutput, redstoneIdle)
      component.invoke(redstone, "setOutput", leftOutput, redstoneOutput)
    else
      component.invoke(redstone, "setOutput", leftOutput, redstoneIdle)
      component.invoke(redstone, "setOutput", rightOutput, redstoneOutput)    
    end
  end
end


[12:08 PM] don_bruce: BTW, if you want nother input here's what the numbers mean.
[12:08 PM] don_bruce: 
Bottom (bottom), Number: 0
Top (top), Number: 1
Back (back), Number: 2
Front (front), Number: 3
Right (right), Number: 4
Left (left), Number: 5
