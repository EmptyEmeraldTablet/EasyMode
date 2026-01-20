# Easy Mode Mod Configuration Guide

## Introduction

Easy Mode Mod is a mod for The Binding of Isaac: Repentance that reduces game difficulty by slowing down enemy attributes.

## Configuration Files

| File | Description |
|------|-------------|
| `config.lua` | User configuration file (managed separately, no git conflicts) |
| `config.lua.example` | Default configuration template |
| `CONFIG.md` | Chinese documentation |
| `CONFIG.en.md` | This English documentation |

## Quick Start

### 1. Modify Configuration

Edit the `config.lua` file. Use a text editor like VS Code or Notepad++:

```lua
return {
    ENEMY_SPEED_FACTOR = 0.4,              -- Enemy move speed (0.4 = 60% reduction)
    BOSS_SPEED_FACTOR = 0.7,               -- Boss move speed (0.7 = 30% reduction)
    PROJECTILE_SPEED_FACTOR = 0.95,        -- Projectile speed (~5% reduction, ~19% range reduction)
    TEAR_SPEED_FACTOR = 0.95,              -- Tear speed (same as projectile)
    ROCK_WAVE_SPEED_FACTOR = 0.9,          -- Rock/Wave speed (~10% reduction, ~19% range reduction)
    BOMB_EXPLOSION_DELAY_MULTIPLIER = 1.5, -- Bomb explosion delay (1.5x)
    ATTACK_COOLDOWN_MULTIPLIER = 1.5,      -- Attack cooldown multiplier
    EXCLUDE_FRIENDLY = true,               -- Exclude friendly units
    EXCLUDE_FAMILIARS = true,              -- Exclude familiars
    ENABLE_ATTACK_SLOWDOWN = false         -- Enable attack slowdown (experimental)
}
```

### 2. Restart Game

After modifying `config.lua`, you need to **completely restart the game** (not just reload the mod).

## Physics: Range and Speed

### Parabolic Motion and Range

Projectiles follow a parabolic trajectory. The range formula is:

```
R = (v² × sin(2θ)) / g
```

**Key Discovery: Range is proportional to the square of velocity!**

| Speed Factor | Actual Speed | Expected Range | Range Reduction |
|-------------|--------------|----------------|-----------------|
| 1.0 | 100% | 100% | No reduction |
| 0.98 | 98% | **96%** | -4% |
| 0.95 | 95% | **90%** | -10% |
| 0.9 | 90% | **81%** | -19% |
| 0.85 | 85% | **72%** | -28% |
| 0.8 | 80% | **64%** | -36% |

**Examples:**
- Speed factor 0.95 → 5% speed reduction, but ~10% range reduction
- Speed factor 0.9 → 10% speed reduction, but ~19% range reduction

### Configuration Suggestions

Adjust based on desired difficulty:

| Difficulty | PROJECTILE/TEAR_SPEED | ROCK_WAVE_SPEED | Range Reduction |
|------------|----------------------|-----------------|-----------------|
| Light | 0.98 | 0.95 | ~4-10% |
| Medium | 0.95 | 0.9 | ~10-19% |
| Heavy | 0.9 | 0.85 | ~19-28% |

## Configuration Parameters

### Speed Control Parameters

#### ENEMY_SPEED_FACTOR
- **Default**: `0.4`
- **Description**: Movement speed factor for regular enemies (Type 10-999)
- **Effect**: Enemy movement speed reduced by 60%

#### BOSS_SPEED_FACTOR
- **Default**: `0.7`
- **Description**: Movement speed factor for Bosses
- **Effect**: Boss movement speed reduced by 30%
- **Note**: Some bosses may not slow down due to game mechanics

#### PROJECTILE_SPEED_FACTOR
- **Default**: `0.95`
- **Description**: Speed factor for enemy projectiles (Type 9, Spawner >= 10)
- **Effect**: ~5% speed reduction, ~10% range reduction
- **Physics**: Range proportional to speed squared

#### TEAR_SPEED_FACTOR
- **Default**: `0.95`
- **Description**: Speed factor for enemy tears (Type 2, Spawner != Player)
- **Effect**: Same as projectile
- **Note**: Enemy tears are actually Type 9 (ENTITY_PROJECTILE), distinguished by SpawnerType

#### ROCK_WAVE_SPEED_FACTOR
- **Default**: `0.9`
- **Description**: Speed factor for special projectiles (Stone Waves, Rocks, etc.)
- **Effect**: ~10% speed reduction, ~19% range reduction
- **Detection**: Only affects `ProjectileVariant.PROJECTILE_ROCK`

