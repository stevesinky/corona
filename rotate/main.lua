
-- constants
W = display.contentWidth
H = display.contentHeight
Cx = W * 0.5
Cy = H * 0.5
scaler = 0.45
radius = 64

local physics = require("physics")
physics.start()
physics.setGravity( 0, 0 )
--physics.setDrawMode( "hybrid" )

display.setStatusBar( display.HiddenStatusBar )
display.setDefault( "background", 1, 1, 1 )

-- setup variables across game
local start = true
local level = 1
local dof = 8
local numberToScore = 3
local targetLeft = 0 --used for when a ball becomes central mid turn, can then inherit this tagert

-- Set up score displays
local scoreTotal = 0
score = display.newText( scoreTotal, 0, 0, native.systemFontBold, 28 )
score:setTextColor( 40, 40, 40, 0 )
score.x = 20; score.y = 20

local function updateScores()
	score.text = scoreTotal
end

freeBalls = {}
centreBalls = {}
local ballBody = { density=2.0, friction=10.0, bounce=0.1, radius=radius * scaler }
local ballColours = { "black", "blue", "red", "green", "gold", "black", "blue", "red", "green" }

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
	return ball
end

function newFreeBall()
	freeNo = #freeBalls + 1
	if (freeNo > 9) then
		freeNo = math.random( 8 )
	end
	local freeBall = newBall( freeNo )
	freeBall.x = math.random(Cx * 0.75, Cy * 1.25)
	freeBall.y = 0
	physics.addBody( freeBall, ballBody )
	freeBall:applyLinearImpulse( 0, 25.0, freeBall.x, freeBall.y )
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
	local overSplash = display.newImage( "game_over.png", true )
	local showGameOver = transition.to( overSplash, { alpha=1.0, xScale=1.0, yScale=1.0, time=500 } )
end

function isGameOver()
	-- check all obeject in centre group
    return false
end

function cleanUpBalls()
end

function ballIsTouchingAndSameColour(ball1, ball2)
	if (centreBalls[i] ~=  ballToAdd) then
		local dx = math.abs(ball1.x - ball2.x)
		local dy = math.abs(ball1.y - ball2.y)
		local dr = math.sqrt( (dx ^ 2) + (dy ^ 2) )
		if (dr <= radius * 2 * scaler) then
			if (ball1.colour == ball2.colour) then
				return true
			end
		end
	end
	return false
end

function elementNotInTable(element, table)
	for i=1, #table do
		if (table[i] == element) then
			return false
		end
	end
	return true
end

function ballArrayToRemove(ballsToRemove, ballsToSearch)
	local ballsToRemoveOutOfLoop = {}
	print("ballsToRemove: " .. #ballsToRemove )
	print("ballsToSearch: " .. #ballsToRemove )
	for i=1, #ballsToRemove do
		ballsToRemoveOutOfLoop[#ballsToRemoveOutOfLoop + 1] = ballsToRemove[i]
		for j=1, #ballsToSearch do
			if (elementNotInTable(ballsToSearch[j], ballsToRemoveOutOfLoop)) then
				if (ballIsTouchingAndSameColour(ballsToSearch[j],ballsToRemove[i])) then
					ballsToRemoveOutOfLoop[#ballsToRemoveOutOfLoop + 1] = ballsToSearch[j]
					local removalArray = ballArrayToRemove(ballsToRemoveOutOfLoop, ballsToSearch)
					for k=1, #removalArray do
						ballsToRemoveOutOfLoop[#ballsToRemoveOutOfLoop + 1] = removalArray[k]
					end
				end
			end
		end
	end
	print("ballsToRemoveOutOfLoop: " .. #ballsToRemoveOutOfLoop )
	return ballsToRemoveOutOfLoop
end

function ballToRemove(ballsToRemove)
	-- get all the balls to remove from the recursive search
	local ballsToRemove = ballArrayToRemove(ballsToRemove, centreBalls)
	for i=1, #ballsToRemove do
		-- remove the object
		--ballsToRemove[i]:removeSelf()
		display.remove( ballsToRemove[i] )
		ballsToRemove[i] = nil
		physics.removeBody( ballsToRemove )	
	end
	-- remove from centreballs
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
		
	for i=1, #centreBalls do
		centreBalls[i]:setLinearVelocity(0, 0)
		local move = centreBalls[i].currentAngle + ((tDelta * 0.004 * oneAngle))
		if (move > centreBalls[i].targetAngle) then
			move = centreBalls[i].targetAngle
		end
	
		local xV = Cx - centreBalls[i].x
		local yV = Cy - centreBalls[i].y
		local radiusFromCentre =  math.sqrt( (xV ^ 2) + (yV ^ 2) )
		centreBalls[i].x = (Cx)  + math.cos(math.rad(move)) * radiusFromCentre 
		centreBalls[i].y = (Cy)  + math.sin(math.rad(move)) * radiusFromCentre
		centreBalls[i].rotation = move
		centreBalls[i].currentAngle = move
		centreBalls[i]:setLinearVelocity( xV * 0.05 ,  yV * 0.05 ) -- bit of force to centre
		targetLeft = centreBalls[i].targetAngle - centreBalls[i].currentAngle
    end

	-- only do this periodically as intensive
	if ( event.time - tComplexPrevious > (100) ) then
		tComplexPrevious = event.time

		for i=1, #centreBalls do
			local xV = Cx - centreBalls[i].x
			local yV = Cy - centreBalls[i].y
			local distanceSq = xV + yV 
			local force = 10 / distanceSq
		end

		if ( event.time - tLastNewBall > (2000 + (1000 * level)) ) then
			tLastNewBall = event.time
			--new ball please
			newFreeBall()
			-- cleanup freeballs that are off screen
			cleanUpBalls()
		end

		-- check game over
		if (isGameOver()) then
			gameOver()
		end
	end
end


local function addToCenter( ballToAdd )
	setBallCurrentAngle( ballToAdd )
	ballToAdd.targetAngle = ballToAdd.currentAngle + targetLeft
	centreBalls[#centreBalls + 1] = ballToAdd
	ballsToAdd = {ballsToAdd}
	timer.performWithDelay(1, ballToRemove(ballsToAdd), 1)
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
		timer.performWithDelay(1, addToCenter(object1), 1)
	end
		
	if (found2 == false) then
		timer.performWithDelay(1, addToCenter(object2), 1)
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

-- animate frames
Runtime:addEventListener( "enterFrame", animate )
-- set rotation on centre blocks
Runtime:addEventListener( "touch", startRotation )

Runtime:addEventListener( "collision", onCollision )