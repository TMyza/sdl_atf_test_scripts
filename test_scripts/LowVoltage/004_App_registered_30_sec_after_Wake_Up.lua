---------------------------------------------------------------------------------------------------
--
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/LowVoltage/common')
local runner = require('user_modules/script_runner')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local hashId = { }
local grammarId = { }

--[[ Local Functions ]]
local function addResumptionData()
  local pAppId = 1
  local cid = common.getMobileSession(pAppId):SendRPC("AddCommand", { cmdID = 1, vrCommands = { "OnlyVRCommand" }})
  common.getHMIConnection():ExpectRequest("VR.AddCommand")
  :Do(function(_, data)
      grammarId[pAppId] = data.params.grammarID
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
    end)
  common.getMobileSession(pAppId):ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
  common.getMobileSession(pAppId):ExpectNotification("OnHashChange")
  :Do(function(_, data)
      hashId[pAppId] = data.payload.hashID
    end)
end

local function checkResumptionData()
  local pAppId = 1
  common.getHMIConnection():ExpectRequest("VR.AddCommand", {
    cmdID = 1,
    vrCommands = { "OnlyVRCommand" },
    type = "Command",
    grammarID = grammarId[pAppId],
    appID = common.getHMIAppId(pAppId)
  })
  :Do(function(_, data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS")
    end)
end

local function checkResumptionHMILevel()
  common.getHMIConnection():ExpectRequest("BasicCommunication.ActivateApp", { appID = common.getHMIAppId(1) })
  :Times(0)
  common.getMobileSession():ExpectNotification("OnHMIStatus",
    { hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" })
end

local function wait()
  common.cprint(35, "Wait 31 sec")
  common.delayedExp(31100)
end

local function checkAppId(pAppId, pData)
  if pData.params.application.appID ~= common.getHMIAppId(pAppId) then
    return false, "App " .. pAppId .. " is registered with not the same HMI App Id"
  end
  return true
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile", common.start)

runner.Step("Register App", common.registerApp)
runner.Step("PolicyTableUpdate for App", common.policyTableUpdate)
runner.Step("Activate App", common.activateApp)
runner.Step("Add resumption data for App", addResumptionData)

runner.Title("Test")

runner.Step("Wait until Resumption Data is stored" , common.waitUntilResumptionDataIsStored)

runner.Step("Send LOW_VOLTAGE signal", common.sendMQLowVoltageSignal)

runner.Step("Send WAKE_UP signal", common.sendMQWakeUpSignal)
runner.Step("Wait", wait)

runner.Step("Re-connect Mobile", common.connectMobile)
runner.Step("Re-register App, check resumption of Data and no resumption of HMI level", common.reRegisterApp, {
  1, hashId, checkAppId, checkResumptionData, checkResumptionHMILevel, "SUCCESS", 5000
})

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
