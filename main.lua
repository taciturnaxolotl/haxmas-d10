local player = {
    x = 80,
    y = 0,
    width = 1,
    height = 1,
    velocityY = 0,
    isJumping = false,
    isSliding = false,
    wantsToSlide = false,
    slideTimer = 0,
    maxSlideTime = 3,
    hitboxPadding = 9,
    animationFrame = 0,
    animationTimer = 0,
    normalHeight = 1,
    slideHeight = 1
}

local ground = { y = 0, height = 40 }
local obstacles = {}
local spawnTimer = 0
local spawnInterval = 1.5
local gameSpeed = 300
local score = 0
local highScore = 0
local gameOver = false
local gravity = 1200
local jumpForce = -500
local showHitboxes = false

local sprite = require "sprite"

local images = {}
local dinoScale = 1
local dinoRunningScale = 1
local pterodactylScale = 1
local pterodactylAnimationTimer = 0
local pterodactylAnimationFrame = 0

function love.load()
    love.window.setTitle("Haxmas Runner :3")
    love.graphics.setDefaultFilter("nearest", "nearest")
    
    images.dinoSheet = love.graphics.newImage("assets/dino-sheet.png")
    
    local targetHeight = 80
    
    -- Sprite sheet frames: 0-1 running, 2-3 sliding, 4 jumping, 5 cactus, 6-7 pterodactyl
    -- Each frame is 22 wide x 20 tall
    dinoRunningScale = targetHeight / 20
    player.width = 22 * dinoRunningScale
    player.normalHeight = targetHeight
    player.slideHeight = targetHeight * 0.5
    player.height = player.normalHeight

    ground.y = love.graphics.getHeight() - ground.height
    player.y = ground.y - player.height + 1

    local pterodactylTargetHeight = 70
    pterodactylScale = pterodactylTargetHeight / 20
    love.graphics.setFont(love.graphics.newFont(20))
end

function love.update(dt)
    if gameOver then return end

    score = score + dt * 10
    gameSpeed = 300 + score * 0.5

    if not player.isJumping then
        -- Handle slide timer
        if player.isSliding then
            player.slideTimer = player.slideTimer + dt
            if player.slideTimer >= player.maxSlideTime then
                player.isSliding = false
                player.slideTimer = 0
            end
            player.height = player.slideHeight
        else
            player.height = player.normalHeight
            player.slideTimer = 0
        end
        
        player.animationTimer = player.animationTimer + dt
        if player.animationTimer >= 0.1 then
            player.animationTimer = 0
            player.animationFrame = 1 - player.animationFrame
        end
    end

    pterodactylAnimationTimer = pterodactylAnimationTimer + dt
    if pterodactylAnimationTimer >= 0.15 then
        pterodactylAnimationTimer = 0
        pterodactylAnimationFrame = 1 - pterodactylAnimationFrame
    end

    if player.isJumping then
        player.velocityY = player.velocityY + gravity * dt
        player.y = player.y + player.velocityY * dt

        if player.y >= ground.y - player.height then
            player.y = ground.y - player.height + 1
            player.isJumping = false
            player.velocityY = 0
            
            -- Start sliding if player wanted to slide during jump
            if player.wantsToSlide then
                player.isSliding = true
            end
        end
    end

    spawnTimer = spawnTimer + dt
    if spawnTimer >= spawnInterval then
        spawnTimer = 0
        spawnInterval = math.random(10, 20) / 10
        spawnObstacle()
    end

    for i = #obstacles, 1, -1 do
        local obs = obstacles[i]
        obs.x = obs.x - gameSpeed * dt

        if obs.x + obs.width < 0 then
            table.remove(obstacles, i)
        end

        if checkCollision(player, obs) then
            gameOver = true
            if score > highScore then
                highScore = score
            end
        end
    end
end

