local test_object = Object:extend()

function test_object:create()
    self.solid = true
    self.direction = 270
    self.speed = 0
    self.bounce = 0
end

function test_object:draw()
    
    love.graphics.push()
	love.graphics.translate(self.x, self.y)
	love.graphics.rotate(math.rad(self.direction))
   
    rect("fill", self.x-self.width / 2, self.y-self.height / 2, self.width,self.height)
	
    love.graphics.pop()
end

function test_object:step()
    local down = love.keyboard.isDown
    if down("w") then
        self.speed = self.speed - 5
       
    elseif down("s") then
        self.speed = self.speed  +5
      
    elseif down("d") then
        self.direction = self.direction - 1
  
    elseif down("a") then
        self.direction = self.direction + 1
    end

    if self.speed > 10 then self.speed = 10 end
    if self.speed < -5 then self.speed = -5 end
    if self.direction < 0 then self.direction = 0 end
    if self.direction > 360 then self.direction = 360 end
end



local floor = Object:extend()

function floor:create() 
    self.width = 800
    self.height = 20
    self.solid = true
    
end

local wall = Object:extend()
function wall:create()
    self.width = 20
    self.height = 600
    self.solid = true
end


World:place(floor, 0, 0)
World:place(floor, 0 , 580)

World:place(wall, 0,0)
World:place(wall, 780,0)


World:place(test_object, 20, 20)

