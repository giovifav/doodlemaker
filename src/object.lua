Object = Class:extend()

function Object:new(id)
    self.name = id or nil
    self.id = uuid()
    self.solid = false
    self.visible = true
    self.persistent = true -- TODO
    self.depth = 0
    self.alarm = {}
    self.width = 100
    self.height = 100
    -- Built-in movements
    self.direction = 0
    self.friction = 0
    self.bounce = 0
    self.gravity = 0
    self.gravity_direction = 0
    self.hspeed = 0
    self.vspeed = 0
    self.speed = 0

    self.image_alpha = 1

    -- Axis movements
    self.x = 0
    self.y = 0
    self.xprevious = self.x
    self.yprevious = self.y
    self.xstart = self.x
    self.ystart = self.y
    -- Run create
    self:__create()
end

function Object:__create()
    if type(self.create) == 'function' then
        self:create()
    end
end

function Object:__step()
    local dt = love.timer.getDelta()

    for index, value in pairs(self.alarm) do
        if value >= 0 then
            self.alarm[index] = value - dt
        end

        if value < 0 and value ~= -1 then
            self.alarm[index] = -1

            if type(self['alarm' .. index]) then
                self['alarm' .. index](self)
            end
        end
    end
    if type(self.step) == 'function' then
        self:step(dt)
    end

    self:__apply_velocities()

    -- update x previous and y previous
    self.xprevious = self.x
    self.yprevious = self.y
end

function Object:__draw()
    -- Skip draw event
    if not self.visible then
        return nil
    end

    local r, g, b, a = love.graphics.getColor()

    if self.image_alpha < 1 then
        love.graphics.setColor(r, g, b, self.image_alpha)
    end

    if type(self.draw) == 'function' then
        local dt = love.timer.getDelta()
        self:draw(dt)
    else
        rect("fill", self.x, self.y, self.width, self.height)
    end

    love.graphics.setColor(r, g, b, a)
end

function Object:__check_collision(x1, y1, w1, h1, x2, y2, w2, h2)
    return x1 < x2 + w2 and
        x2 < x1 + w1 and
        y1 < y2 + h2 and
        y2 < y1 + h1
end

function Object:place_free(x, y)
    local collision = false

    for index, instance in ipairs(World.instances) do
        if instance.solid and instance.id ~= self.id then
            local has_collision = self:__check_collision(
                x, y, self.width, self.height,
                instance.x, instance.y, instance.width, instance.height
            )

            if has_collision then
                collision = true
            end
        end
    end

    return not collision
end

function Object:__apply_gravity()
    local radians = math.rad(self.gravity_direction)
    local vacceleration = self.gravity * math.sin(radians);
    local hacceleration = self.gravity * math.cos(radians);

    self.vspeed = self.vspeed - vacceleration
    self.hspeed = self.hspeed + hacceleration
end

function Object:__apply_speed()
    local radians = math.rad(self.direction)
    local vacceleration = self.speed * math.sin(radians);
    local hacceleration = self.speed * math.cos(radians);

    self.vspeed = self.vspeed - vacceleration
    self.hspeed = self.hspeed + hacceleration
end

function Object:__handle_collision()
    if  self.solid == true then
        for index, instance in ipairs(World.instances) do
            if instance.id == self.id then
                return
            end

            local separation_x, separation_y = self:__calculate_separators(instance)

            if separation_x and separation_y then
                self:__resolve_collision(instance, separation_x, separation_y)
            end
        end
    end
end

function Object:__calculate_separators(instance)
    -- Calculate enter x and center y
    local sxx = self.x + (self.width / 2)
    local ixx = instance.x + (instance.width / 2)
    local syy = self.y + (self.height / 2)
    local iyy = instance.y + (instance.height / 2)

    -- distance between the rects
    local distanceX = sxx - ixx
    local distanceY = syy - iyy

    local abs_distance_x = math.abs(distanceX)
    local abs_distance_y = math.abs(distanceY)

    -- sum of the extents
    local sum_half_width = (self.width + instance.width) / 2
    local sum_half_height = (self.height + instance.height) / 2

    if abs_distance_x >= sum_half_width or abs_distance_y >= sum_half_height then
        -- no collision
        return
    end

    -- shortest separation
    local separation_x = sum_half_width - abs_distance_x
    local separation_y = sum_half_height - abs_distance_y

    if separation_x < separation_y then
        if separation_x > 0 then
            separation_y = 0
        end
    else
        if separation_y > 0 then
            separation_x = 0
        end
    end

    -- correct sign
    if distanceX < 0 then
        separation_x = -separation_x
    end

    if distanceY < 0 then
        separation_y = -separation_y
    end

    return separation_x, separation_y
end

function Object:__resolve_collision(instance, separation_x, separation_y)
    -- find the collision normal
    local delta = math.sqrt(separation_x * separation_x + separation_y * separation_y)

    local normalX = separation_x / delta
    local normalY = separation_y / delta

    -- relative velocity
    local hspeed = self.hspeed - (instance.hspeed or 0)
    local vspeed = self.vspeed - (instance.vspeed or 0)

    -- penetration speed
    local penetration_speed = hspeed * normalX + vspeed * normalY

    -- penetration component
    local penetration_x = normalX * penetration_speed
    local penetration_y = normalY * penetration_speed

    -- tangent component
    local tangent_x = hspeed - penetration_x
    local tangent_y = vspeed - penetration_y

    -- restitution
    local restitution = 1 + math.max(self.bounce, instance.bounce or 0)

    -- friction
    local friction = math.min(self.friction, instance.friction or 0)

    -- change the velocity of shape a
    self.hspeed = hspeed - penetration_x * restitution + tangent_x * friction
    self.vspeed = vspeed - penetration_y * restitution + tangent_y * friction

    if penetration_speed <= 0 then
        self.x = self.x + separation_x
        self.y = self.y + separation_y
    end
end

function Object:__apply_velocities()
    local dt = love.timer.getDelta()

    -- Apply forces that modify vspeed/hspeed
    self:__apply_gravity()
    self:__apply_speed()

    self.x = self.x + self.hspeed * dt
    self.y = self.y + self.vspeed * dt
end

return Object
