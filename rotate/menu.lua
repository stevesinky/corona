-----------------------------------------------------------------------------------------
--
-- menu.lua
--
-----------------------------------------------------------------------------------------

-- allow this lua file to be used with storyboards
local storyboard = require "storyboard"
local scene = storyboard.newScene()
local utility = require ("utility")
local math = require ("math")

local background
local playText

-- what to do when the screen loads
function scene:createScene(event)
	local screenGroup = self.view
	background = display.newImageRect("background.png", 1080, 1920)
	utility.putInCentre(background)  

	local title = utility.addBlackCentredTextWithFont("ROTATE",-190,screenGroup,100,"Exo-DemiBoldItalic")
	utility.setColour(title, 175, 0, 175)

	playText = utility.addCentredText("PLAY", 0,screenGroup,50,"Exo-DemiBoldItalic")	
	utility.setColour(playText, 175, 0, 175)

	transition.to ( title,{ time= 200, x = (title.x),y = (title.y + 200) } ) 
	transition.to ( playText,{ time= 400, x = (playText.x),y = (playText.y - 400) } ) 

end

local function playGame()
	storyboard.gotoScene("game")
end

-- add all the event listening
function scene:enterScene(event)
	storyboard.purgeScene("game")
	playText:addEventListener( "tap", playGame )
end

function scene:exitScene(event)
	playText:removeEventListener( "tap", playGame )
end

function scene:destroyScene(event)
end

scene:addEventListener("createScene", scene)
scene:addEventListener("enterScene", scene)
scene:addEventListener("exitScene", scene)
scene:addEventListener("destroyScene", scene)

return scene
