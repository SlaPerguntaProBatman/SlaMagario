-- Variáveis globais
local playerX, playerY
local playerSize = 20
local screenWidth, screenHeight = love.graphics.getWidth(), love.graphics.getHeight()
local enemies = {}
local goldenBalls = {}
local score = 0
local rebirthThreshold = 100 -- Pontuação necessária para rebirth
local rebirthMultiplier = 1
local rebirthPoints = 0 -- Pontos acumulados em direção ao rebirth
local rebirthLetter = "A" -- Letra para indicar o progresso em direção ao próximo rebirth
local pets = {} -- Lista de pets comprados
local petShopOpen = false -- Loja de pets aberta ou fechada
local petShopButton = {x = screenWidth - 100, y = 10, width = 90, height = 30} -- Botão da loja de pets
local petCosts = { -- Preços dos pets
    {name = "Ultra Pet", cost = 1000000000, effect = "+10000 score, +10 rebirth"},
    {name = "Mega Pet", cost = 1000000, effect = "+100 score, +1 rebirth"},
    {name = "Super Pet", cost = 100000, effect = "+50 score"},
    {name = "Mighty Pet", cost = 10000, effect = "+20 score"},
    {name = "Awesome Pet", cost = 1000, effect = "+10 score"},
    {name = "Cool Pet", cost = 100, effect = "+5 score"},
    {name = "Fantastic Pet", cost = 10000000, effect = "+500 score, +5 rebirth"},
    {name = "Legendary Pet", cost = 100000000, effect = "+5000 score, +50 rebirth"}
}

local gameOverButton = {x = screenWidth / 2 - 100, y = screenHeight / 2 + 50, width = 200, height = 50} -- Botão de "Tentar Novamente"

-- Estado do jogo
local gameRunning = true
local gameOver = false

-- Função de inicialização
function love.load()
    loadData()
    if #enemies == 0 then
        -- Criação de inimigos vermelhos e bem maiores
        for i = 1, 10 do
            createEnemy()
        end
    end

    if #goldenBalls == 0 then
        -- Criação de bolinhas douradas
        for i = 1, 5 do
            createGoldenBall()
        end
    end
end

-- Função de criação de inimigos
function createEnemy()
    local enemy = {
        x = love.math.random(0, screenWidth),
        y = love.math.random(0, screenHeight),
        size = 80, -- Tamanho ainda maior dos inimigos
        color = {1, 0, 0}, -- Cor vermelha
        speed = love.math.random(20, 50) -- Velocidade aleatória
    }
    table.insert(enemies, enemy)
end

-- Função de criação de bolinha dourada
function createGoldenBall()
    local goldenBall = {
        x = love.math.random(0, screenWidth),
        y = love.math.random(0, screenHeight),
        size = love.math.random(10, 20),
        color = {1, 1, 0}, -- Cor amarela
        visible = true
    }
    table.insert(goldenBalls, goldenBall)
end

