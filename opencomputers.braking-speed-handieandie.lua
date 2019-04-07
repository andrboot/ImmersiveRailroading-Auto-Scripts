--[[
Author: Andrew Lalis
Tweaked: Andrew B
Tweaked More: LtBrandon
File: train_control.lua
Version: 1.1
Last Modified: 26-01-2019 - Andrboot

This script provides simple ways to set target velocities and distances for
trains from the mod Immersive Engineering. To set it up, place two augments,
one detector and one controller, on the same rail tie, and connect both to a
computer.

This script focuses on two major actions:
	1. Slowing down the train with brakes.
	2. Speeding up with the throttle.
Requires - Redstonecard
]]--

local DEBUG = false
local VERBOSE = true
local EndScriptAutomatically = false
local EndScript = false
--[[
This function can be implemented by users for added functionality.

stock - table: The result of detector.info()
consist - table: The result of detector.consist()
controller - augment: The locomotive controller augment.
--]]
local function onTrainOverhead(stock, consist, controller)
	controller.horn()
end

--[[
How many decimal points of precision should throttle setting have?
Set it to a power of 0.1. Note that more precision means MUCH MORE
computational complexity.
--]]
local THROTTLE_PRECISION = 0.001

local CONFIG_FILE = "ir_speed_control_config"



-- Only enable OC-specific modules if not in debug.
local component = nil
local event = nil
local fs = nil
local serialization = nil
local term = nil

local detector = nil
local control = nil

if (not DEBUG) then
	component = require("component")
	event = require("event")
	fs = require("filesystem")
	serialization = require("serialization")
	term = require("term")
	detector = component.ir_augment_detector
	control = component.ir_augment_control
end

local SPEED_RATIO = 20 * 3.6
local SLIP_CONSTANT = 1.0
local LOCO_PREFIX = "rolling_stock/locomotives/"

local function toMetric(v)
	return v * SPEED_RATIO
end

local function fromMetric(v)
	return v / SPEED_RATIO
end

local function getSlip(v)
    -- TODO: Include weather and biome conditions.
    local SlipMult = SLIP_CONSTANT

    if math.abs(v) >= 0.0001 then
        SlipMult = SlipMult * (1 - 0.004 * math.abs(v))
    end

	return SlipMult
end

