local utility = require ("utility")

-- constants
W = display.contentWidth
H = display.contentHeight
Cx = W * 0.5
Cy = H * 0.5
scaler = 0.5
radius = 64

local physics = require("physics")
physics.start()
physics.setGravity( 0, 0 )
--physics.setDrawMode( "hybrid" )

display.setStatusBar( display.HiddenStatusBar )
local background = display.newImageRect("background.png", 1080, 1920)
utility.putInCentre(background)

-- setup variables across game
local start = true
local level = 1
local dof = 4
local numberToScore = 3
local targetLeft = 0 --used for when a ball becomes central mid turn, can then inherit this tagert

-- Set up score displays
local scoreTotal = 0
score = display.newText( scoreTotal, 0, 0, native.systemFontBold, 28 )
score:setTextColor( 40, 40, 40, 0 )
score.x = 20; score.y = 20

local lowAlpha = 0.05

local function updateScores()
	score.text = scoreTotal
end

freeBalls = {}
centreBalls = {}
local ballBody = { density=2.0, friction=10.0, bounce=0.1, radius=radius * scaler }
local ballColours = { "black", "blue", "red", "green", "gold", "blue", "gold", "red", "green" }

function getAngle( ball )
	local arcx = ball.x - Cx
	local arcy = ball.y - Cy
	angle = math.atan2(arcy, arcx )
	return math.deg( angle )
end

function setBallCurrentAngle( ball )
	local angleToDeg = getAngle( ball )
	ball.currentAngle = angleToDeg  
	ball.targetAngle = angleToDeg
end

function newBall( i )
	local ball = display.newImage( "ball_" .. ballColours[i] .. ".png" )
	ball:scale( scaler, scaler )
	ball.id = "ball" -- store object type as string attribute
	ball.colour = ballColours[i] -- store ball colour as string attribute
	ball.alpha = 1
	ball.remove = 0 
	return ball
end

function newFreeBall()
	freeNo = #freeBalls + 1
	if (freeNo > 9) then
		freeNo = math.random( 8 )
	end
	local freeBall = newBall( freeNo )
	freeBall.x = math.random(Cx * 0.75, Cy * 1.25)
	freeBall.y = -8
	physics.addBody( freeBall, ballBody )
	freeBall:applyLinearImpulse( 0, 35.0, freeBall.x, freeBall.y )
	freeBalls[freeNo] = freeBall	
end

-- Arrange stating balls at centre
local startCentreSize = 4
for i = 1, startCentreSize do
	centreBalls[i] = newBall( i )
	centreBalls[i].x = Cx + (centreBalls[i].width * centreBalls[i].xScale * i) - centreBalls[i].width * centreBalls[i].xScale * 2.5
	centreBalls[i].y = Cy 
	setBallCurrentAngle(centreBalls[i])
	physics.addBody( centreBalls[i], ballBody )
	if (i > 1) then
	--newJoint(centreBalls[i-1], centreBalls[i])
	end		
end

function gameOver()
	start = false
	local gameOver = display.newImage( "game_over.png", false )
	utility.putInCentre(gameOver)
end

function isGameOver()
	-- check all obeject in centre group
	for i = 1, #centreBalls do
		if (centreBalls[i].x < 0) then
			return true
		end
		if (centreBalls[i].x > W) then
			return true
		end
		if (centreBalls[i].y < 0) then
			return true
		end
		if (centreBalls[i].y > H) then
			return true
		end
	end
    return false
end

function cleanUpBalls()
	--if way off screen, remove image/physics
end


function ballsAreTheSame(ball1, ball2)
	if (ball1.colour == ball2.colour) then
		if (ball1.x == ball2.x) then
			if (ball1.y == ball2.y) then
				return true
			end
		end
	end
	return false
end

function removeBalls(balls)
	--print("attempting to remove " .. #balls .. " balls")
	for i = 1, #balls do
		transition.to(balls[i], {time=300, alpha=lowAlpha})
	end
end

local function ballIsTouchingAndSameColour(ball1, ball2)
	if (ball1.colour == ball2.colour) then
		--print("balls are same colour:" .. ball1.colour)
		local dx = math.abs(ball1.x - ball2.x)
		local dy = math.abs(ball1.y - ball2.y)
		local tolerance = (radius * 2 * scaler)
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
		timer.performWithDelay(1, removeBalls(ballsToRemove), 1)	
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


function startRotation( event )
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

local tPrevious = system.getTimer()
local tComplexPrevious = system.getTimer()
local tLastNewBall = system.getTimer()

function animate( event )

	local tDelta = event.time - tPrevious
	tPrevious = event.time

	if (start) then
		-- wait until start splash screen is done
		tPrevious = event.time
		tComplexPrevious = event.time
		return true
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

    	for i=1, #removalBalls do
    		removalBalls[i]:removeSelf()
    		removalBalls[i] = nil
    	end
    end

	-- only do this periodically as intensive
	if ( event.time - tComplexPrevious > (100) ) then
		-- check game over
		if (isGameOver()) then
			print( "GAME OVER!" )
			gameOver()
		end


		if ( event.time - tLastNewBall > (2000) ) then
			tLastNewBall = event.time
			--new ball please
			newFreeBall()
			-- cleanup freeballs that are off screen
			cleanUpBalls()
		end
	end
end

-- animate frames
Runtime:addEventListener( "enterFrame", animate )
-- set rotation on centre blocks
Runtime:addEventListener( "touch", startRotation )

Runtime:addEventListener( "collision", onCollision )