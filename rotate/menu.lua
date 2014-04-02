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

local physics = require("physics")
physics.start()
physics.setGravity( 0, 0 )

local background
local playText

local W = display.contentWidth
local H = display.contentHeight
local Cx = W * 0.5
local Cy = H * 0.5
local radius = 64 -- constant on image
local ballColours = { "black", "blue", "red", "green", "gold", "blue", "gold", "red", "green" }
local freeBalls = {}
local tPrevious

-- what to do when the screen loads
function scene:createScene(event)
	local screenGroup = self.view
	background = display.newImageRect("background.png", 1080, 1920)
	utility.putInCentre(background)  

	local title = display.newText("SillyBalls!", 0, 0, "Helvetica", 104) 
	utility.centreObjectX(title)
	title.anchorY = 0
	title:translate(0, 120)
	title:setFillColor( 0, 0, 0 )
	
	playText = display.newText("PLAY GAME", 0, 0, "Helvetica", 98) 
	utility.centreObjectX(playText)
	playText.anchorY = 0
	playText:translate(0, 480)
	utility.setColour(playText, 175, 0, 175)

	tPrevious = system.getTimer() 
end

local function newBall( i, scaler )
	local ball = display.newImage( "ball_" .. ballColours[i] .. "_f.png" )
	ball:scale( scaler, scaler )
	ball.id = "ball" -- store object type as string attribute
	ball.colour = ballColours[i] -- store ball colour as string attribute
	ball.alpha = 0.3
	ball.actualRadius = radius * scaler
	return ball
end

local function newFreeBall()
	freeNo = #freeBalls + 1
	if (freeNo > 9) then
		freeNo = math.random( 8 )
	end
	local scale = math.random(3, 7) * 0.1
	local freeBall = newBall( freeNo, scale )
	freeBall.x = math.random(Cx * 0.4, Cx * 1.6)
	freeBall.y = -18
	local ballBody = { density=2.0, friction=10.0, bounce=0.1, radius=freeBall.actualRadius }
	physics.addBody( freeBall, ballBody )
	freeBall:applyLinearImpulse( math.random(-3,3), (55.0 * scale ), freeBall.x, freeBall.y )
	freeBalls[freeNo] = freeBall	
end

local function removeBall(ball)
	ball:removeSelf()
    ball = nil
end

local function isBallOffScreen(ball)
	local buffer = ball.actualRadius
	if (ball.x < (0 - buffer)) then
		return true
	end
	if (ball.x > (W + buffer)) then
		return true
	end
	if (ball.y < (0 - buffer)) then
		return true
	end
	if (ball.y > (H + buffer)) then
		return true
	end
end

local function cleanUpBalls()
	--if way off screen, remove image/physics
	-- check all obeject in centre group
	for i = 1, #freeBalls do
		if (isBallOffScreen(freeBalls[i])) then
			removeBall(freeBalls[i])
		end
	end
end

local function playGame()
	storyboard.gotoScene("game")
end

local function animate(event)
	local tDelta = event.time - tPrevious
	
	if (tDelta > 1500) then
		tPrevious = event.time
		newFreeBall()
		timer.performWithDelay(1, cleanUpBalls(), 1)
	end
end

-- add all the event listening
function scene:enterScene(event)
	storyboard.purgeScene("game")
	playText:addEventListener( "tap", playGame )
	playText:addEventListener( "touch", playGame )
	Runtime:addEventListener( "enterFrame", animate )
end

function scene:exitScene(event)
	playText:removeEventListener( "tap", playGame )
	playText:removeEventListener( "touch", playGame )
	Runtime:removeEventListener( "enterFrame", animate )
	for i = 1, #freeBalls do
		removeBall(freeBalls[i])
	end
end

function scene:destroyScene(event)
end

scene:addEventListener("createScene", scene)
scene:addEventListener("enterScene", scene)
scene:addEventListener("exitScene", scene)
scene:addEventListener("destroyScene", scene)

return scene
