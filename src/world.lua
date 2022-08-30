
local function depth_sorter(t, a, b)
  return t[b].depth < t[a].depth
end



World = Class:extend()


function World:new()
    self.instances = {}
end

function World:draw()
    for index, instance in spairs(self.instances, depth_sorter)  do

        instance:__draw()

    end
end

function World:update(dt)
    for index, instance in ipairs(self.instances) do
        instance:__step()
    end
    for index, instance in ipairs(self.instances) do
        instance:__handle_collision()
      end
end

function World:place(obj, x, y)
    local instance = obj()
    if x then
        instance.x = x
    end
    if y then
        instance.y = y
    end

    table.insert(self.instances, instance)
end

return World
