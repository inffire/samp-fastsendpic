script_name("fastsendpic")
script_author("inf")
script_moonloader(018)
script_description("sending seen pickup via RBUTTON+F")
script_version_number(1)
script_version("v1")
script_dependencies("samp", "sampfuncs", "cleo")

require "lib.moonloader"
require "lib.sampfuncs"

local mem = require "memory"
local Vector3D = require "vector3d"

local ACT_PRIMARY_KEY		= VK_RBUTTON -- /lib/samp/vkeys.lua
local ACT_SECONDARY_KEY		= VK_F
local MAX_SENDING_DISTANCE	= 75.0
local MAX_SENDING_FOV		= 62.0

local stPickupPtr 			= nil

function main()
	if not isSampLoaded() or not isCleoLoaded() or not isSampfuncsLoaded() then return end
	while not isSampAvailable() do wait(100) end
	
	while not stPickupPtr do stPickupPtr = sampGetPickupPoolPtr(); wait(100) end
	stPickupPtr = stPickupPtr + 0xf004

	MAX_SENDING_FOV = MAX_SENDING_FOV * math.pi / 180.0

	while true do
		if isKeyDown(ACT_PRIMARY_KEY) and isKeyJustPressed(ACT_SECONDARY_KEY) then
			local result = {}
			for i=0, MAX_PICKUPS-1 do
				local m = mem.getuint32(stPickupPtr + i*20 + 0x04)
				if m and m ~= 0 then
					local pickup = Vector3D(
						mem.getfloat(stPickupPtr + i*20 + 0x08),
						mem.getfloat(stPickupPtr + i*20 + 0x0C),
						mem.getfloat(stPickupPtr + i*20 + 0x10)
					)
					local camera = Vector3D(getActiveCameraCoordinates())
					local pickup_offset = pickup - camera
					local distance_to_pickup = pickup_offset:length()

					if distance_to_pickup < MAX_SENDING_DISTANCE and distance_to_pickup > 0 then
						local camera_look_at = Vector3D(getActiveCameraPointAt())
						local camera_direction = camera_look_at - camera
						local camera_to_pickup = camera_direction * distance_to_pickup
						local diff = camera_to_pickup - pickup_offset
						local angle_to_pickup = math.atan(diff:length() / distance_to_pickup)
						if angle_to_pickup < MAX_SENDING_FOV / 2 then table.insert(result, {i, angle_to_pickup}) end
					end
				end
			end
			if #result > 0 then
				table.sort(result, function(a,b) return a[2]<b[2] end)
				sampSendPickedUpPickup(result[1][1])
			end
		end
		wait(32)
	end
end
