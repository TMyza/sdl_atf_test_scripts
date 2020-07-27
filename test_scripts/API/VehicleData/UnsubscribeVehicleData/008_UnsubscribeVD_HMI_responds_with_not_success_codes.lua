---------------------------------------------------------------------------------------------------
-- Description: Check Processing of UnsubscribeVehicleData request
-- if HMI respond with unsuccessful resultCode for <vd_param> parameter
--
-- Preconditions:
-- 1) SDL and HMI are started
-- 2) SubscribeVehicleData, UnsubscribeVehicleData RPCs and <vd_param> parameter are allowed by policies
-- 3) App is registered
-- 4) App is subscribed to <vd_param> data
--
-- In case:
-- 1) App sends UnsubscribeVehicleData(<vd_param>=true) request to the SDL
-- SDL does:
--  a) transfer this request to HMI.
-- 2) HMI responds with "SUCCESS" result to UnsubscribeVehicleData request
--  and with not success result for <vd_param> vehicle data
-- SDL does:
--  a) respond "GENERIC_ERROR", success:false and with unsuccessful resultCode for <vd_param> data to the mobile app
-- Note: expected behavior is under clarification in https://github.com/smartdevicelink/sdl_core/issues/3384
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/common')

--[[ Local Variables ]]
local resultCodes = {
  "TRUNCATED_DATA",
  "DISALLOWED",
  "USER_DISALLOWED",
  "INVALID_ID",
  "VEHICLE_DATA_NOT_AVAILABLE",
  "DATA_NOT_SUBSCRIBED",
  "IGNORED",
  "DATA_ALREADY_SUBSCRIBED"
}

--[[ Local Functions ]]
local function unsubscribeVDwithUnsuccessCodeForVD(pParam, pCode)
  local response = { dataType = common.vd[pParam], resultCode = pCode}
  local cid = common.getMobileSession():SendRPC("UnsubscribeVehicleData", { [pParam] = true })
  common.getHMIConnection():ExpectRequest("VehicleInfo.UnsubscribeVehicleData", { [pParam] = true })
  :Do(function(_,data)
    common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", { [pParam] = response })
  end)
  common.getMobileSession():ExpectResponse(cid, { success = false, resultCode = "GENERIC_ERROR", [pParam] = response })
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment and update preloaded_pt file", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App", common.registerApp)

common.Title("Test")
for param in common.spairs(common.getVDParams(true)) do
  common.Title("VD parameter: " .. param)
  common.Step("RPC " .. common.rpc.sub, common.processSubscriptionRPC, { common.rpc.sub, param })
  for _, code in common.spairs(resultCodes) do
    common.Step("RPC " .. common.rpc.unsub .. " resultCode " .. code,
      unsubscribeVDwithUnsuccessCodeForVD, { param, code })
  end
end

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
