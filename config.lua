-- Easy Mode Mod Configuration
-- Modify these values to adjust difficulty
-- Your changes to this file will be preserved and won't cause git merge conflicts

return {
    ENEMY_SPEED_FACTOR = 0.4,              -- Enemy move speed (0.4 = 60% reduction)
    BOSS_SPEED_FACTOR = 0.7,               -- Boss move speed (0.7 = 30% reduction)
    PROJECTILE_SPEED_FACTOR = 0.7,         -- Enemy projectile speed (0.7 = 30% reduction)
    TEAR_SPEED_FACTOR = 0.7,               -- Enemy tear speed (0.7 = 30% reduction)
    ROCK_WAVE_SPEED_FACTOR = 0.6,          -- Rock/Wave projectile speed (0.6 = 40% reduction)
    BOMB_EXPLOSION_DELAY_MULTIPLIER = 1.5, -- Extend bomb explosion time (1.5x)
    ATTACK_COOLDOWN_MULTIPLIER = 1.5,      -- Attack cooldown multiplier
    EXCLUDE_FRIENDLY = true,               -- Exclude friendly units
    EXCLUDE_FAMILIARS = true,              -- Exclude familiars
    ENABLE_ATTACK_SLOWDOWN = false         -- Enable attack slowdown (experimental)
}
