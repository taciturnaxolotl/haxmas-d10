local player = {
    x = 80,
    y = 0,
    width = 1,
    height = 1,
    velocityY = 0,
    isJumping = false,
    hitboxPadding = 8,
    animationFrame = 0,
    animationTimer = 0
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

local images = {}
local dinoScale = 1
local dinoRunningScale = 1
local pterodactylScale = 1
local pterodactylAnimationTimer = 0
local pterodactylAnimationFrame = 0

function love.load()
    love.window.setTitle("Haxmas Runner :3")
    
    images.dino = love.graphics.newImage("assets/dino.png")
    images.dinoRunning = love.graphics.newImage("assets/dino_running_sheet.png")
    images.cactus = love.graphics.newImage("assets/cactus.png")
    images.pterodactyl = love.graphics.newImage("assets/pterodactyl.png")
    
    local targetHeight = 80
    dinoScale = targetHeight / images.dino:getHeight()
    dinoRunningScale = targetHeight / images.dinoRunning:getHeight()
    player.width = (images.dinoRunning:getWidth() / 2) * dinoRunningScale
    player.height = targetHeight

    ground.y = love.graphics.getHeight() - ground.height
    player.y = ground.y - player.height + 1

    local pterodactylTargetHeight = 70
    pterodactylScale = pterodactylTargetHeight / images.pterodactyl:getHeight()
    love.graphics.setFont(love.graphics.newFont(20))
end

function love.update(dt)
    if gameOver then return end

    score = score + dt * 10
    gameSpeed = 300 + score * 0.5

    if not player.isJumping then
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

    if player.isJumping then
        love.graphics.draw(images.dino, player.x, player.y, 0, dinoScale, dinoScale)
    else
        local frameWidth = images.dinoRunning:getWidth() / 2
        local quad = love.graphics.newQuad(
            player.animationFrame * frameWidth, 0,
            frameWidth, images.dinoRunning:getHeight(),
            images.dinoRunning:getDimensions()
        )
        love.graphics.draw(images.dinoRunning, quad, player.x, player.y, 0, dinoRunningScale, dinoRunningScale)
    end

    for _, obs in ipairs(obstacles) do
        if obs.type == "pterodactyl" then
            local frameWidth = images.pterodactyl:getWidth() / 2
            local quad = love.graphics.newQuad(
                pterodactylAnimationFrame * frameWidth, 0,
                frameWidth, images.pterodactyl:getHeight(),
                images.pterodactyl:getDimensions()
            )
            love.graphics.draw(images.pterodactyl, quad, obs.x, obs.y, 0, pterodactylScale, pterodactylScale)
        else
            love.graphics.draw(images.cactus, obs.x, obs.y, 0,
                obs.width / images.cactus:getWidth(),
                obs.height / images.cactus:getHeight())
        end
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
        end
    end

    if key == "escape" then
        love.event.quit()
    end
end

function spawnObstacle()
    local obstacleType = math.random(1, 3)
    local obstacle = {
        x = love.graphics.getWidth()
    }

    if obstacleType == 1 and score > 50 then
        obstacle.type = "pterodactyl"
        obstacle.width = (images.pterodactyl:getWidth() / 2) * pterodactylScale
        obstacle.height = images.pterodactyl:getHeight() * pterodactylScale
        local flyHeights = {
            ground.y - obstacle.height + 1,
            ground.y - obstacle.height - 60,
            ground.y - obstacle.height - 120
        }
        obstacle.y = flyHeights[math.random(1, 3)]
    else
        obstacle.type = "cactus"
        obstacle.width = 30
        obstacle.height = 50
        obstacle.y = ground.y - obstacle.height + 1
    end

    table.insert(obstacles, obstacle)
end

function checkCollision(a, b)
    local padding = a.hitboxPadding or 0
    return a.x + padding < b.x + b.width - padding and
           a.x + a.width - padding > b.x + padding and
           a.y + padding < b.y + b.height - padding and
           a.y + a.height - padding > b.y + padding
end

function restartGame()
    gameOver = false
    score = 0
    obstacles = {}
    spawnTimer = 0
    gameSpeed = 300
    player.y = ground.y - player.height + 1
    player.isJumping = false
    player.velocityY = 0
    player.animationFrame = 0
    player.animationTimer = 0
end