function love.draw()
    love.graphics.clear(1, 1, 1)

    love.graphics.setColor(0, 0, 0)
    love.graphics.line(0, ground.y, love.graphics.getWidth(), ground.y)

    love.graphics.setColor(1, 1, 1)

    -- 5 frames total: 0-1 running, 2-3 sliding, 4 jumping
    local frameIndex
    if player.isJumping then
        frameIndex = 4
    elseif player.isSliding then
        frameIndex = 2 + player.animationFrame
    else
        frameIndex = player.animationFrame
    end
    
    local frameWidth = 22
    local frameHeight = 20
    local quad = love.graphics.newQuad(
        frameIndex * frameWidth, 0,
        frameWidth, frameHeight,
        images.dinoSheet:getDimensions()
    )
    
    love.graphics.draw(images.dinoSheet, quad, player.x, player.y, 0, dinoRunningScale, dinoRunningScale)

    for _, obs in ipairs(obstacles) do
        local frameWidth = 22
        local frameHeight = 20
        local frameIndex
        
        if obs.type == "pterodactyl" then
            -- Pterodactyl frames 6-7
            frameIndex = 6 + pterodactylAnimationFrame
        else
            -- Cactus frame 5
            frameIndex = 5
        end
        
        local quad = love.graphics.newQuad(
            frameIndex * frameWidth, 0,
            frameWidth, frameHeight,
            images.dinoSheet:getDimensions()
        )
        
        local scale = dinoRunningScale
        if obs.type == "pterodactyl" then
            scale = pterodactylScale
        else
            scale = obs.height / frameHeight
        end
        
        love.graphics.draw(images.dinoSheet, quad, obs.x, obs.y, 0, scale, scale)
        
        -- Draw obstacle hitbox
        if showHitboxes then
            love.graphics.setColor(1, 0, 0, 0.5)
            local hitboxX = obs.x + (obs.hitboxOffset or 0)
            local hitboxY = obs.y + (obs.hitboxOffsetY or 0)
            love.graphics.rectangle("line", hitboxX, hitboxY, obs.width, obs.height)
            love.graphics.setColor(1, 1, 1)
        end
    end
    
    -- Draw player hitbox
    if showHitboxes then
        local padding = player.hitboxPadding
        local topPadding = padding
        
        -- When sliding, reduce top hitbox by additional 3px
        if player.isSliding then
            topPadding = padding + 3 * dinoRunningScale
        end
        
        love.graphics.setColor(0, 1, 0, 0.5)
        love.graphics.rectangle("line", 
            player.x + padding, 
            player.y + topPadding, 
            player.width - padding * 2, 
            player.height - topPadding - padding)
        love.graphics.setColor(1, 1, 1)
    end
 
    love.graphics.setColor(0, 0, 0)
    love.graphics.print("Score: " .. math.floor(score), 10, 10)
    love.graphics.print("High Score: " .. math.floor(highScore), 10, 35)

    if gameOver then
        love.graphics.setColor(0, 0, 0, 0.7)
        love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())

        love.graphics.setColor(1, 1, 1)
        love.graphics.print("GAME OVER", love.graphics.getWidth() / 2 - 60, love.graphics.getHeight() / 2 - 30)
        love.graphics.print("Press SPACE to restart", love.graphics.getWidth() / 2 - 100, love.graphics.getHeight() / 2 + 10)
    end
end

function love.keypressed(key)
    if key == "space" or key == "up" then
        if gameOver then
            restartGame()
        elseif not player.isJumping then
            player.isJumping = true
            player.velocityY = jumpForce
            player.height = player.normalHeight
        end
    end
    
    if key == "down" or key == "lshift" or key == "rshift" then
        if not gameOver then
            player.wantsToSlide = true
            if not player.isJumping then
                player.isSliding = true
            end
        end
    end

    if key == "escape" then
        love.event.quit()
    end
    
    if key == "h" then
        showHitboxes = not showHitboxes
    end
end

function love.keyreleased(key)
    if key == "down" or key == "lshift" or key == "rshift" then
        player.wantsToSlide = false
        player.isSliding = false
        player.slideTimer = 0
        player.height = player.normalHeight
    end
end

function spawnObstacle()
    local obstacleType = math.random(1, 3)
    local obstacle = {
        x = love.graphics.getWidth()
    }

    if obstacleType == 1 and score > 50 then
        obstacle.type = "pterodactyl"
        local spriteHeight = 20 * pterodactylScale
        obstacle.width = 22 * pterodactylScale
        obstacle.height = 12 * pterodactylScale  -- 12px tall hitbox
        obstacle.hitboxOffsetY = 3 * pterodactylScale  -- 3px down from top
        obstacle.spriteHeight = spriteHeight
        local flyHeights = {
            ground.y - spriteHeight + 1,
            ground.y - spriteHeight - 60,
            ground.y - spriteHeight - 120
        }
        obstacle.y = flyHeights[math.random(1, 3)]
    else
        obstacle.type = "cactus"
        local cactusScale = dinoRunningScale * 0.8
        local spriteWidth = 22 * cactusScale
        obstacle.width = 12 * dinoRunningScale
        obstacle.height = 20 * cactusScale
        obstacle.spriteWidth = spriteWidth
        obstacle.hitboxOffset = (spriteWidth - obstacle.width) / 2
        obstacle.y = ground.y - obstacle.height + 1
    end

    table.insert(obstacles, obstacle)
end

function checkCollision(a, b)
    local padding = a.hitboxPadding or 0
    local topPadding = padding
    
    -- When sliding, reduce top hitbox by additional 3px
    if a.isSliding then
        topPadding = padding + 3 * dinoRunningScale
    end
    
    -- Offset for centered cactus hitbox
    local bx = b.x
    local bOffset = b.hitboxOffset or 0
    local by = b.y
    local bOffsetY = b.hitboxOffsetY or 0
    
    return a.x + padding < bx + bOffset + b.width - padding and
           a.x + a.width - padding > bx + bOffset + padding and
           a.y + topPadding < by + bOffsetY + b.height - padding and
           a.y + a.height - padding > by + bOffsetY + padding
end

function restartGame()
    gameOver = false
    score = 0
    obstacles = {}
    spawnTimer = 0
    gameSpeed = 300
    player.isSliding = false
    player.wantsToSlide = false
    player.slideTimer = 0
    player.height = player.normalHeight
    player.y = ground.y - player.height + 1
    player.isJumping = false
    player.velocityY = 0
    player.animationFrame = 0
    player.animationTimer = 0
end