-- Função de atualização
function love.update(dt)
    if gameRunning then
        -- Movimentação do jogador
        local dx, dy = 0, 0
        if love.keyboard.isDown("w") then
            dy = -200 * dt
        elseif love.keyboard.isDown("s") then
            dy = 200 * dt
        end

        if love.keyboard.isDown("a") then
            dx = -200 * dt
        elseif love.keyboard.isDown("d") then
            dx = 200 * dt
        end

        playerX = playerX + dx
        playerY = playerY + dy

        -- Verificar limites do mapa
        playerX = math.max(0, math.min(playerX, screenWidth))
        playerY = math.max(0, math.min(playerY, screenHeight))

        -- Colisão do jogador com as bolinhas douradas
        for i, ball in ipairs(goldenBalls) do
            local dx = playerX - ball.x
            local dy = playerY - ball.y
            local distance = math.sqrt(dx * dx + dy * dy)

            if distance < playerSize / 2 + ball.size / 2 and ball.visible then
                score = score + 5 * rebirthMultiplier -- Pontuação aumentada ao comer a bolinha dourada
                rebirthPoints = rebirthPoints + 5 * rebirthMultiplier -- Pontos acumulados para o rebirth
                playerSize = playerSize + 5 -- Aumentar o tamanho do jogador
                table.remove(goldenBalls, i)
                createGoldenBall() -- Gerar nova bolinha dourada
                break
            end
        end

        -- Atualização dos inimigos
        for _, enemy in ipairs(enemies) do
            local dx = playerX - enemy.x
            local dy = playerY - enemy.y
            local distance = math.sqrt(dx * dx + dy * dy)

            local angle = math.atan2(playerY - enemy.y, playerX - enemy.x)
            enemy.x = enemy.x + math.cos(angle) * enemy.speed * dt
            enemy.y = enemy.y + math.sin(angle) * enemy.speed * dt
        end

        -- Colisão do jogador com os inimigos
        for i, enemy in ipairs(enemies) do
            local dx = playerX - enemy.x
            local dy = playerY - enemy.y
            local distanceToPlayer = math.sqrt(dx * dx + dy * dy)

            if distanceToPlayer < playerSize / 2 + enemy.size / 2 then
                if enemy.size > playerSize then
                    -- Se o inimigo for maior, o jogador perde
                    gameOver = true
                    gameRunning = false
                    break
                else
                    -- Se o jogador for maior, ele ganha os pontos do inimigo
                    score = score + enemy.size * rebirthMultiplier
                    rebirthPoints = rebirthPoints + enemy.size * rebirthMultiplier
                    playerSize = playerSize + 5 -- Aumentar o tamanho do jogador
                    table.remove(enemies, i)
                    createEnemy() -- Gerar novo inimigo
                    break
                end
            end
        end

        -- Verificar se o jogador atingiu o rebirth
        if rebirthPoints >= rebirthThreshold then
            rebirthMultiplier = rebirthMultiplier * 2 -- Duplicar o multiplicador de rebirth
            rebirthPoints = rebirthPoints - rebirthThreshold -- Reduzir os pontos necessários para o próximo rebirth
            rebirthThreshold = rebirthThreshold * 2 -- Dobrar a pontuação necessária para o próximo rebirth
            rebirthLetter = string.char(rebirthLetter:byte() + 1) -- Aumentar a letra para o próximo rebirth
        end
    end
end

-- Função de desenho
function love.draw()
    -- Desenho do jogador
    love.graphics.setColor(1, 1, 1)
    love.graphics.circle("fill", playerX, playerY, playerSize / 2)

    -- Desenho dos inimigos
    for _, enemy in ipairs(enemies) do
        love.graphics.setColor(1, 0, 0)
        love.graphics.circle("fill", enemy.x, enemy.y, enemy.size / 2)
    end

    -- Desenho das bolinhas douradas
    for _, ball in ipairs(goldenBalls) do
        love.graphics.setColor(1, 1, 0) -- Cor amarela
        love.graphics.circle("fill", ball.x, ball.y, ball.size / 2)
    end

    -- Exibição da pontuação e rebirth
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Score: " .. score, 10, 10)
    love.graphics.print("Rebirth Points: " .. rebirthPoints, 10, 30)
    love.graphics.print("Rebirth Letter: " .. rebirthLetter, 10, 50)

    -- Desenho do botão da loja de pets
    love.graphics.setColor(0.5, 0.5, 0.5)
    love.graphics.rectangle("fill", petShopButton.x, petShopButton.y, petShopButton.width, petShopButton.height)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Pet Shop", petShopButton.x + 10, petShopButton.y + 10)

    -- Exibição dos pets
    love.graphics.print("Pets:", 10, 70)
    for i, pet in ipairs(pets) do
        love.graphics.print("Pet " .. i .. ": " .. pet.name, 10, 70 + i * 20)
    end

    -- Exibição da loja de pets
    if petShopOpen then
        love.graphics.setColor(0.5, 0.5, 0.5, 0.8)
        love.graphics.rectangle("fill", screenWidth / 2 - 200, screenHeight / 2 - 150, 400, 300)
        love.graphics.setColor(1, 1, 1)
        love.graphics.print("Pet Shop", screenWidth / 2 - 40, screenHeight / 2 - 140)
        for i, pet in ipairs(petCosts) do
            love.graphics.print(pet.name .. ": " .. pet.cost .. " score (" .. pet.effect .. ")", screenWidth / 2 - 180, screenHeight / 2 - 100 + i * 30)
        end
    end

    -- Exibição da tela de Game Over
    if gameOver then
        love.graphics.setColor(0, 0, 0, 0.5)
        love.graphics.rectangle("fill", 0, 0, screenWidth, screenHeight)

        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("Game Over", 0, screenHeight / 2 - 50, screenWidth, "center")

        -- Desenhar botão "Tentar Novamente"
        love.graphics.setColor(0.5, 0.5, 0.5)
        love.graphics.rectangle("fill", gameOverButton.x, gameOverButton.y, gameOverButton.width, gameOverButton.height)
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("Tentar Novamente", gameOverButton.x, gameOverButton.y + 15, gameOverButton.width, "center")
    end