### Time Control Parameters

#### BOMB_EXPLOSION_DELAY_MULTIPLIER
- **Default**: `1.5`
- **Description**: Bomb explosion delay multiplier
- **Effect**: Bomb explosion time extended by 50%
- **Implementation**: Uses `EntityBomb:SetExplosionCountdown()`

#### ATTACK_COOLDOWN_MULTIPLIER
- **Default**: `1.5`
- **Description**: Enemy attack cooldown multiplier
- **Effect**: Enemy attack interval extended by 50% (experimental)

### Exclusion Parameters

#### EXCLUDE_FRIENDLY
- **Default**: `true`
- **Description**: Whether to exclude friendly units (charmed enemies)
- **Effect**: Charmed enemies won't be slowed

#### EXCLUDE_FAMILIARS
- **Default**: `true`
- **Description**: Whether to exclude familiars
- **Effect**: Player's familiars won't be affected

#### ENABLE_ATTACK_SLOWDOWN
- **Default**: `false`
- **Description**: Whether to enable attack slowdown (experimental)
- **Note**: This feature may be unstable

## Git Conflict Protection

`config.lua` uses Git's `skip-worktree` feature to protect your local changes from git merge conflicts.

### Benefits
- ✅ Your local configuration won't be overwritten when pulling updates
- ✅ You can modify settings anytime without affecting other users
- ✅ Perfect for personalized settings

### Committing Configuration Changes

If you want to commit your configuration changes:

```bash
# 1. Temporarily disable skip-worktree protection
git update-index --no-skip-worktree config.lua

# 2. Commit changes
git add config.lua
git commit -m "Update config with my settings"

# 3. Re-enable protection
git update-index --skip-worktree config.lua
```

### Resetting to Default Configuration

To reset to default configuration:

```bash
# 1. Temporarily disable protection
git update-index --no-skip-worktree config.lua

# 2. Reset from template
cp config.lua.example config.lua

# 3. Commit reset (optional)
git add config.lua
git commit -m "Reset config to defaults"

# 4. Re-enable protection
git update-index --skip-worktree config.lua
```

## Preset Configurations

### Light Difficulty Reduction (Recommended for Beginners)

```lua
return {
    ENEMY_SPEED_FACTOR = 0.5,
    BOSS_SPEED_FACTOR = 0.8,
    PROJECTILE_SPEED_FACTOR = 0.98,
    TEAR_SPEED_FACTOR = 0.98,
    ROCK_WAVE_SPEED_FACTOR = 0.95,
    BOMB_EXPLOSION_DELAY_MULTIPLIER = 1.2,
    ATTACK_COOLDOWN_MULTIPLIER = 1.2,
    EXCLUDE_FRIENDLY = true,
    EXCLUDE_FAMILIARS = true,
    ENABLE_ATTACK_SLOWDOWN = false
}
```

### Medium Difficulty Reduction (Recommended for Most Players)

```lua
return {
    ENEMY_SPEED_FACTOR = 0.4,
    BOSS_SPEED_FACTOR = 0.7,
    PROJECTILE_SPEED_FACTOR = 0.95,
    TEAR_SPEED_FACTOR = 0.95,
    ROCK_WAVE_SPEED_FACTOR = 0.9,
    BOMB_EXPLOSION_DELAY_MULTIPLIER = 1.5,
    ATTACK_COOLDOWN_MULTIPLIER = 1.5,
    EXCLUDE_FRIENDLY = true,
    EXCLUDE_FAMILIARS = true,
    ENABLE_ATTACK_SLOWDOWN = false
}
```

### Heavy Difficulty Reduction (Challenge Mode)

```lua
return {
    ENEMY_SPEED_FACTOR = 0.3,
    BOSS_SPEED_FACTOR = 0.6,
    PROJECTILE_SPEED_FACTOR = 0.9,
    TEAR_SPEED_FACTOR = 0.9,
    ROCK_WAVE_SPEED_FACTOR = 0.85,
    BOMB_EXPLOSION_DELAY_MULTIPLIER = 2.0,
    ATTACK_COOLDOWN_MULTIPLIER = 2.0,
    EXCLUDE_FRIENDLY = true,
    EXCLUDE_FAMILIARS = true,
    ENABLE_ATTACK_SLOWDOWN = false
}
```

## Supported Entity Types

