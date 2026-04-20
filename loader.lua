local Library = loadstring(game:HttpGet("https://github.com/CatThatDrinksSprite/moonshine/raw/main/libraries/scoot/Library.lua", true))()
local success, result = pcall(function()
    return loadstring(game:HttpGet(string.format("https://github.com/CatThatDrinksSprite/moonshine/raw/main/games/%s.lua", game.PlaceId), true))
end)

if not isfolder("moonshineimages") then
    makefolder("moonshineimages")
end

if not isfile("moonshineimages/moon.png") then
    writefile("moonshineimages/moon.png", game:HttpGet("https://github.com/CatThatDrinksSprite/moonshine/raw/main/moonshineimages/moon.png", true))
end

if success and type(result) == "function" then
    Library:Notification("Loading!", string.format("Found script for %s!", game.PlaceId), 5)
    result()
else
    Library:Notification("Failed to load.", "Game may not be supported, Check the github for supported games!", 5)
end