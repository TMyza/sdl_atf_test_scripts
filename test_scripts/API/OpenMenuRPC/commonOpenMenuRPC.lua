---------------------------------------------------------------------------------------------------
-- Common module
---------------------------------------------------------------------------------------------------
--[[ General configuration parameters ]]
config.defaultProtocolVersion = 2

 --[[ Required Shared libraries ]]
local actions = require("user_modules/sequences/actions")

 --[[ Variables ]]
local m = actions

 --[[ Functions]]
function m.addSubMenu(pMenuID)
  local cid = m.getMobileSession():SendRPC("AddSubMenu",
    {
      menuID = pMenuID,
      position = 500,
      menuName ="SubMenupositive"
    })
    EXPECT_HMICALL("UI.AddSubMenu",
      {
        menuID = pMenuID,
        menuParams = {
          position = 500,
          menuName ="SubMenupositive"
        }
      })
:Do(function(_,data)
  m.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
end)
m.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
m.getMobileSession():ExpectNotification("OnHashChange",{})
end

function m.showAppMenu(pMenuID)
  local cid = m.getMobileSession():SendRPC("ShowAppMenu", { menuID = pMenuID })
  m.getHMIConnection():ExpectRequest("UI.ShowAppMenu", {})
  :Do(function(_, data)
    m.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
  end)
  m.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
end

function m.hmiSystemContextMENU(pAppId)
  if not pAppId then pAppId = 1 end
  m.getHMIConnection(pAppId):SendNotification("BasicCommunication.OnAppDeactivated",
    { appID = m.getHMIAppId(pAppId) })
  m.getMobileSession(pAppId):ExpectNotification("OnHMIStatus",
    { hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MENU" })
end

return m