| Entity Type | EntityType Value | SpawnerType | Processing |
|-------------|-----------------|-------------|------------|
| Regular Enemy | 10-999 | - | Uses ENEMY_SPEED_FACTOR |
| Boss | Special | - | Uses BOSS_SPEED_FACTOR |
| Enemy Projectile | 9 | >= 10 | Uses PROJECTILE_SPEED_FACTOR |
| Enemy Tear | 2 | >= 10 | Uses TEAR_SPEED_FACTOR |
| Player Tear | 2 | 1 | Not processed |
| Rock Projectile | 9 (Variant=1) | - | Uses ROCK_WAVE_SPEED_FACTOR |
| Bomb | 4 | - | Uses BOMB_EXPLOSION_DELAY_MULTIPLIER |

## FAQ

### Q: What do I need to do after modifying the config?

A: You need to **completely restart the game**, not just reload the mod.

### Q: Why is projectile range reduced more than expected?

A: Range is proportional to the square of speed. If speed factor is 0.9, range will be 0.81 (19% reduction).

### Q: Can I completely disable projectile slowdown?

A: Yes, set PROJECTILE_SPEED_FACTOR and TEAR_SPEED_FACTOR to 1.0.

### Q: Why isn't the Boss slowing down?

A: Some bosses have special movement logic that may not be affected by speed factors. This is a game mechanic limitation.

### Q: Configuration not working?

1. Make sure to completely restart the game
2. Check config.lua syntax (use an online Lua syntax checker)
3. Check if other mods are overriding your settings

## Technical Details

### How It Works

The mod scans all entities in the room every frame using the `MC_POST_UPDATE` callback:

1. Get all entities in room: `Isaac.GetRoomEntities()`
2. Detect entity type and apply appropriate slowdown
3. Use weak tables to cache processed entities and avoid duplicate processing

### Performance Optimization

- Each projectile is only processed once (tracked using `processedProjectiles`)
- Stationary entities are ignored (speed < 0.5)
- Entity type filtering for quick processing

## Related Files

- `main.lua` - Mod main logic
- `config.lua` - User configuration
- `config.lua.example` - Configuration template
- `README.md` - Mod readme
- `CONFIG.md` - Chinese configuration documentation
- `CONFIG.en.md` - This English documentation

## Advanced玩法: Challenge Yourself 🎮

### Want Higher Difficulty? No Problem!

This mod supports setting parameters **greater than 1.0** to achieve "Hard Mode" or even "Masochist Mode"!

```lua
return {
    ENEMY_SPEED_FACTOR = 1.5,              -- Enemies run faster than you!
    BOSS_SPEED_FACTOR = 2.0,               -- Boss moves at 2x normal speed!
    PROJECTILE_SPEED_FACTOR = 1.5,        -- Projectiles fly like bullets!
    BOMB_EXPLOSION_DELAY_MULTIPLIER = 0.5, -- Bombs explode faster!
}
```

### Effect Preview

| Parameter | Normal Value | Masochist Value | Effect |
|-----------|--------------|-----------------|--------|
| ENEMY_SPEED_FACTOR | 0.4 | 1.5 | Enemy speed increased by 275% |
| BOSS_SPEED_FACTOR | 0.7 | 2.0 | Boss speed increased by 186% |
| PROJECTILE_SPEED_FACTOR | 0.95 | 1.5 | Projectile speed increased by 58%, range increased by 125% |

### ⚠️ Friendly Reminder

> **This is not a warning, it's advice from the developer:**
>
> - Setting ENEMY_SPEED_FACTOR > 1 means enemies might run faster than you
> - PROJECTILE_SPEED_FACTOR > 1 makes projectiles fly farther and faster
> - You might need better dodge skills and faster reflexes
> - We don't guarantee you'll survive Chapter 1
> - Developer is not responsible for broken controllers, smashed keyboards, or wet monitors

### Achievement Unlocked

If you manage to complete the game with this config, please contact the developer:

```lua
ENEMY_SPEED_FACTOR = 3.0
BOSS_SPEED_FACTOR = 5.0
PROJECTILE_SPEED_FACTOR = 2.0
ATTACK_COOLDOWN_MULTIPLIER = 0.1  -- Shorter cooldown = More frequent attacks
```

**Good luck! Don't forget to buy extra tissues for your tears.** 🧻

---

## License

```
MIT License (MIT)
Copyright © 2026 Easy Mode Mod Contributors

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to
deal in the Software without restriction, including without limitation the
rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
sell copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS IN THE SOFTWARE.
```
