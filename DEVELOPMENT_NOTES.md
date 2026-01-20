# Easy Mode Mod - Development Notes

## Issues and Solutions Summary

This document summarizes the technical issues encountered during the development of the Easy Mode mod for The Binding of Isaac: Repentance and their solutions.

---

## 1. Mod Callback Registration Issue

### Problem
Callbacks registered using `Isaac.AddCallback(Mod, ...)` failed to trigger because the `Mod` variable was not defined.

### Lua Context
- The `RegisterMod()` function returns a mod table, but Lua scoping rules require explicit variable assignment
- Simply calling `RegisterMod("Name", 1)` doesn't create a global `Mod` variable

### Original Code (Broken)
```lua
local EasyMode = RegisterMod("Easy Mode", 1)

-- This fails: Mod is nil
Isaac.AddCallback(Mod, ModCallbacks.MC_NPC_UPDATE, onNPCUpdate, 0)
```

### Solution
Use the registered mod table directly or create an alias:
```lua
local EasyMode = RegisterMod("Easy Mode", 1)
local Mod = EasyMode  -- Create alias

Isaac.AddCallback(EasyMode, ModCallbacks.MC_NPC_UPDATE, onNPCUpdate, 0)
```

### Best Practice
Always use the mod table returned by `RegisterMod()` directly:
```lua
Isaac.AddCallback(EasyMode, ModCallbacks.MC_NPC_UPDATE, onNPCUpdate, 0)
```

---

## 2. Callback Timing Issue

### Problem
`MC_NPC_UPDATE`, `MC_POST_PROJECTILE_UPDATE`, and `MC_POST_TEAR_UPDATE` callbacks were not firing for enemies in the room.

### Root Cause
These callbacks are entity-specific and only trigger for individual entities when they are updated. If an entity is already in the room before the mod loads, the callback may not capture it properly.

### Solution
Use `MC_POST_UPDATE` combined with `Isaac.GetRoomEntities()` to scan all entities each frame:
```lua
local function onPostUpdate()
    local entities = Isaac.GetRoomEntities()
    for _, entity in ipairs(entities) do
        -- Process each entity
    end
end

Isaac.AddCallback(EasyMode, ModCallbacks.MC_POST_UPDATE, onPostUpdate, 0)
```

### Trade-off
- Pros: Catches all entities reliably
- Cons: Higher performance cost (scans all entities every frame)

---

## 3. Entity Valid Check Issue

### Problem
`entity.Valid` returns `nil` instead of `false` for valid entities, causing condition checks to fail.

### Lua Behavior
In Lua, `nil` is falsy, so `if entity.Valid` returns false even for valid entities.

### Original Code (Broken)
```lua
if entity.Valid then
    -- This never executes for valid entities!
end
```

### Solution
Use explicit comparison:
```lua
if entity.Valid ~= false then
    -- This correctly handles both true and nil values
end
```

### Alternative
Since `nil ~= false` is `true` in Lua:
```lua
if entity.Valid then
    -- Still doesn't work for nil
end

if not (entity.Valid == false) then
    -- Works correctly
end
```

---

## 4. Enemy Detection Methods

### Problem
Using `entity:IsActiveEnemy()` and `entity:IsVulnerableEnemy()` returned false for valid enemies, causing them to be skipped.

### Investigation
These methods have complex internal logic that depends on:
- Enemy state (sleeping, attacking, etc.)
- Champion status
- Room context

### Solution
Use `entity:ToNPC()` as the primary detection method:
```lua
local npc = entity:ToNPC()
if npc then
    -- Entity is a valid NPC
    -- Check Type for enemy classification
end
```

### Additional Type Check
```lua
local etype = entity.Type
if etype >= 10 and etype ~= 1000 then
    -- Type 10-999 are enemies
    -- Type 1000 is effect
    -- Type < 10 is player or other non-enemy
end
```

---

## 5. Chinese Character Encoding

### Problem
Console output showed garbled characters when using Chinese comments or print statements.

