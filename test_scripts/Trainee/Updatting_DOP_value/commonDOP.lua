---------------------------------------------------------------------------------------------------
-- Common module
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local actions = require("user_modules/sequences/actions")

-- [[ Module ]]
local m = actions

-- [[ Parameters ]]
m.params = { "pdop", "hdop", "vdop" }
m.params_combi = {
    { a = "pdop", b = "hdop" },
    { a = "hdop", b = "vdop" },
    { a = "vdop", b = "pdop" }
}

-- [[ Functions ]]
function m.sendGetVehicleDataLostOneParameter(pParam, pValue)
    local gpsData = {}    
    gpsData[pParam.a] = pValue
    gpsData[pParam.b] = pValue
    local cid = m.getMobileSession():SendRPC("GetVehicleData", { gps = true })
    m.getHMIConnection():ExpectRequest("VehicleInfo.GetVehicleData", { gps = true })
    :Do(function(_, data)
        m.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", { gps = gpsData })
        end)
    m.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS", gps = gpsData })
end

function m.sendGetVehicleDataPositive(pParam, pValue)
    local gpsData = {}
    gpsData[pParam] = pValue
    local cid = m.getMobileSession():SendRPC("GetVehicleData", { gps = true })
    m.getHMIConnection():ExpectRequest("VehicleInfo.GetVehicleData", { gps = true })
    :Do(function(_, data)
        m.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", { gps = gpsData })
        end)
    m.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS", gps = gpsData })
end

function m.sendGetVehicleDataNegative(pParam, pValue)
    local gpsData = {}
    gpsData[pParam] = pValue
    local cid = m.getMobileSession():SendRPC("GetVehicleData", { gps = true })
    m.getHMIConnection():ExpectRequest("VehicleInfo.GetVehicleData", { gps = true })
    :Do(function(_, data)
        m.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", { gps = gpsData })
        end)
    m.getMobileSession():ExpectResponse(cid, { success = false, resultCode = "GENERIC_ERROR" })
end

function m.sendOnVehicleDataLostOneParameter(pParam, pValue)
    local gpsData = {}
    gpsData[pParam.a] = pValue
    gpsData[pParam.b] = pValue
    m.getHMIConnection():SendNotification("VehicleInfo.OnVehicleData", { gps = gpsData })
    m.getMobileSession():ExpectNotification("OnVehicleData", { gps = gpsData })
end

function m.sendOnVehicleDataPositive(pParam, pValue)
    local gpsData = {}
    gpsData[pParam] = pValue
    m.getHMIConnection():SendNotification("VehicleInfo.OnVehicleData", { gps = gpsData })
    m.getMobileSession():ExpectNotification("OnVehicleData", { gps = gpsData })
end

function m.sendOnVehicleDataNegative(pParam, pValue)
    local gpsData = {}
    gpsData[pParam] = pValue
    m.getHMIConnection():SendNotification("VehicleInfo.OnVehicleData", { gps = gpsData })
    m.getMobileSession():ExpectNotification("OnVehicleData")
    :Times(0)
end

function m.subscribeVehicleData()
    local gpsResponseData = {
      dataType = "VEHICLEDATA_GPS",
      resultCode = "SUCCESS"
    }
    local cid = m.getMobileSession():SendRPC("SubscribeVehicleData", { gps = true })
    m.getHMIConnection():ExpectRequest("VehicleInfo.SubscribeVehicleData", { gps = true })
    :Do(function(_, data)
        m.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", { gps = gpsResponseData })
    end)
    m.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS", gps = gpsResponseData })
end


return m
