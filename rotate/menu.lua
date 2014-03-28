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

local W = display.contentWidth
local H = display.contentHeight
local Cx = W * 0.5
local Cy = H * 0.5
local scaler = 0.5
local radius = 64
local actualRadius = radius * scaler
local ballBody = { density=2.0, friction=10.0, bounce=0.1, radius=actualRadius }
local ballColours = { "black", "blue", "red", "green", "gold", "blue", "gold", "red", "green" }
local freeBalls
local tPrevious

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

	freeBalls = {}
	tPrevious = system.getTimer() 
end

local function newBall( i )
	local ball = display.newImage( "ball_" .. ballColours[i] .. ".png" )
	ball:scale( scaler, scaler )
	ball.id = "ball" -- store object type as string attribute
	ball.colour = ballColours[i] -- store ball colour as string attribute
	ball.alpha = 1
	return ball
end

local function newFreeBall()
	freeNo = #freeBalls + 1
	if (freeNo > 9) then
		freeNo = math.random( 8 )
	end
	local freeBall = newBall( freeNo )
	freeBall.x = math.random(Cx * 0.8, Cx * 1.2)
	freeBall.y = -8
	physics.addBody( freeBall, ballBody )
	freeBall:applyLinearImpulse( 0, 35.0, freeBall.x, freeBall.y )
	freeBalls[freeNo] = freeBall	
end

local function removeBall(ball)
	ball:removeSelf()
    ball = nil
end

local function isBallOffScreen(ball)
	local buffer = actualRadius
	if (ball.x < (0 - buffer)) then
		return true
	end
	if (ball.x > (W + buffer) then
		return true
	end
	if (ball.y < (0 - buffer)) then
		return true
	end
	if (ball.y > (H + buffer) then
		return true
	end
end

local function cleanUpBalls()
	--if way off screen, remove image/physics
	-- check all obeject in centre group
	for i = 1, #freeballs do
		if (isBallOffScreen(freeballs[i])) then
			removeBall(freeballs[i])
		end
	end
end

local function playGame()
	storyboard.gotoScene("game")
end

local function animate()
	local tDelta = event.time - tPrevious
	
	if (tDelta > 500) then
		tPrevious = event.time
		cleanUpBalls()
	end
end

-- add all the event listening
function scene:enterScene(event)
	storyboard.purgeScene("game")
	playText:addEventListener( "tap", playGame )
	Runtime:addEventListener( "enterFrame", animate )
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
