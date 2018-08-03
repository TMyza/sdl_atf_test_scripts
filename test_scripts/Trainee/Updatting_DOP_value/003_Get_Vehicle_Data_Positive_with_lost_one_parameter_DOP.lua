---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0175-Updating-DOP-value-range-for-GPS-notification.md
---------------------------------------------------------------------------------------------------
-- In case:
-- 1. Mob app sends request GetVehicleData to SDL with gps parametr = true
-- 2. SDL resends this request to HMI with gps parameter = true
-- 3. HMI sends response without one of three gps parameters: "pdop", "hdop", "vdop" to SDL
-- SDL does:
-- 4. Resends notification to Mob App without one of three gps parameters: "pdop", "hdop", "vdop"
---------------------------------------------------------------------------------------------------
-- [[ Required Shared libraries ]]
local common = require('test_scripts/Trainee/Updatting_DOP_value/commonDOP')
local runner = require('user_modules/script_runner')

-- [[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false
local value = 1000

-- [[ Scenario ]]
runner.Title("Precondition")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile", common.start)
runner.Step("Register App", common.registerApp)
runner.Step("PolicyTableUpdate", common.policyTableUpdate, { common.ptUpdate })
runner.Step("Activate App", common.activateApp)

-- [[ Test ]]
runner.Title("Test")
for k in ipairs(common.params_combi) do
    runner.Step("Send GetVehicleData" .. k .. "=" .. tostring(value), common.sendGetVehicleDataLostOneParameter, { common.params_combi[k], value })
end

-- [[ Postconditions ]]
runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
