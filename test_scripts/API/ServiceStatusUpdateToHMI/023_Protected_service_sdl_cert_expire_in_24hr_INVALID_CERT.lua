---------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0211-ServiceStatusUpdateToHMI.md
-- Description: The attempt to open the protected Video, Audio, RPC services with unsuccessful OnStatusUpdate
-- (REQUEST_REJECTED, INVALID_CERT) notification in case certification in DB after update is not valid and services are
-- force protected
-- Precondition:
-- 1) App is registered with NAVIGATION appHMIType and activated.
-- In case:
-- 1) Mobile app requests StartService (SERVICETYPE, encryption = true)
-- SDL does:
-- 1) send StartSream() to HMI
-- 2) send OnServiceUpdate (SERVICETYPE, REQUEST_RECEIVED) to HMI
-- 3) send GetSystemTime_Rq() and wait response from HMI GetSystemTime_Res()
-- 4) send OnStatusUpdate(UPDATE_NEEDED)
-- In case:
-- 2) Policy Table Update is Successful
-- SDL does:
-- 1) send OnStatusUpdate(UP_TO_DATE) if Policy Table Update is successful
-- In case:
-- 3) Cert is about to expire in next 24 hrs
-- SDL does:
-- 1) send OnServiceUpdate (SERVICETYPE, INVALID_CERT) to HMI
-- 2) send StartServiceNACK (SERVICETYPE, encryption = false) to mobile app
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/ServiceStatusUpdateToHMI/common')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Functions ]]
function common.sendGetSystemTimeResponse(pId, pMethod)
  local st = {
    millisecond = 100,
    second = 30,
    minute = 29,
    hour = 15,
    day = 18,
    month = 4,
    year = 2045,
    tz_hour = -3,
    tz_minute = 10
  }
  common.getHMIConnection():SendResponse(pId, pMethod, "SUCCESS", { systemTime = st })
end

function common.onServiceUpdateFunc(pServiceTypeValue)
  common.getHMIConnection():ExpectNotification("BasicCommunication.OnServiceUpdate",
    { serviceEvent = "REQUEST_RECEIVED", serviceType = pServiceTypeValue, appID = common.getHMIAppId() },
    { serviceEvent = "REQUEST_REJECTED", serviceType = pServiceTypeValue, appID = common.getHMIAppId(),
      reason = "INVALID_CERT" })
  :Times(2)
end

function common.serviceResponseFunc(pServiceId)
  common.getMobileSession():ExpectControlMessage(pServiceId, {
    frameInfo = common.frameInfo.START_SERVICE_NACK,
    encryption = false
  })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions, { "0x0A, 0x0B" })
runner.Step("Init SDL certificates", common.initSDLCertificates,
  { "./files/Security/client_credential.pem", true })
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("App registration", common.registerApp)
runner.Step("PolicyTableUpdate", common.policyTableUpdate)
runner.Step("App activation", common.activateApp)

runner.Title("Test")
runner.Step("Start Video Service protected", common.startServiceWithOnServiceUpdate, { 11, 0, 1 })
runner.Step("Start Audio Service protected", common.startServiceWithOnServiceUpdate, { 10, 0, 1 })
runner.Step("Start RPC Service protected", common.startServiceWithOnServiceUpdate, { 7, 0, 1 })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
