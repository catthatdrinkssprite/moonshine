

# 🌙 moonshine

a fully opensource script for roblox

## 🎮 supported games


| game name   | place id  | lines of code |
| ----------- | --------- | ------------- |
| prison life | 155615604 | 1185          |


## 📦 script

(Click to expand)

```lua
loadstring(game:HttpGet("https://github.com/CatThatDrinksSprite/moonshine/raw/main/loader.lua", true))()
```





---

## 🔫 prison life

### combat

gun mods

- **no fire rate** — removes fire rate delay on all guns
- **no spread** — zeroes out bullet spread on all guns
- **force auto fire** — forces all guns to fire automatically



aimbot

- **silent aim** — hooks raycast to redirect bullets to the closest target
  - fov circle (accent colored) and tracer (mouse to target)
  - configurable radius, bone selection (head / humanoidrootpart)
  - wall check, death check
  - team and inmate type filters (guards, inmates, criminals / regular, aggressive, arrestable)
  - friend check with player whitelist dropdown



### movement

- **noclip** — walk through walls and objects
- **infinite jump** — jump mid-air without limits

### visuals

esp

- **filters** — filter by team and inmate type, whitelist specific players (hide esp or show green)
- **name esp** — floating names above players with team color, inmate status prefixes ([A] / [W]), outline
- **box esp** — 2d bounding boxes around players with team color, outline



character

- **force field character** — applies forcefield material to your character



### world

- **remove doors** — removes all doors from the map (reversible)

### misc

- **remove jump cooldown** — disables the anti-jump cooldown script
- **always backpack** — keeps the backpack enabled even when crouching or tased
- **anti invisible** — detects and stops the invisibility animation, highlights invisible players in red
- **anti tase** — counteracts taser effects by stopping stun animations and restoring movement
- **arrest aura** — automatically arrests nearby players within 10 studs, with friend check and whitelist
- **fist aura** — automatically punches nearby players within 10 studs, with friend check and whitelist

---



## 🛡️ license

this project is licensed under the [gnu general public license v3.0 or later](https://github.com/CatThatDrinksSprite/moonshine/blob/main/LICENSE).



---



## 📃 credits

catthatdrinkssprite - script founder and lead developer

azula.cs - active contributor

scoot - ui library

