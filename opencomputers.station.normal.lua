-- Front/Back Station STop
-- Redstone intput to active on 'front'
-- Redstone output to activate controller on 'rear'
local redstone = component.list("redstone")()
local frontInput = 3
local backOutput = 2
local redstoneThreshold = 1
local redstoneOutput = 4
local redstoneIdle = 0
function os.sleep(timeout)
  local deadline = computer.uptime() + (timeout or 0)
  repeat
    computer.pullSignal(deadline - computer.uptime())
  until computer.uptime() >= deadline
end

assert(redstone, "Missing redstone card or block!")
component.invoke(redstone, "setOutput", backOutput, redstoneIdle)

computer.beep(500,0.25)
computer.beep(750,0.25)
computer.beep(1000,0.25)

while true do
  local name, _, side, _, value = computer.pullSignal()
  if name == "redstone_changed" then
    if side == frontInput then
      if value >= redstoneThreshold then
  computer.beep(400,0.25)
  os.sleep(5)
        component.invoke(redstone, "setOutput", backOutput, redstoneOutput)
        computer.beep(1000, 0.1)
        computer.beep(1000, 0.1)
        computer.beep(1000, 0.1)
      else
  os.sleep(10)
        component.invoke(redstone, "setOutput", backOutput, redstoneIdle)
      end
    end
  end
end
