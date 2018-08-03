--------------------------------------------------------------------------------------------------
-- Common module
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local actions = require("user_modules/sequences/actions")
local security = require("user_modules/sequences/security")
local utils = require("user_modules/utils")
local test = require("user_modules/dummy_connecttest")
local commonFunctions = require("user_modules/shared_testcases/commonFunctions")
local common = require("test_scripts/Security/SSLHandshakeFlow/common")

--[[ General configuration parameters ]]
config.serverCertificatePath = "./files/Security/GetSystemTime_certificates/spt_credential.pem"
config.serverPrivateKeyPath = "./files/Security/GetSystemTime_certificates/spt_credential.pem"
config.serverCAChainCertPath = "./files/Security/GetSystemTime_certificates/spt_credential.pem"

--[[ Module ]]
local m = actions

--[[ General configuration parameters ]]
config.defaultProtocolVersion = 3
config.isCheckClientCertificate = false
config.application1.registerAppInterfaceParams.appName = "server"
config.application1.registerAppInterfaceParams.appID = "SPT"
m.appHMIType = "DEFAULT"
config.application1.registerAppInterfaceParams.appHMIType = { m.appHMIType }

--[[ Variables ]]
m.frameInfo = security.frameInfo
m.delayedExp = utils.wait
m.readFile = utils.readFile

--[[ Functions ]]
function m.getSystemTimeValue()
  return {
    millisecond = 100,
    second = 30,
    minute = 29,
    hour = 15,
    day = 20,
    month = 3,
    year = 2018,
    tz_hour = -3,
    tz_minute = 10
  }
end

function m.getAppID(pAppId)
  return m.getConfigAppParams(pAppId).appID
end

local function allowSDL()
  test.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality", {
    allowed = true,
    source = "GUI",
    device = {
      id = utils.getDeviceMAC(),
      name = utils.getDeviceName()
    }
  })
end

function m.start(pOnSystemTime, pHMIParams)
  test:runSDL()
  commonFunctions:waitForSDLStart(test)
  :Do(function()
      test:initHMI()
      :Do(function()
          utils.cprint(35, "HMI initialized")
          test:initHMI_onReady(pHMIParams)
          :Do(function()
              utils.cprint(35, "HMI is ready")
              if pOnSystemTime then
                m.getHMIConnection():SendNotification("BasicCommunication.OnSystemTimeReady")
              end
              test:connectMobile()
              :Do(function()
                  utils.cprint(35, "Mobile connected")
                  allowSDL(test)
                end)
            end)
        end)
    end)
end

local function expectHandshakeMessage(pGetSystemTimeOccur, pTime, pHandshakeOccurences)
  m.getMobileSession():ExpectHandshakeMessage()
  :Times(pHandshakeOccurences)

  EXPECT_HMICALL("BasicCommunication.GetSystemTime")
  :Do(function(_, d)
    m.getHMIConnection():SendResponse(d.id, d.method, "SUCCESS", { systemTime = pTime })
  end)
  :Times(pGetSystemTimeOccur)
end

function m.startServiceSecured(pData, pServiceId, pGetSystemTimeOccur, pTime, pHandshakeOccurences)
  m.getMobileSession():StartSecureService(pServiceId)
  m.getMobileSession():ExpectControlMessage(pServiceId, pData)

  m.getHMIConnection():ExpectNotification("SDL.OnStatusUpdate")
  :Times(0)

  expectHandshakeMessage(pGetSystemTimeOccur, pTime, pHandshakeOccurences)
end

local function expNotDuringPTU()
  m.getHMIConnection():ExpectRequest("VehicleInfo.GetVehicleData", { odometer = true })
end

function m.startServiceSecuredwithPTU(pData, pServiceId, pGetSystemTimeOccur, pTime, pPTUpdateFunc, pHandshakeOccurences)
  m.getMobileSession():StartSecureService(pServiceId)
  m.getMobileSession():ExpectControlMessage(pServiceId, pData)

  m.getHMIConnection():ExpectNotification("SDL.OnStatusUpdate",
    { status = "UPDATE_NEEDED" }, { status = "UPDATING" }, { status = "UP_TO_DATE" })
    :Times(3)
    :Do(function(e)
      if e.occurences == 1 then
        m.policyTableUpdate(pPTUpdateFunc, expNotDuringPTU)
      end
    end)

  expectHandshakeMessage(pGetSystemTimeOccur, pTime, pHandshakeOccurences)
end

m.postconditions = common.postconditions

local preconditionsOrig = m.preconditions
function m.preconditions()
  preconditionsOrig()
  common.initSDLCertificates("./files/Security/GetSystemTime_certificates/client_credential.pem", false)
end

local policyTableUpdate_orig = m.policyTableUpdate

function m.policyTableUpdate(pPTUpdateFunc)
  local function expNotificationFunc()
    m.getHMIConnection():ExpectRequest("BasicCommunication.DecryptCertificate")
    :Do(function(_, d)
        m.getHMIConnection():SendResponse(d.id, d.method, "SUCCESS", { })
      end)
    :Times(AnyNumber())
    m.getHMIConnection():ExpectRequest("VehicleInfo.GetVehicleData", { odometer = true })
  end
  policyTableUpdate_orig(pPTUpdateFunc, expNotificationFunc)
end

return m
