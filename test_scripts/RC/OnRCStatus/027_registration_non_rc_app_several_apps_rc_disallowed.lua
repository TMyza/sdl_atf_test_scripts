---------------------------------------------------------------------------------------------------
-- User story: TBD
-- Use case: TBD
--
-- Requirement summary:
-- [SDL_RC] TBD
--
-- Description:
-- In case:
-- 1) RC functionality is disallowed on HMI
-- 2) RC app1 is registered
-- 3) Non-RC app2 is registered
-- 4) Non-RC app3 starts registration
-- SDL must:
-- 1) not send an OnRCStatus notification to the newly registered non-RC app
-- 2) not send an OnRCStatus notification to the HMI
-- 3) not send OnRCStatus notifications to the already registered RC apps
-- 4) not send OnRCStatus notifications to the already registered non-RC apps
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/RC/OnRCStatus/commonOnRCStatus')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ General configuration parameters ]]
config.application1.registerAppInterfaceParams.appHMIType = { "REMOTE_CONTROL" }
config.application2.registerAppInterfaceParams.appHMIType = { "DEFAULT" }
config.application3.registerAppInterfaceParams.appHMIType = { "DEFAULT" }

--[[ Local Functions ]]
local function disableRCFromHMI()
  common.getHMIConnection():SendNotification("RC.OnRemoteControlSettings", { allowed = false })
  common.wait(2000)
end

local function registerAppOnRCStatusAllowFalse(pAppId)
  common.registerAppWOPTU(pAppId)
  common.getMobileSession(pAppId):ExpectNotification("OnRCStatus",
	{ allowed = false, freeModules = {}, allocatedModules = {} })
  EXPECT_HMINOTIFICATION("RC.OnRCStatus")
  :Times(0)
end

local function registerNonRCAppSeveralApps()
  common.registerNonRCApp(3)
  common.getMobileSession(1):ExpectNotification("OnRCStatus")
  :Times(0)
  common.getMobileSession(2):ExpectNotification("OnRCStatus")
  :Times(0)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RC functionality is disallowed from HMI", disableRCFromHMI)
runner.Step("RC app1 registration", registerAppOnRCStatusAllowFalse, { 1 })
runner.Step("Non-RC app2 registration", common.registerNonRCApp, { 2 })

runner.Title("Test")
runner.Step("Registration non-RC app3", registerNonRCAppSeveralApps)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
