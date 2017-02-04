local inspect = require "inspect"
local rooms = require "rooms"
local tiles = require "tiles"
local tileSize = tiles.tileSize
local map = {}

function map:initializeVariables()
	self.nRooms = 0
	self.maxRooms = 10
	self.maxRandomRooms = 5
	self.failed = false
	self.pAttempts = 0
	self.pMaxAttempts = 8000
	self.minRoomSize = 6
	self.maxRoomSize = 12
	self.mWidth = 200
	self.mHeight = 100
	self.body = {}
	self.maxRandomDist = 50
	self.minRandomDist = 45
end

function map:initializeGrid()
	self.grid = {}
	for y = 1, self.mHeight do
		local temp = {}
		for x = 1, self.mWidth do
			temp[#temp+1] = tiles.empty
		end
		self.grid[#self.grid+1] = temp
	end
end

function map:initializeRoomsRandomly()
	self.pAttempts = 0
	self.nRooms = 0
	local max = math.random(1, self.maxRandomRooms)
	while not self.failed and self.nRooms < max do
		local x, y, w, h
		local place
		repeat
			w, h = self:getRandomDimensions()
			w = math.ceil(w*1.5)
			h = math.ceil(h*1.2)
			x, y = self:getRandomPosition()

			if self.pAttempts >= self.pMaxAttempts then
				self.failed = true
				return
			end
			if self:dist(x+w/2, y+h/2, self.body.x+self.body.w/2, self.body.y+self.body.h/2) < self.maxRandomDist and
			self:dist(x+w/2, y+h/2, self.body.x+self.body.w/2, self.body.y+self.body.h/2) > self.minRandomDist then
				place = self:checkArea(x, y, w, h, 2)
			else
				place = true
				self.pAttempts = self.pAttempts + 1
			end
		until place == false

		self:newArea(x, y, w, h, "random")
	end
end

function map:initializeRoomsAxisAligned()
	local x, y = math.ceil(self.mWidth / 2), math.ceil(self.mHeight / 2)
	self:newArea(x, y, self.maxRoomSize, self.minRoomSize, "aligned")

	local cx, cy = x, y
	local cDir
	local dir
	repeat
		local room = rooms.container.aligned[#rooms.container.aligned]
		local rx, ry, rw, rh = room.x, room.y, room.w, room.h
		local place
		dir = math.random(0,3)
		dir = dir % 6 
		-- North
		if dir == 0 then
			place = self:checkArea(rx, ry-rh-1, rw, rh, 0)
			if place == false then
				self:newArea(rx, ry-rh-1, rw, rh, "aligned")
			end
			y = ry - rh - 1
		end
		-- South
		if dir == 2 then
			place = self:checkArea(rx, ry+rh+1, rw, rh, 0)
			if place == false then
				self:newArea(rx, ry+rh+1, rw, rh, "aligned")
			end
			y = ry + rh + 1
		end
		-- East
		if dir == 1 then
			place = self:checkArea(rx+rw+1, ry, rw, rh, 0)
			if place == false then
				self:newArea(rx+rw+1, ry, rw, rh, "aligned")
			end
			x = rx + rw + 1
		end
		-- West
		if dir == 3 then
			place = self:checkArea(rx-rw-1, ry, rw, rh, 0)
			if place == false then
				self:newArea(rx-rw-1, ry, rw, rh, "aligned")
			end
			x = rx - rw - 1
		end

		cx, cy = x, y
	until self.nRooms >= self.maxRooms or self.pAttempts > self.pMaxAttempts
	print(self.pAttempts)
end

function map:newArea(x, y, w, h, roomType)
	for my = y, y + h do
		for mx = x, x + w do
			if my >= y + 1 and my <= y + h - 1 and 
			mx >= x + 1 and mx <= x + w - 1 then
				self.grid[my][mx] = tiles.rooms.floor
			else
				self:outlineArea(mx, my, x, y, w, h)
			end
		end
	end
	if roomType == "aligned" then
		rooms:newAlignedRoom(x, y, w, h)
	elseif roomType == "random" then
		rooms:newRandomRoom(x, y, w, h)
	end
	self.nRooms = self.nRooms + 1
end

function map:outlineArea(mx, my, x, y, w, h)
	-- Add vertical walls
	if mx == x or mx == x + w and my > y and my < y + h then
		self.grid[my][mx] = tiles.rooms.wall
	end
	-- Add horizontal walls
	if my == y or my == y + h and mx > x and mx < x + w then
		self.grid[my][mx] = tiles.rooms.wall
	end

	-- Add Top Left Corner
	if my == y and mx == x then
		self.grid[my][mx] = tiles.rooms.wall
	-- Add Top Right Corner
	end
	if my == y and mx == x + w then
		self.grid[my][mx] = tiles.rooms.wall
	end

	-- Add Bottom Left corner
	if my == y + h and mx == x then
		self.grid[my][mx] = tiles.rooms.wall
	-- Add Bottom Right corner
	end
	if my == y + h and mx == x + w then
		self.grid[my][mx] = tiles.rooms.wall
	end
end

function map:checkArea(x, y, w, h, offset)
	self.pAttempts = self.pAttempts + 1
	local minX, minY = x - offset, y - offset
	local maxX, maxY = x + w + offset, y + h + offset
	if minX > 0 and maxX < self.mWidth and minY > 0 and maxY < self.mHeight then
		for my = minY, maxY do
			for mx = minX, maxX do
				if self.grid[my][mx] == tiles.rooms.floor or self.grid[my][mx] == tiles.rooms.wall then
					return true
				end
			end
		end
		return false
	end
end

function map:destroyGrid()
	for i = #self.grid, 1, -1 do
		for j = #self.grid[i], 1, -1 do
			table.remove(self.grid[i], j)
		end
		table.remove(self.grid, i)
	end
end

function map:drawGrid()
	self:loopGrid(
		function(y)end,
		function(x, y)
			love.graphics.setColor(255,255,255)
			if self:getN(x, y) == tiles.rooms.floor then
				love.graphics.setColor(0,0,0)
			elseif self:getN(x, y) == tiles.rooms.wall then
				love.graphics.setColor(0,0,0)
			end
			love.graphics.rectangle("fill", x*tileSize, y*tileSize, tileSize, tileSize)
		end,
		function(y)end
	)

	love.graphics.setColor(185,0,185)
	love.graphics.rectangle("line", 0, 0, self.mWidth*tileSize, self.mHeight*tileSize)

	love.graphics.setColor(0,255,255)
	love.graphics.rectangle("line", self.body.x*tileSize, self.body.y*tileSize,
		self.body.w*tileSize, self.body.h*tileSize)
end

function map:loopGrid(preLoop, loop, postLoop)
	for y = 1, self.mHeight do
		preLoop(y)
		for x = 1, self.mWidth do
			loop(x, y)
		end
		postLoop(y)
	end
end

function map:setBody()
	local x1, y1 = self.mWidth, self.mHeight
	local x2, y2 = 0, 0
	for i = 1, #rooms.container.aligned do
		local room = rooms.container.aligned[i]
		x1 = math.min(x1, room.x)
		y1 = math.min(y1, room.y)
		x2 = math.max(x2, room.x + room.w + 1)
		y2 = math.max(y2, room.y + room.h + 1)
	end
	self.body.x = x1
	self.body.y = y1
	self.body.w = x2 - x1
	self.body.h = y2 - y1
end

function map:getN(x, y)
	if self.grid then	
		return self.grid[y][x]
	end
end

function map:getRandomDimensions()
	return math.random(self.minRoomSize, self.maxRoomSize),
		math.random(self.minRoomSize, self.maxRoomSize)
end

function map:getRandomPosition()
	return math.random(1, self.mWidth - self.maxRoomSize),
		math.random(1, self.mHeight - self.maxRoomSize)
end

function map:printGrid()
	for y = 1, self.mHeight do
		local line = ""
		for x = 1, self.mWidth do
			line = line .. tostring(self.grid[y][x]) .. " "
		end
		print(line)
	end
end

function map:dist(x1, y1, x2, y2)
	return math.sqrt((x2 - x1)^2 + (y2 - y1)^2)
end

return map