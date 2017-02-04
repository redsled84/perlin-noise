local rooms = {}

function rooms:initializeVariables()
	self.container = {
		aligned = {},
		random = {}
	}
end

function rooms:newAlignedRoom(x, y, w, h)
	table.insert(self.container.aligned, {
		x = x, y = y, w = w, h = h
	})
end

function rooms:newRandomRoom(x, y, w, h)
	table.insert(self.container.random, {
		x = x, y = y, w = w, h = h
	})
end

function rooms:getCenter(room)
	return room.x + room.w / 2, room.y + room.h / 2
end

function rooms:destroyContainer()
	for i = #self.container, 1, -1 do
		for j = #self.container[i], 1, -1 do
			table.remove(self.container[i], j)
		end
	end
end

return rooms