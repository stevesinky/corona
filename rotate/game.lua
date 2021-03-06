-----------------------------------------------------------------------------------------
--
-- game.lua
--
-----------------------------------------------------------------------------------------

-- allow this lua file to be used with storyboards
local storyboard = require "storyboard"
local scene = storyboard.newScene()
local utility = require ("utility")

local physics = require("physics")
physics.start()
physics.setGravity( 0, 0 )
--physics.setDrawMode( "hybrid" )

-- constants though all levels
local W = display.contentWidth
local H = display.contentHeight
local Cx = W * 0.5
local Cy = H * 0.5
local radius = 64 -- constant on image
local level = 1
local lowAlpha = 0.01
local scoreTotal = 0
local ballColours = { "blue", "red", "green", "gold", "blue", "gold", "red", "black", "green" }

-- variables
local background
local start
local targetLeft
local dof
local held
local numberToScore
local score
local tPrevious
local tComplexPrevious
local tLastNewBall
local freeBalls
local centreBalls
local isGameOver
local timerBar
local timerBarText
local levelTime

local function getAngle( ball )
	local arcx = ball.x - Cx
	local arcy = ball.y - Cy
	angle = math.atan2(arcy, arcx )
	return math.deg( angle )
end

local function setBallCurrentAngle( ball )
	local angleToDeg = getAngle( ball )
	ball.currentAngle = angleToDeg  
	ball.targetAngle = angleToDeg
end

local function newBall( i, scaler )
	local ball = display.newImage( "ball_" .. ballColours[i] .. "_f.png" )
	ball:scale( scaler, scaler )
	ball.id = "ball" -- store object type as string attribute
	ball.colour = ballColours[i] -- store ball colour as string attribute
	ball.alpha = 1
	ball.actualRadius = radius * scaler
	return ball
end

local function newFreeBall()
	freeNo = #freeBalls + 1
	if (freeNo > 9) then
		freeNo = math.random( 8 )
	end
	local scale = 0.55
	if (math.fmod(freeNo, 3) == 0 ) then
		scale = math.random(5, 6) * 0.11
	end

	local freeBall = newBall( freeNo, scale )
	freeBall.x = math.random(Cx * 0.75, Cx * 1.25)
	freeBall.y = -8
	local ballBody = { density=2.0, friction=1.0, bounce=0.1, radius=freeBall.actualRadius }
	physics.addBody( freeBall, ballBody )
	freeBall:applyLinearImpulse( 0, (60.0 * scale), freeBall.x, freeBall.y )
	freeBalls[freeNo] = freeBall	
end

-- what to do when the screen loads
function scene:createScene(event)
	screenGroup = self.view

	background = display.newImageRect("background.png", 1080, 1920)
	utility.putInCentre(background)

	score = display.newText( scoreTotal, 40, -120, native.systemFontBold, 32 )
	utility.setColour(score, 0, 0, 0)

	timerBar = display.newRect( W / 2, H + 120, W - 64, 32 )
	utility.setColour(timerBar, 175, 0, 175)

	timerBarText = display.newText( "TIME", W / 2, H + 120, native.systemFontBold, 32 )
	utility.setColour(timerBarText, 0, 0, 0)

	start = true
	targetLeft = 0 --used for when a ball becomes central mid turn, can then inherit this tagert
	level = level + 1
	dof = 5
	numberToScore = 3
	levelTime = 40000

	tPrevious = system.getTimer()
	tComplexPrevious = system.getTimer()
	tLastNewBall = system.getTimer()

	freeBalls = {}
	centreBalls = {}

	isGameOver = false

	-- Arrange stating balls at centre
	local startCentreSize = 4
	for i = 1, startCentreSize do
		centreBalls[i] = newBall( i, 0.5 )
		centreBalls[i].x = Cx + (centreBalls[i].width * centreBalls[i].xScale * i) - centreBalls[i].width * centreBalls[i].xScale * 2.5
		centreBalls[i].y = Cy 
		setBallCurrentAngle(centreBalls[i])
		local ballBody = { density=2.0, friction=10.0, bounce=0.1, radius=centreBalls[i].actualRadius }
		physics.addBody( centreBalls[i], ballBody )
	end
end

local function gameOver()
	start = false
	local gameOver = display.newImage( "game_over.png", false )
	utility.putInCentre(gameOver)
end

