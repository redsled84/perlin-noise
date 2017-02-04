math.randomseed(os.time())
local camera = require "camera"
local cam = camera.new()
local map = require "map"
local rooms = require "rooms"
local tiles = require "tiles"
local tileSize = tiles.tileSize

local body
function love.load()
	rooms:initializeVariables()
	map:initializeVariables()
	map:initializeGrid()
	map:initializeRoomsAxisAligned()
	map:setBody()
	map:initializeRoomsRandomly()
end

local timer = 0
local timerMax = .5
function love.update(dt)
	cam:lookAt(map.mWidth * tileSize / 2, map.mHeight * tileSize / 2)
	--[[
	timer = timer + dt
	if timer > timerMax then
		rooms:destroyContainer()
		map:destroyGrid()
		map:initializeVariables()
		map:initializeGrid()
		map:initializeRoomsAxisAligned()
		map:initializeRoomsRandomly()
		timer = 0
	end
	]]
end

function love.draw()
	cam:attach()
	map:drawGrid()
	cam:detach()
end

function love.keypressed(key)
	if key == "r" then
		love.event.quit("restart")
	elseif key == "escape" then
		love.event.quit()
	end
end