### Root Cause
The Binding of Isaac console does not support UTF-8 encoding for Chinese characters.

### Solution
Use English for all debug output:
```lua
-- Instead of:
print("[调试] 敌人速度")

-- Use:
print("[DEBUG] Enemy speed")
```

---

## 6. Game Entity Types Reference

### Common Entity Types
| Type | Description |
|------|-------------|
| 1 | Player |
| 2 | Tear |
| 3 | Effect |
| 4-9 | Various |
| 10-999 | Enemies (NPCs) |
| 1000 | Effect/Decoration |

### EntityType Constants
```lua
EntityType.ENTITY_PLAYER     -- 1
EntityType.ENTITY_TEAR       -- 2
EntityType.ENTITY_PROJECTILE -- 9
EntityType.ENTITY_FAMILIAR   -- 3
```

### SpawnerType for Tears
- `EntityType.ENTITY_PLAYER` (1): Player's tears
- `>= 10`: Enemy tears

---

## 7. Performance Considerations

### Issue
Scanning all entities every frame can be expensive for large rooms with many enemies.

### Optimizations Applied
1. Skip stationary entities (speed < 0.5)
2. Skip zero-speed projectiles (speed < 0.1)
3. Use weak tables for caches to allow garbage collection

### Future Improvements
- Add frame skip (process every N frames)
- Add distance check (only process enemies near player)
- Use entity tags for faster filtering

---

## 8. Mod Structure Recommendations

### Single File vs Multiple Files

**Problem**: The game's `require()` function has limitations and may not work reliably for loading additional Lua files.

### Recommendation
Keep all mod logic in a single `main.lua` file for maximum compatibility.

### File Structure
```
EasyModeMod/
├── main.lua          # All mod logic
├── metadata.xml      # Mod description
└── README.md         # Documentation
```

---

## 9. Configuration Management

### Original Issue
Damage multipliers were implemented but game damage is integer-based (1-2 damage), making multipliers produce invalid values (e.g., 0.5 damage).

### Solution
Remove damage modification entirely, keep only speed modifications:
```lua
EasyMode.Config = {
    ENEMY_SPEED_FACTOR = 0.4,        -- 60% reduction
    BOSS_SPEED_FACTOR = 0.7,         -- 30% reduction
    PROJECTILE_SPEED_FACTOR = 0.5,   -- 50% reduction
    -- Damage modifiers removed (incompatible with integer damage)
}
```

---

## 10. Debug Logging Best Practices

### Issue
Excessive debug logging (every frame, every entity) floods the console and makes it difficult to identify real issues.

### Solution
1. Remove per-frame/per-entity debug logs in production
2. Keep only initialization and error logs
3. Use conditional logging for development:
```lua
local DEBUG_MODE = false  -- Set to true for development

if DEBUG_MODE then
    print(string.format("[DEBUG] Entity speed: %.2f", speed))
end
```

---

## Summary of Key Learnings

1. **Always use the mod table directly** - Don't assume `Mod` is available
2. **Use MC_POST_UPDATE with Isaac.GetRoomEntities()** - Most reliable for entity scanning
3. **Use `value ~= false` instead of truthy checks** - Handles Lua's nil behavior
4. **Use entity:ToNPC() for NPC detection** - More reliable than IsActiveEnemy()
5. **Use English for all output** - Console doesn't support UTF-8 Chinese
6. **Single file structure** - require() has limitations
7. **Remove debug logging** - Keep only essential output
8. **Projectile speed factors need testing** - Too low causes projectiles to stall
9. **EntityBomb has SetExplosionCountdown()** - Use to extend bomb explosion time

---

## 11. Projectile Speed Adjustment

### Problem
Initial projectile speed factor of 0.5 (50% reduction) caused enemy projectiles to nearly stop moving, making them ineffective and breaking game mechanics.

### Investigation
- Projectiles with very low speed appear to "hover" in place
- This breaks enemy attack patterns and game balance
- The game expects projectiles to travel at certain speeds to be dodgeable

