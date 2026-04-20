local BASE_URL = "https://github.com/CatThatDrinksSprite/moonshine/raw/main"

local Folders = {
    "moonshine",
    "moonshine/images",
    "moonshine/txts",
    "moonshine/sounds",
}

local Assets = {
    ["moonshine/images/moon.png"]           = "moonshine/images/moon.png",
    ["moonshine/images/W AZULA.png"]        = "moonshine/images/W%20AZULA.png",
    ["moonshine/txts/W AZULA.txt"]          = "moonshine/txts/W%20AZULA.txt",
    ["moonshine/sounds/rust.mp3"]           = "moonshine/sounds/rust.mp3",
    ["moonshine/sounds/minecraft orb.mp3"]  = "moonshine/sounds/minecraft%20orb.mp3",
}

for _, folder in Folders do
    if not isfolder(folder) then
        makefolder(folder)
    end
end

local FailedAssets = {}

for localPath, remotePath in Assets do
    if not isfile(localPath) then
        local ok, data = pcall(game.HttpGet, game, BASE_URL .. "/" .. remotePath, true)
        if ok then
            writefile(localPath, data)
        else
            table.insert(FailedAssets, localPath)
        end
    end
end

local Library = loadstring(game:HttpGet(BASE_URL .. "/libraries/scoot/Library.lua", true))()

if #FailedAssets > 0 then
    Library:Notification("Download Failed.", "Could not download: " .. table.concat(FailedAssets, ", "), 8)
end

local success, result = pcall(function()
    return loadstring(game:HttpGet(string.format("%s/games/%s.lua", BASE_URL, game.PlaceId), true))
end)

if success and type(result) == "function" then
    Library:Notification("Loading!", string.format("Found script for %s!", game.PlaceId), 5)
    result()
else
    Library:Notification("Failed to load.", "Game may not be supported, Check the github for supported games!", 5)
end
