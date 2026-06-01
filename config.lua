-- Easy Mode Mod Configuration
-- Modify these values to adjust difficulty
-- Your changes to this file will be preserved and won't cause git merge conflicts

return {
    ENEMY_SPEED_FACTOR = 0.4,              -- Enemy move speed (0.4 = 60% reduction)
    BOSS_SPEED_FACTOR = 0.7,               -- Boss move speed (0.7 = 30% reduction)
    PROJECTILE_SPEED_FACTOR = 0.95,        -- Enemy projectile speed (~5% reduction)
    TEAR_SPEED_FACTOR = 0.95,              -- Enemy tear speed (~5% reduction)
    ROCK_WAVE_SPEED_FACTOR = 0.9,          -- Rock/Wave projectile speed (~10% reduction)
    BOMB_EXPLOSION_DELAY_MULTIPLIER = 1.5, -- Extend bomb explosion time (1.5x)
    EXCLUDE_FRIENDLY = true,               -- Exclude friendly units
    EXCLUDE_FAMILIARS = true               -- Exclude familiars
}
