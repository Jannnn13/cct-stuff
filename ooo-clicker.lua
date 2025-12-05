-- A simple CC: Tweaked game where you have to click on O's to gain points

-- Licensed under the MIT License
-- Made by Jannnn13

local version = "1.0.0"
local cfgPath = customConfigPath or ".oooClickerConfig.json"

local function pullClick()
    local _, _, x, y = os.pullEvent("mouse_click")

    return {
        x = x,
        y = y
    }
end

local function readConfig()
    local cfgTemplate = {
        highScore = 0,

        theme = {
            darkMode = false,
            blackWhiteMode = false
        }
    }

    if not fs.exists(cfgPath) then
        local file = fs.open(cfgPath, "w")
        file.write(textutils.serializeJSON(cfgTemplate))
        file.close()
    end

    local file = fs.open(cfgPath, "r")

    local content = file.readAll()
    file.close()

    local cfg 

    pcall(function()
        cfg = textutils.unserializeJSON(content)
    end)

    if (not cfg) or (type(cfg) ~= "table") then
        cfg = cfgTemplate
    end

    return cfg
end

local cfg = readConfig(cfgPath)

local function saveConfig(cfg)
    local file = fs.open(cfgPath, "w")
    file.write(textutils.serializeJSON(cfg))
    file.close()
end

local function getColor()
    local rt = {}

    if term.isColor() or not cfg.theme.blackWhiteMode then
        if cfg.theme.darkMode then
            rt.bg = colors.black
            rt.playButton = colors.lime
            rt.onlineButton = colors.orange
            rt.settingsButton = colors.lightGray
            rt.exitButton = colors.red
            rt.text = colors.blue
        else
            rt.bg = colors.white
            rt.playButton = colors.lime
            rt.onlineButton = colors.orange
            rt.settingsButton = colors.gray
            rt.exitButton = colors.red
            rt.text = colors.orange
        end
    else
        if cfg.theme.darkMode then
            rt.bg = colors.black
            rt.playButton = colors.white
            rt.onlineButton = colors.white
            rt.settingsButton = colors.white
            rt.exitButton = colors.white
            rt.text = colors.white
        else
            rt.bg = colors.white
            rt.playButton = colors.black
            rt.onlineButton = colors.black
            rt.settingsButton = colors.black
            rt.exitButton = colors.black
            rt.text = colors.black
        end
    end

    return rt
end

local function pen(text, color)
    local previousTextColor = term.getTextColor()
    
    term.setTextColor(color)
    term.write(text)
    term.setTextColor(previousTextColor)
end

local function waitForButtonClick(buttons)
    while true do
        local coor = pullClick()

        if coor and coor.x and coor.y then
            for _, button in ipairs(buttons) do
                local text = button.text
                local width = #text

                if width > 0 and (coor.y == button.y) and (coor.x >= button.x) and (coor.x < button.x + width) then
                    return text, button.id
                end
            end
        end
    end
end

local function onOff(boolean)
    if boolean then
        return "On"
    else
        return "Off"
    end
end

local function onOffColor(boolean)
    if boolean then
        return getColor().playButton
    else
        return getColor().exitButton
    end
end

local function res()
    local x, y = term.getSize()

    return {
        x = x,
        y = y
    }
end

if (res().x < 11) or (res().y < 6) then
    error("Screen is too small! Minimum size is 11x6.", 0)
end

local previousColors = {
    bg = term.getBackgroundColor(),
    text = term.getTextColor()
}

local game = {}

