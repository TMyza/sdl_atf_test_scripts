---------------------------------------------------------------------------------------------------
-- Proposal:https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0257-New-vehicle-data-HandsOffSteering.md
--
-- Description: Check that SDL rejects UnsubscribeVehicleData request with resultCode "DISALLOWED" if 'handsOffSteering'
-- parameter is not allowed by policy after PTU
--
-- Preconditions:
-- 1) SDL and HMI are started
-- 2) RPCs SubscribeVehicleData, UnsubscribeVehicleData and handsOffSteering parameter are allowed by policies
-- 3) App is registered and subscribed to handsOffSteering data
--
-- In case:
-- 1) App sends valid UnsubscribeVehicleData(handsOffSteering=true) request to SDL
-- SDL does:
-- - a) transfer this request to HMI
-- 2) HMI sends VehicleInfo.UnsubscribeVehicleData response with handsOffSteering data to SDL
-- SDL does:
-- - a) send UnsubscribeVehicleData response with (success = true, resultCode = "SUCCESS",
--    handsOffSteering = <data received from HMI>) to App
-- 3) App is subscribed to handsOffSteering data again
-- 4) PTU is performed with disabling permissions for handsOffSteering parameter
-- 5) App sends valid UnsubscribeVehicleData(handsOffSteering=true) request to SDL
-- SDL does:
-- - a) send UnsubscribeVehicleData response with (success = false, resultCode = "DISALLOWED") to App
-- - b) not transfer this request to HMI
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/HandsOffSteering/common')

--[[ Local Variables ]]
local rpc_sub = "SubscribeVehicleData"
local rpc_unsub = "UnsubscribeVehicleData"
local result = "DISALLOWED"

--[[ Local Function ]]
local function ptUpdate(pt)
  local pGroups = {
    rpcs = {
      UnsubscribeVehicleData = {
        hmi_levels = { "NONE", "BACKGROUND", "LIMITED", "FULL" },
        parameters = { "gps" }
      },
      OnVehicleData = {
        hmi_levels = { "NONE", "BACKGROUND", "LIMITED", "FULL" },
        parameters = { "handsOffSteering" }
      }
    }
  }
  pt.policy_table.functional_groupings["NewTestCaseGroup"] = pGroups
  pt.policy_table.app_policies[common.getAppParams().fullAppID].groups = { "Base-4", "NewTestCaseGroup" }
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment and update preloaded_pt file", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App", common.registerApp)
common.Step("App subscribes to handsOffSteering data", common.processSubscriptionRPC, { rpc_sub })
common.Step("Check allow " .. rpc_unsub .. " RPC", common.processSubscriptionRPC, { rpc_unsub })
common.Step("App subscribes to handsOffSteering data again", common.processSubscriptionRPC, { rpc_sub })

common.Title("Test")
common.Step("Policy Table Update with disabling permissions for handsOffSteering",
  common.policyTableUpdate, { ptUpdate })
common.Step("RPC " .. rpc_unsub .. " with handsOffSteering parameter DISALLOWED after PTU",
  common.processRPCFailure, { rpc_unsub, result })
common.Step("Check that App is still subscribed", common.sendOnVehicleData)

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
