Class = require("libs.classic")
Object = require("src.object")
require("src.globals")
World = require("src.world")()
Screen = {}

function love.load()
    Screen.width, Screen.height = love.graphics.getDimensions()
    
end

function love.draw()
    Screen.width, Screen.height = love.graphics.getDimensions()
    World:draw()
end
function love.update()
    Screen.width, Screen.height = love.graphics.getDimensions()
    World:update()
    
end

require("game")