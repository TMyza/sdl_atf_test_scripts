---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_core/issues/965
--
-- Precondition:
-- 1) SDL Core and HMI are started. App is registered, HMI level = FULL
-- 2) App is registered
-- Description:
-- Steps to reproduce:
-- 1) Send 10 ListFiles request from app
-- Expected:
-- 1) App is unregistered by REQUEST_WHILE_IN_NONE_HMI_LEVEL reason
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Defects/commonDefects')
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')

-- [[Local variables]]
local count_of_requests = 1

--[[ Local Functions ]]
local function updateINIFile()
  common.backupINIFile()
  commonFunctions:write_parameter_to_smart_device_link_ini("AppHMILevelNoneTimeScaleMaxRequests", count_of_requests)
  commonFunctions:write_parameter_to_smart_device_link_ini("AppHMILevelNoneRequestsTimeScale", 30000)
end

local function listFilesRequests(self)
	for i = 1, 10 do
		self.mobileSession1:SendRPC("ListFiles", {})
	end
	self.mobileSession1:ExpectResponse("ListFiles")
	:Do(function(_, data)
		if data.payload.resultCode == "SUCCESS" then
			return true
		elseif data.payload.resultCode == "APPLICATION_NOT_REGISTERED" then
			return true
		else return false, "Received unexpected resultCode " .. data.payload.resultCode
		end
	end)
	:Times(Between(1,10))
	EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", {appID = common.getHMIAppId(), unexpectedDisconnect = false})
	self.mobileSession1:ExpectNotification("OnAppInterfaceUnregistered", { reason = "REQUEST_WHILE_IN_NONE_HMI_LEVEL" })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Update .ini file", updateINIFile)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI", common.rai_n)

runner.Title("Test")
runner.Step("App is unregistered by REQUEST_WHILE_IN_NONE_HMI_LEVEL reason", listFilesRequests)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
runner.Step("Restore INI file", common.restoreINIFile)