local function isBallOffScreen(ball)
	local buffer = radius * 4
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

local function isGameOver()
	-- check all obeject in centre group
	if (timerBar.width < 2) then
		return true
	end
	return false
end

local function removeBall(ball)
	ball:removeSelf()
    ball = nil
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


local function ballsAreTheSame(ball1, ball2)
	if (ball1.colour == ball2.colour) then
		if (ball1.x == ball2.x) then
			if (ball1.y == ball2.y) then
				return true
			end
		end
	end
	return false
end

local function fadeBalls(balls)
	--print("attempting to remove " .. #balls .. " balls")
	for i = 1, #balls do
		transition.to(balls[i], {time=300, alpha=lowAlpha})
	end
end

local function ballIsTouchingAndSameColour(ball1, ball2)
	if (ball1.colour == ball2.colour) then
		if (ball1.colour == "black") then
			return false;
		end

		--print("balls are same colour:" .. ball1.colour)
		local dx = math.abs(ball1.x - ball2.x)
		local dy = math.abs(ball1.y - ball2.y)
		local tolerance = ball1.actualRadius + ball2.actualRadius 
		--print("dx="..dx.." dy="..dy.." tol="..tolerance)
		if (dx <= tolerance) then
			if (dy <= tolerance) then
				--print("balls are next to each other")
				return true
			end
		end
	end
	return false
end

local function isNewRemoval( ball, alreadyTouchingAndThisColour )
	for i=1, #alreadyTouchingAndThisColour do
		if (ballsAreTheSame(ball, alreadyTouchingAndThisColour[i])) then
			return false
		end
	end
	for i=1, #alreadyTouchingAndThisColour do
		if (ballIsTouchingAndSameColour(ball, alreadyTouchingAndThisColour[i])) then
			return true
		end
	end
	return false	
end

local function searchCentreForNew( alreadyTouchingAndThisColour )
	--print ("searchCentreForNew with arraySize: " .. #alreadyTouchingAndThisColour .. " centreSize: ".. #centreBalls)
	for i=1, #centreBalls do
		if (isNewRemoval(centreBalls[i], alreadyTouchingAndThisColour)) then
			alreadyTouchingAndThisColour[#alreadyTouchingAndThisColour + 1] = centreBalls[i]
			alreadyTouchingAndThisColour = searchCentreForNew( alreadyTouchingAndThisColour )		
		end	
	end
	return alreadyTouchingAndThisColour
end

local function startSearch( ball1, ball2 )
	local touchingAndThisColour = {}
	touchingAndThisColour[1] = ball1
	touchingAndThisColour[2] = ball2
	local ballsToRemove = searchCentreForNew(touchingAndThisColour)
	if (#ballsToRemove >= numberToScore) then
		timer.performWithDelay(1, fadeBalls(ballsToRemove), 1)	
	end	
end

local function addToCenter( ballToAdd )
	setBallCurrentAngle( ballToAdd )
	ballToAdd.targetAngle = ballToAdd.currentAngle + targetLeft
	centreBalls[#centreBalls + 1] = ballToAdd
	ballsToAdd = {ballsToAdd}
end

local function joinBalls( object1, object2 )
	
	-- insert into the centre group, as all joins balls with be there
	local oldCount = #centreBalls
	local found1 = false
	local found2 = false
	for i=1, oldCount do
		if (centreBalls[i] == object1) then
			found1 = true
		end
		if (centreBalls[i] == object2) then
			found2 = true
		end
	end
	if (found1 == false) then
		addToCenter(object1)
	end
		
	if (found2 == false) then
		addToCenter(object2)
	end
	if (object1.colour == object2.colour) then
		--print( "two balls just touched with the colour: " .. object1.colour)
		timer.performWithDelay(1, startSearch(object1, object2), 1)
	end
end

local function onCollision( event )
	--loose speed
	event.object1:setLinearVelocity(0, 0)
	event.object2:setLinearVelocity(0, 0)
    timer.performWithDelay(1, joinBalls(event.object1, event.object2), 1)
end


local function myTapListener( event )
	if (start == true) then
		start = false
		for i=1, #centreBalls do
			setBallCurrentAngle( centreBalls[i] )	
		end
	else
		for i=1, #centreBalls do
			local target = centreBalls[i].currentAngle + (360 / dof)
			centreBalls[i].targetAngle = target
		end
	end
end

local function myTouchListener( event )

	myTapListener( event )

    if ( event.phase == "began" ) then
        --code executed when the button is touched
        held = true
    elseif ( event.phase == "ended" ) then
        --code executed when the touch lifts off the object
        held = false
    end
    return true  --prevents touch propagation to underlying objects
end

local function updateTimer( elapsedTime )
	local timeRatio = levelTime / elapsedTime
	local scaleX = W / timeRatio
	timerBar.width = timerBar.width - scaleX
end

local function animate( event )

	local tDelta = event.time - tPrevious
	tPrevious = event.time

	updateTimer(tDelta)

	if (isGameOver == true) then
		return true
	end

	if (start == true) then
		-- wait until start splash screen is done
		tPrevious = event.time
		tComplexPrevious = event.time
		return true
	end

	if (held == true) then
		myTapListener(event)
	end

	local oneAngle = 360 / dof
	local fadeRate = 1 - (tDelta * 0.5)
	local updateCentreBalls = false
	local removalBalls = {}
	local newCentreBalls = {}
   
	for i=1, #centreBalls do
		if (centreBalls[i].alpha > lowAlpha) then
			centreBalls[i]:setLinearVelocity(0, 0)
			local distanceFromTarget = centreBalls[i].targetAngle - centreBalls[i].currentAngle
			if (distanceFromTarget < 3) then
				distanceFromTarget = 2
			end
			local dampingFactorFromTarget = distanceFromTarget / oneAngle
			local move = centreBalls[i].currentAngle + (tDelta * 0.0025 * oneAngle * dampingFactorFromTarget)
	
			local xV = Cx - centreBalls[i].x
			local yV = Cy - centreBalls[i].y
			local radiusFromCentre =  math.sqrt( (xV ^ 2) + (yV ^ 2) )
			centreBalls[i].x = (Cx)  + math.cos(math.rad(move)) * radiusFromCentre 
			centreBalls[i].y = (Cy)  + math.sin(math.rad(move)) * radiusFromCentre
			centreBalls[i].rotation = move
			centreBalls[i].currentAngle = move
			centreBalls[i]:setLinearVelocity( xV * 0.05 ,  yV * 0.05 ) -- bit of force to centre
			targetLeft = centreBalls[i].targetAngle - centreBalls[i].currentAngle

			newCentreBalls[#newCentreBalls+1] = centreBalls[i]
		else
			--needs removing
			removalBalls[#removalBalls+1] = centreBalls[i]
			updateCentreBalls = true
		end
    end

    if (updateCentreBalls) then
    	print( "updatingCentreBalls old=" .. #centreBalls .. " new=" .. #newCentreBalls .. "due to remove=" .. #removalBalls)
    	centreBalls = newCentreBalls
    	scoreTotal = scoreTotal + #removalBalls
    	score.text = scoreTotal
    	timerBar.width = timerBar.width + (W * 0.1 * #removalBalls)    	   
    	for i=1, #removalBalls do
    		removeBall(removalBalls[i])
    	end
    end

	-- only do this periodically as intensive
	if ( event.time - tComplexPrevious > (100) ) then
		-- check game over
		if (isGameOver()) then
			print( "GAME OVER!" )
			isGameOver = true
			gameOver()
		end


		if ( event.time - tLastNewBall > (2000) ) then
			tLastNewBall = event.time
			--new ball please
			newFreeBall()
			-- cleanup freeballs that are off screen
			--cleanUpBalls() doesn't work
		end
	end
end

-- add all the event listening
function scene:enterScene(event)
	print("enter game")
	Runtime:addEventListener( "enterFrame", animate )
	Runtime:addEventListener( "tap", myTapListener )
	Runtime:addEventListener( "touch", myTouchListener )
	Runtime:addEventListener( "collision", onCollision )
	storyboard.purgeScene("menu")	
end

function scene:exitScene(event)
	Runtime:removeEventListener( "enterFrame", animate )
	Runtime:removeEventListener( "tap", myTapListener )
	Runtime:removeEventListener( "touch", myTapListener )
	Runtime:removeEventListener( "collision", onCollision )
end

function scene:destroyScene(event)
end

scene:addEventListener("createScene", scene)
scene:addEventListener("enterScene", scene)
scene:addEventListener("exitScene", scene)
scene:addEventListener("destroyScene", scene)

return scene