end

-- Função para encerrar o jogo
function gameOverAction()
    saveData()
    love.event.quit("restart")
end

-- Função para salvar os dados do jogo
function saveData()
    local data = {
        playerX = playerX,
        playerY = playerY,
        playerSize = playerSize,
        enemies = enemies,
        goldenBalls = goldenBalls,
        score = score,
        rebirthMultiplier = rebirthMultiplier,
        rebirthThreshold = rebirthThreshold,
        rebirthPoints = rebirthPoints,
        rebirthLetter = rebirthLetter,
        pets = pets
    }
    love.filesystem.write("save.txt", table.serialize(data))
end

-- Função para carregar os dados do jogo
function loadData()
    if love.filesystem.getInfo("save.txt") then
        local data = love.filesystem.load("save.txt")()
        playerX = data.playerX or screenWidth / 2
        playerY = data.playerY or screenHeight / 2
        playerSize = data.playerSize or 20
        enemies = data.enemies or {}
        goldenBalls = data.goldenBalls or {}
        score = data.score or 0
        rebirthMultiplier = data.rebirthMultiplier or 1
        rebirthThreshold = data.rebirthThreshold or 100
        rebirthPoints = data.rebirthPoints or 0
        rebirthLetter = data.rebirthLetter or "A"
        pets = data.pets or {}
    else
        playerX = screenWidth / 2
        playerY = screenHeight / 2
        playerSize = 20
        enemies = {}
        goldenBalls = {}
        score = 0
        rebirthMultiplier = 1
        rebirthThreshold = 100
        rebirthPoints = 0
        rebirthLetter = "A"
        pets = {}
    end
end

-- Função para comprar um pet
function buyPet(petIndex)
    local pet = petCosts[petIndex]
    if score >= pet.cost then
        score = score - pet.cost
        table.insert(pets, {name = pet.name, effect = pet.effect})
    end
end

-- Função de clique do mouse
function love.mousepressed(x, y, button)
    if button == 1 then
        -- Verificar se o botão da loja de pets foi clicado
        if x >= petShopButton.x and x <= petShopButton.x + petShopButton.width and
           y >= petShopButton.y and y <= petShopButton.y + petShopButton.height then
            petShopOpen = not petShopOpen
        end

        -- Verificar se a loja de pets está aberta e um pet foi clicado
        if petShopOpen then
            for i, pet in ipairs(petCosts) do
                if x >= screenWidth / 2 - 200 and x <= screenWidth / 2 + 200 and
                   y >= screenHeight / 2 - 100 + i * 30 and y <= screenHeight / 2 - 70 + i * 30 then
                    buyPet(i)
                end
            end
        end

        -- Verificar se o botão "Tentar Novamente" foi clicado
        if gameOver then
            if x >= gameOverButton.x and x <= gameOverButton.x + gameOverButton.width and
               y >= gameOverButton.y and y <= gameOverButton.y + gameOverButton.height then
                gameOverAction()
            end
        end
    end
end

-- Chamar a função para carregar os dados ao iniciar o jogo
loadData()
