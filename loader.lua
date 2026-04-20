local Library = loadstring(game:HttpGet("https://github.com/CatThatDrinksSprite/moonshine/raw/main/libraries/scoot/Library.lua", true))()
local success, result = pcall(function()
    return loadstring(game:HttpGet(string.format("https://github.com/CatThatDrinksSprite/moonshine/raw/main/games/%s.lua", game.PlaceId), true))
end)

if not isfolder("moonshine") then
    makefolder("moonshine")
end

if not isfolder("moonshine/images") then
    makefolder("moonshine/images")
end

if not isfolder("moonshine/txts") then
    makefolder("moonshine/txts")
end

if not isfolder("moonshine/sounds") then
    makefolder("moonshine/sounds")
end

if not isfile("moonshine/images/moon.png") then
    writefile("moonshine/images/moon.png", game:HttpGet("https://github.com/CatThatDrinksSprite/moonshine/raw/main/moonshine/images/moon.png", true))
end

if not isfile("moonshine/images/W AZULA.png") then
    writefile("moonshine/images/W AZULA.png", game:HttpGet("https://github.com/CatThatDrinksSprite/moonshine/raw/main/moonshine/images/W%20AZULA.png", true))
end

if not isfile("moonshine/txts/W AZULA.txt") then
    writefile("moonshine/txts/W AZULA.txt", game:HttpGet("https://github.com/CatThatDrinksSprite/moonshine/raw/main/moonshine/txts/W%20AZULA.txt", true))
end

if not isfile("moonshine/sounds/rust.mp3") then
    writefile("moonshine/sounds/rust.mp3", game:HttpGet("https://github.com/CatThatDrinksSprite/moonshine/raw/main/moonshine/sounds/rust.mp3", true))
end

if not isfile("moonshine/sounds/minecraft orb.mp3") then
    writefile("moonshine/sounds/minecraft orb.mp3", game:HttpGet("https://github.com/CatThatDrinksSprite/moonshine/raw/main/moonshine/sounds/minecraft%20orb.mp3", true))
end

if success and type(result) == "function" then
    Library:Notification("Loading!", string.format("Found script for %s!", game.PlaceId), 5)
    result()
else
    Library:Notification("Failed to load.", "Game may not be supported, Check the github for supported games!", 5)
end