---------------------------------------------------------------------------------------------------
-- User story: https://github.com/smartdevicelink/sdl_core/issues/1032
--
-- Precondition:
-- 1) Core, HMI started.
-- 2) Application is registered, HMI level = FULL.
-- Description:
-- Steps to reproduce:
-- 1) Send CreateInteractionChoiceSet with duplicate vrCommands, other parameters are valid.
-- Expected:
-- 1) Choice set isn't created and SDL response resultCode = DUPLICATE_NAME, success=false to mobile.
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Defects/commonDefects')

--[[ Local Functions ]]
local function createInteractionChoiceSetDuplicateName(self)
  local params = {
    interactionChoiceSetID = 100,
    choiceSet = {
      {
        choiceID = 111,
        menuName = "Choice111",
        vrCommands = { "Choice111" }
      },
      {
      choiceID = 112,
      menuName = "Choice112",
      vrCommands = { "Choice111" }
      }
    }
  }
  local cid = self.mobileSession1:SendRPC("CreateInteractionChoiceSet", params)
  EXPECT_HMICALL("VR.AddCommand")
  :Times(0)
  self.mobileSession1:ExpectResponse(cid, { success = false, resultCode = "DUPLICATE_NAME" })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI, PTU", common.rai_n)
runner.Step("Activate App", common.activate_app)

runner.Title("Test")
runner.Step("CreateInteractionChoiceSet with vrCommands duplicate", createInteractionChoiceSetDuplicateName)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