function game.titleScreen()
    term.setBackgroundColor(getColor().bg)
    term.clear()

    term.setCursorPos(1, 1)
    
    if res().y > 6 then
        pen("OOO", getColor().text)
        term.setCursorPos(1, 2)
        pen("Clicker", getColor().text)
    else
        pen("OOO Clicker", getColor().text)
    end

    term.setCursorPos(1, res().y - 2)
    pen("Play", getColor().playButton)

    term.setCursorPos(1, res().y - 1)
    pen("Settings", getColor().settingsButton)

    term.setCursorPos(1, res().y)
    pen("Exit", getColor().exitButton)

    local clickedButton = waitForButtonClick({
        { text = "Play", x = 1, y = res().y - 2 },
        { text = "Settings", x = 1, y = res().y - 1 },
        { text = "Exit", x = 1, y = res().y }
    })

    if clickedButton == "Play" then
        local looseCause, score = game.mainGame()
        game.scoreViewer(looseCause, score)
    elseif clickedButton == "Settings" then
        game.settings()
    elseif clickedButton == "Exit" then
        term.setBackgroundColor(previousColors.bg)
        term.setTextColor(previousColors.text)
        term.clear()
        term.setCursorPos(1, 1)

        return "Game Exit"
    end
end

function game.settings()
    term.setBackgroundColor(getColor().bg)
    term.clear()

    term.setCursorPos(1, 1)
    pen("X", getColor().exitButton)

    term.setCursorPos(res().x - #version, 1)
    pen("v" .. version, getColor().text)

    term.setCursorPos(1, 2)
    pen("Dark Mode:", getColor().text)

    term.setCursorPos(1, 3)
    pen(onOff(cfg.theme.darkMode), onOffColor(cfg.theme.darkMode))

    local buttons = {
        { text = "X", id = "X", x = 1, y = 1 },
        { text = onOff(cfg.theme.darkMode), id = "darkMode", x = 1, y = 3 },
    }

    local _, clickedButton = waitForButtonClick(buttons)

    if clickedButton == "X" then
        return
    elseif clickedButton == "darkMode" then
        cfg.theme.darkMode = not cfg.theme.darkMode
        saveConfig(cfg)
        game.settings()
    elseif clickedButton == "blackWhiteMode" then
        cfg.theme.blackWhiteMode = true
        saveConfig(cfg)
        game.settings()
    end
end

function game.scoreViewer(looseCause, score)
    if score > cfg.highScore then
        cfg.highScore = score
        saveConfig(cfg)
    end

    term.setBackgroundColor(getColor().bg)
    term.clear()

    term.setCursorPos(1, 1)
    pen(looseCause, getColor().exitButton)

    term.setCursorPos(1, 2)
    pen("Score: " .. score, getColor().text)

    term.setCursorPos(1, 3)
    pen("HS: " .. cfg.highScore, getColor().text) 

    term.setCursorPos(1, 5)
    pen("Play Again", getColor().playButton)

    term.setCursorPos(1, 6)
    pen("Exit", getColor().exitButton)

    local clickedButton = waitForButtonClick({
        { text = "Play Again", x = 1, y = 5 },
        { text = "Exit", x = 1, y = 6 }
    })

    if clickedButton == "Play Again" then
        local looseCause, score = game.mainGame()
        game.scoreViewer(looseCause, score)
    elseif clickedButton == "Exit" then
        return
    end
end

function game.mainGame()
    local score = 0
    local looseCause = ""

    while true do
        parallel.waitForAny(function()
            term.setBackgroundColor(getColor().bg)
            term.clear()

            term.setCursorPos(1, 1)
            pen("X", getColor().exitButton)

            term.setCursorPos(res().x - #tostring(score), 1)
            pen(tostring(score), getColor().text)

            local random = {}
            random.x = math.random(1, res().x)
            random.y = math.random(2, res().y)

            term.setCursorPos(random.x, random.y)
            pen("O", getColor().text)

            local clickedButton = waitForButtonClick({
                { text = "X", x = 1, y = 1 },
                { text = "O", x = random.x, y = random.y }
            })

            if clickedButton == "X" then
                looseCause = "Cancelled."
                return
            end
        end, function()
            sleep(1.5)
            looseCause = "Time's up!"
        end)

        if looseCause ~= "" then
            break
        else
            score = score + 1
        end
    end

    return looseCause, score
end

while true do
    if game.titleScreen() == "Game Exit" then
        break
    end
end