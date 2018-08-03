---------------------------------------------------------------------------------------------------
-- User story: Smoke
-- Use case: SetMediaClockTimer
-- Item: Happy path
--
-- Requirement summary:
-- [SetMediaClockTimer] SUCCESS: getting SUCCESS:UI.SetMediaClockTimer()
--
-- Description:
-- Mobile application sends valid SetMediaClockTimer request and gets UI.SetMediaClockTimer "SUCCESS" response from HMI

-- Pre-conditions:
-- a. HMI and SDL are started
-- b. appID is registered and activated on SDL
-- c. appID is currently in Background, Full or Limited HMI level

-- Steps:
-- appID requests SetMediaClockTimer with valid parameters

-- Expected:
-- SDL validates parameters of the request
-- SDL checks if UI interface is available on HMI
-- SDL checks if SetMediaClockTimer is allowed by Policies
-- SDL checks if all parameters are allowed by Policies
-- SDL transfers the UI part of request with allowed parameters to HMI
-- SDL receives UI part of response from HMI with "SUCCESS" result code
-- SDL responds with (resultCode: SUCCESS, success:true) to mobile application
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonFunctions = require("user_modules/shared_testcases/commonFunctions")
local commonSmoke = require('test_scripts/Smoke/commonSmoke')

--[[ Local Variables ]]
local updateMode = {"COUNTUP", "COUNTDOWN", "PAUSE", "RESUME", "CLEAR"}

local requestParams = {
  startTime = {
    hours = 0,
    minutes = 1,
    seconds = 33
  },
  endTime = {
    hours = 0,
    minutes = 1 ,
    seconds = 35
  }
}

local indicator = {"PLAY_PAUSE", "PLAY", "PAUSE", "STOP"}

--[[ Local Functions ]]
local function SetMediaClockTimer(pParams, pMode, pIndicator, self)
  local Parameters = commonFunctions:cloneTable(pParams)
  Parameters.updateMode = pMode
  Parameters.audioStreamingIndicator = pIndicator
  if pMode == "COUNTDOWN" then
    Parameters.endTime.minutes = Parameters.startTime.minutes - 1
  end
  local cid = self.mobileSession1:SendRPC("SetMediaClockTimer", Parameters)
  Parameters.appID = commonSmoke.getHMIAppId()
  EXPECT_HMICALL("UI.SetMediaClockTimer", Parameters)
  :Do(function(_,data)
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  self.mobileSession1:ExpectResponse(cid, { success = true, resultCode = "SUCCESS"})
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonSmoke.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonSmoke.start)
runner.Step("RAI", commonSmoke.registerApp)
runner.Step("Activate App", commonSmoke.activateApp)

runner.Title("Test")
for _, value in pairs (updateMode) do
  for _, value2 in pairs (indicator) do
    runner.Step("SetMediaClockTimer Positive Case with udate mode " .. value .. " " .. value2 , SetMediaClockTimer, { requestParams,value,value2 })
  end
end

runner.Title("Postconditions")
runner.Step("Stop SDL", commonSmoke.postconditions)