### Solution
Adjusted speed factors to be less aggressive:
```lua
PROJECTILE_SPEED_FACTOR = 0.7,   -- 30% reduction instead of 50%
TEAR_SPEED_FACTOR = 0.7,         -- 30% reduction instead of 50%
ROCK_WAVE_SPEED_FACTOR = 0.6,    -- 40% reduction for heavier projectiles
```

### Best Practices
- Test speed factors in-game to find the right balance
- Consider different factors for different projectile types
- Lighter projectiles (tears) can be slowed more than heavy ones (rocks)
- Avoid speed factors below 0.6 for standard projectiles

---

## 12. Bomb Explosion Time Extension

### Problem
Need to extend the time before enemy bombs explode to give players more reaction time.

### EntityBomb API
The `EntityBomb` class provides methods to modify bomb behavior:

```lua
-- Get bomb entity
local bomb = entity:ToBomb()
if bomb then
    -- Get current explosion countdown
    local currentCountdown = bomb.ExplosionCountdown  -- int, read-only property

    -- Set new explosion countdown (void function)
    bomb:SetExplosionCountdown(int Countdown)
end
```

### EntityBomb Properties
| Property | Type | Description |
|----------|------|-------------|
| ExplosionCountdown | int | Time until explosion (frames) |
| ExplosionDamage | float | Damage of the explosion |
| Flags | int | Behavior flags (uses TearFlags) |
| IsFetus | boolean | Is this a fetus bomb? |
| RadiusMultiplier | float | Explosion radius multiplier |

### Solution
Use `SetExplosionCountdown()` to extend explosion time:
```lua
local bomb = entity:ToBomb()
if bomb and not processedBombs[bomb] then
    local currentCountdown = bomb.ExplosionCountdown
    if currentCountdown and currentCountdown > 0 then
        local newCountdown = currentCountdown * 1.5  -- 50% longer
        bomb:SetExplosionCountdown(math.floor(newCountdown))
        processedBombs[bomb] = true
    end
end
```

### Important Notes
- Each bomb should only have its countdown modified once
- Use a cache (weak table) to track processed bombs
- The countdown is in frames, not seconds (60 frames = 1 second)
- Be careful not to extend too much or bombs become trivial

---

## 13. Rock/Wave Projectile Handling

### Problem
Spiders (EntityType.ENTITY_SPIDER = 85) and other enemies spawn rock projectiles that need different speed handling.

### Rock Projectile Detection
Rock projectiles are EntityType.ENTITY_PROJECTILE with specific characteristics:

```lua
local function isRockProjectile(entity)
    if entity.Type ~= EntityType.ENTITY_PROJECTILE then
        return false
    end
    
    -- Check for rock variant
    local variant = entity.Variant
    if variant == ProjectileVariant.PROJECTILE_ROCK then
        return true
    end
    
    -- Alternative: Check projectile properties
    local projectile = entity:ToProjectile()
    if projectile then
        -- Rock projectiles may have different damage/height values
        return true  -- Heuristic approach
    end
    
    return false
end
```

### ProjectileVariant Constants
```lua
ProjectileVariant.PROJECTILE_BLOOD    -- 0
ProjectileVariant.PROJECTILE_TEAR     -- 1
ProjectileVariant.PROJECTILE_ROCK     -- 2
ProjectileVariant.PROJECTILE_SPIRAL   -- 3
-- etc.
```

### Solution
Apply different speed factors based on projectile type:
```lua
if entity.Type == EntityType.ENTITY_PROJECTILE then
    local factor = EasyMode.Config.PROJECTILE_SPEED_FACTOR
    
    if isRockProjectile(entity) then
        factor = EasyMode.Config.ROCK_WAVE_SPEED_FACTOR
    end
    
    entity.Velocity = direction * (speed * factor)
end
```

---

## References

- [Binding of Isaac: Repentance Modding Wiki](https://moddingofisaac.com/)
- [Isaac API Documentation](https://wofsauge.github.io/IsaacDocs/)
- [Lua 5.1 Reference Manual](https://www.lua.org/manual/5.1/)