--[[
Extracts the locomotive's name from a json filename as given by detector.info()

id - string: The string identifying the type of locomotive.

return - string: The name of the locomotive, with common prefixes and postfixes
removed.
--]]
local function getLocoName(id)
	return string.sub(id, #LOCO_PREFIX + 1, -6)
end

local function formatMps(v)
	return string.format("%.2f", v * 3.6)
end

--[[
Determines the acceleration needed to go from an initial velocity to a final
velocity in x distance.

v_i - float: Initial velocity
v_f - float: Final velocity
x - float: Displacement (distance travelled)

return - float: Acceleration needed to achieve the given final velocity in
x distance.
--]]
local function getAcceleration(v_i, v_f, x)
	return ((v_f * v_f) - (v_i * v_i)) / (2 * x)
end

--[[
Determines the velocity at which static traction becomes greater than applied
traction. At this point, computations should use the applied traction instead
of static.

throttle - float: Throttle setting, between 0 and 1.
horsepower - float: The horsepower of the locomotive.
traction - float: The locomotive's static traction.

return - float: The velocity at which the static friction becomes greater
than applied friction, in Km/h
--]]
local function getTractionIntersect(throttle, horsepower, traction)
	local a = 0.004
	local b = -1
	local c = (1855 * throttle^3 * horsepower) / (1.5 * traction * SLIP_CONSTANT)
	local s1 = (-b + math.sqrt(b^2 - 4*a*c)) / (2 * a)
	local s2 = (-b - math.sqrt(b^2 - 4*a*c)) / (2 * a)
	return s2
end

local function ApplyBrakes(BrakePower)
    if VERBOSE then
		print("  Applying brakes at power: "..BrakePower)
	end

    control.setThrottle(0)
    control.setBrake(BrakePower)
end

--[[
Slows a train down with a constant target acceleration.

    TrainMass = Full mass of train in kg
    TrainVelocity = Train velocity in m/s
    TargetVelocity = Target velocity in m/s
    TargetDistance = Distance to reach target velocity in meters
    StartingTractionNewtons = available from computer api
--]]
local function slowDown(TrainMass, TrainVelocity, TargetVelocity, TargetDistance, StartingTractionNewtons)
    local ConfigBrakeMultiplier = 1.0
    local AccelerationNeeded = -getAcceleration(TrainVelocity, TargetVelocity, TargetDistance) * 0.18

    if VERBOSE then
        print("Starting braking, acceleration needed: ", AccelerationNeeded)
    end

    -- Figure out acceleration from resistance
    local TrainMassLb = 2.20462 * TrainMass
    local RollingResistanceNewtons = TrainMassLb * 0.00667233
    local ResistanceAcceleration = RollingResistanceNewtons / TrainMass

    if ResistanceAcceleration < AccelerationNeeded then
        -- Apply Brakes for remaining acceleration
        AccelerationNeeded = AccelerationNeeded - ResistanceAcceleration

        -- Figure out the maximum Acceleration from the brakes
        local TrainBrakePower = 1.0
        local SlipCoefficient = getSlip((TrainVelocity + TargetVelocity) / 2)
        local MaxAirBrake = math.min(math.min(1, math.pow(TrainBrakePower, 2)) * SlipCoefficient, 1) * loconumber
        local MaxBrakeNewtons = StartingTractionNewtons * MaxAirBrake * ConfigBrakeMultiplier
        local MaxBrakeAcceleration = MaxBrakeNewtons / TrainMass

        if AccelerationNeeded > MaxBrakeAcceleration then
            print("Warning! Train is going too fast and will not stop in time!")
            print("Braking acceleration required: ", AccelerationNeeded)
            print("Braking acceleration available: ", MaxBrakeAcceleration)
            ApplyBrakes(1.0)
        else
            -- I'm sure this could be done mathematically, but we're just going to bruteforce it
            -- because we don't have to worry about performance here.
            local BrakePower = 0
            local BrakePowerStep = 0.001
            local BrakeAcceleration

            repeat
                BrakePower = BrakePower + BrakePowerStep

                local AirBrake = math.min(math.min(1, math.pow(BrakePower * TrainBrakePower, 2)) * SlipCoefficient, 1) * loconumber
                local BrakeNewtons = StartingTractionNewtons * AirBrake * ConfigBrakeMultiplier

                BrakeAcceleration = BrakeNewtons / TrainMass
            until BrakeAcceleration >= AccelerationNeeded

            if VERBOSE then
                print("Train is now braking (BrakeNewtons, BrakeAcceleration, AccelerationNeeded): ")
                print(BrakeNewtons, BrakeAcceleration, AccelerationNeeded)
            end

            -- Tell the train to stop
            ApplyBrakes(BrakePower)
        end
    else
        -- Accelerate? This probably isn't needed, but let me know.
        print("Warning! Train is moving too slow to reach the destination!")
    end
end

local function speedUp(v_i, v_f, target_acceleration, rolling_resistance_force, traction, total_weight, loco_weight, horsepower, half_velocity)
	local required_tractive_effort = target_acceleration * total_weight + rolling_resistance_force
	local integral_force = (v_f - v_i) * required_tractive_effort

	if (VERBOSE) then
		print("  Ft = " .. required_tractive_effort .. " N")
		print("  Integral of Ft = " .. integral_force)
		print()
	end

	local iteration_count = 0
	local step_size = 0.1
	local t = 0
	-- Repeat until desired precision is reached.
	while (step_size >= THROTTLE_PRECISION) do
		t = t + step_size

		local v_half = getTractionIntersect(t, horsepower, traction) / 3.6

		-- The static friction can be ignored completely.

		local function integrate_applied(t, h, v_i, v_f)
			return 1855 * (t^3) * h * (math.log(v_f) - math.log(v_i))
		end

		local function integrate_static(traction, v_i, v_f)
			return 1.5 * traction * SLIP_CONSTANT * ((v_f - 0.002 * (v_f^2)) - (v_i - 0.002 * (v_i^2)))
		end

		local integral_static = 1.5 * traction * SLIP_CONSTANT * ((v_half - 0.002 * (v_half^2)) - (v_i - 0.002 * (v_i^2)))
		local integral_applied = 1855 * (t^3) * horsepower * (math.log(v_f) - math.log(v_half))
		local proposed_integral_force = 0

		if (v_half <= v_i) then
			-- If the intersection is below the speed range, use only applied.
			proposed_integral_force = integrate_applied(t, horsepower, v_i, v_f)
		elseif (v_half >= v_f) then
			-- If the intersection is above the speed range, use only static.
			proposed_integral_force = integrate_static(t, horsepower, v_i, v_f)
		else
			-- The intersection sits between v_i and v_f, so use both.
			proposed_integral_force = integrate_static(traction, v_i, v_half) + integrate_applied(t, horsepower, v_half, v_f)
		end

		if (VERBOSE) then
			print("->| (" .. iteration_count .. ") t = " .. t .. " :")
			print("  | V(1/2) = " .. v_half .. " m/s")
			print("  | Fs + Fa integral = " .. proposed_integral_force)
		end

		-- Check if we've overshot the target force, and go back and increase the precision.
		if (proposed_integral_force > integral_force) then
			t = t - step_size
			step_size = step_size / 10

			if (VERBOSE) then
				print("  | Too much! Increasing precision to " .. step_size)
			end
		end

		iteration_count = iteration_count + 1
	end

	if (VERBOSE) then
		print()
		print("Found target throttle of: " .. t)
		print()
	end

	-- Once the throttle has been computed, then actually set the controls on the locomotive.
	if (not DEBUG) then
		control.setBrake(0)
		control.setThrottle(t)
		print("[+] " .. formatMps(v_i) .. " Km/h -> " .. formatMps(v_f) .. " Km/h, Throttle set to " .. t)
		if (t >= 1.0) then
			print("  ! [WARNING] ! Throttle set to MAX, likely insufficient power.")
		end
	end
end

--[[
Sets the locomotive to either speed up or slow down to attain a specified final
velocity at a distance of x meters(blocks) away.

v_i - float: Initial velocity in Km/h
v_f - float: Final velocity in Km/h
x - float: The distance over which velocity should change, in m.
stock - table: A table of information about the locomotive itself.
consist - table: A table of information about the train as a whole.
--]]
local function setFinalVelocityAtDistance(v_i, v_f, x, stock, consist)
	-- Convert from km/h to m/s
	v_i = v_i / 3.6
	v_f = v_f / 3.6

	-- Physics computations.
	local total_weight = consist.weight_kg
	local average_velocity = v_i + (v_f - v_i) / 2
	local target_acceleration = getAcceleration(v_i, v_f, x)
	local time = (v_f - v_i) / target_acceleration
	local half_velocity = math.sqrt(v_i^2 + (2 * target_acceleration * (x / 2)))
	local rolling_resistance_force = total_weight * 0.01471
	local resting_acceleration = -rolling_resistance_force / total_weight

	if (VERBOSE) then
		print("[DEBUG-INFO]:")
		print("Vi = " .. v_i .. " m/s")
		print("Vf = " .. v_f .. " m/s")
		print("dX = " .. x .. " m")
		print("Total weight = " .. total_weight .. " Kg")
		print("a = " .. target_acceleration .. " m/s^2, dT = " .. time .. " s")
		print("V(1/2) = " .. half_velocity .. " m/s")
		print("Resting acceleration: " .. resting_acceleration .. " m/s^2")
		print()
	end

	-- Locomotive constants.
	-- Additional Magic for Consist combination
	loconumber = 0
	locotracions = 0
	locoweight = 0
	locohorse = 0
		repeat
			loconumber = loconumber + 1
			locotracions = locotracions + consist.locomotives[loconumber].traction
			locoweight = locoweight + consist.locomotives[loconumber].weight
			locohorse = locohorse + consist.locomotives[loconumber].horsepower
		until loconumber == (consist.locomotives.n)
	-- standard Loco Constrants
	loco_name = getLocoName(stock.id)
	weight_loco_kg = locoweight
	loco_traction = locotracions
	horsepower = locohorse

	print("[i] " .. loco_name .. " passed overhead.")

	-- Use the throttle to accelerate.
	if (target_acceleration > resting_acceleration) then
		speedUp(
			v_i,
			v_f,
			target_acceleration,
			rolling_resistance_force,
			loco_traction,
			total_weight,
			weight_loco_kg,
			horsepower,
			half_velocity
		)
	else
        -- Use brakes to slow the train over time.
        -- slowDown(TrainMass, TrainVelocity, TargetVelocity, TargetDistance, StartingTractionNewtons)
		slowDown(
            total_weight,
			v_i,
			v_f,
			x,
			consist.totoal_traction_N
		)
	end

	if (VERBOSE) then
		print("[END]")
		print()
	end
end

local function handleEvent(augment_type, stock_uuid, params)
	local stock = detector.info()
	local rsdetect = component.redstone
	if (augment_type == "LOCO_CONTROL" and stock ~= nil and stock.horsepower ~= nil and rsdetect.getInput(1) == 0) then
		-- Assume that the detector and the controller are at the same point.
        local consist = detector.consist()

        if not consist then return end

		setFinalVelocityAtDistance(
			consist.speed_km,
			params.final_velocity,
			params.distance,
			stock,
			consist
		)

		-- Call user-defined function after all speed-dependent logic is done.

		onTrainOverhead(stock, consist, control)

        EndScript = true
	end
end

--[[
Saves the given table of parameters to a configuration file.

params - table: A table of parameters.
--]]
local function saveParameters(params)
	if (fs ~= nil) then
		local f = io.open(CONFIG_FILE, "w")
		f:write(serialization.serialize(params))
		f:close()
	end
end

--[[
Reads parameters from a configuration file.

return - table: A table of parameters.
--]]
local function readParameters()
	local f = io.open(CONFIG_FILE, "r")
	local params = serialization.unserialize(f:read("*a"))
	f:close()
	return params
end

--[[
Using configuration files and command line arguments, get all needed
parameters for the program.

args - table: Command line arguments.

return - float, float: VF and X
--]]
local function getParameters(args)
	local params = {
		final_velocity = 0,
		distance = 40
	}

	-- Attempt to get arguments from command line, if given.
	if (#args == 2) then
		params.final_velocity = tonumber(args[1])
		params.distance = tonumber(args[2])
		saveParameters(params)
		print("[i] Saved config to file.")
	elseif (fs ~= nil) then
		for k,v in pairs(readParameters()) do
			params[k] = v
		end
		print("[i] Loaded config from file.")
	end

	return params
end

-- DEBUG FUNCTIONS:
local function testRun(v_i, v_f, x, b_e, stock, consist)
	b_a = getBrake(
		v_i / 3.6,
		v_f / 3.6,
		x,
		consist.weight_kg * 0.01471,
		consist.weight_kg,
		stock.traction,
		stock.weight
	)
	local actual = b_a
	local expected = b_e
	local difference = b_a - b_e
	local ratio = b_a / b_e

	print("Test Run:")
	print("  v_i      = " .. v_i .. " km/h")
	print("  v_f      = " .. v_f .. " km/h")
	print("  x        = " .. x .. " m")
	print("Results:")
	print("  expected = " .. b_e)
	print("  actual   = " .. b_a)
	print("  diff     = " .. difference)
	print("  ratio    = " .. ratio)
	print()

end

--------------------------------------------------|
-- ACTUAL SCRIPT: This is the program entry point.|
--------------------------------------------------|




if (not DEBUG) then

	local params = getParameters({...})
	os.sleep(1)

	term.clear()
	print("--------------------------------------")
	print("Immersive Railroading Speed Controller")
	print("--------------------------------------")
	print("| Target Velocity: " .. params.final_velocity .. " Km/h")
	print("| Distance: " .. params.distance .. " m")
	print("--------------------------------------")

	while not EndScriptAutomatically or not EndScript do
		event_name, address, augment_type, stock_uuid = event.pull("ir_train_overhead")
		handleEvent(augment_type, stock_uuid, params)
	end
else
	local stock = {-- Stock
		id = "rolling_stock/locomotives/DEBUG.json",
		weight = 181436,
		traction = 631648,
		horsepower = 4400
	}
	local consist = {-- Consist
		weight_kg = 778204,
		speed_km = 10
	}
	testRun(11.75, 0, 55, 0.054, stock, consist)
	testRun(20.25, 0, 100, 0.123, stock, consist)
	testRun(27.13, 0, 152, 0.143, stock, consist)
	testRun(38.96, 0, 195, 0.211, stock, consist)
end
