-- Easy Mode Mod for The Binding of Isaac: Repentance
-- This mod reduces game difficulty by slowing down enemies and projectiles
-- Does not affect player attributes

local EasyMode = RegisterMod("Easy Mode", 1)

-- ============================================================================
-- Configuration
-- ============================================================================

EasyMode.Config = {
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

-- ============================================================================
-- Cached entity processing for performance
-- ============================================================================

local processedEntities = setmetatable({}, {__mode = "k"})
local processedBombs = setmetatable({}, {__mode = "k"})

-- ============================================================================
-- Automatic range compensation helper
-- ============================================================================

local function applyRangeCompensation(entity, projectile, speedFactor)
    -- Automatically calculate compensation to maintain range
    -- Range = Speed × FlightTime
    -- FlightTime ≈ Height / |FallingSpeed|
    -- To maintain range when speed is reduced by factor, we need to:
    -- 1. Increase Height magnitude (more negative)
    -- 2. Decrease FallingSpeed magnitude (closer to 0)
    -- This extends flight time proportionally
    
    if not speedFactor or speedFactor >= 1.0 then
        return -- No compensation needed for non-slowed entities
    end
    
    -- Calculate compensation factor (inverse of speed reduction)
    local compensation = 1.0 / speedFactor
    
    -- Apply Height compensation (make it more negative)
    if entity.Height then
        entity.Height = entity.Height * compensation
    end
    
    -- Apply FallingSpeed compensation (make it closer to 0, slower fall)
    if projectile then
        if projectile.FallingSpeed then
            projectile.FallingSpeed = projectile.FallingSpeed * compensation
        end
        if projectile.FallingAccel then
            projectile.FallingAccel = projectile.FallingAccel * compensation
        end
    end
end

local function isEnemyNPC(entity)
    -- Check if entity is an enemy NPC
    if not entity then return false end
    
    -- Try to convert to NPC
    local npc = entity:ToNPC()
    if not npc then return false end
    
    -- Skip if not a valid enemy type (Types 10-999 are enemies, 1000 is effect)
    local etype = entity.Type
    if etype < 10 or etype == 1000 then return false end
    
    -- Skip dead entities
    if npc:IsDead() then return false end
    
    return true
end

local function isEnemyProjectile(entity)
    -- Check if it's an enemy projectile
    if not entity or not entity.Type then
        return false
    end

    -- Check projectile type
    if entity.Type == EntityType.ENTITY_PROJECTILE then
        return true
    end

    -- Check tear type - player tears have SpawnerType == ENTITY_PLAYER
    if entity.Type == EntityType.ENTITY_TEAR then
        if entity.SpawnerType ~= EntityType.ENTITY_PLAYER then
            return true  -- Enemy tear
        end
    end

    return false
end

-- Check if entity is a rock projectile (spawned by spiders)
local function isRockProjectile(entity)
    if entity.Type ~= EntityType.ENTITY_PROJECTILE then
        return false
    end
    
    -- Rock projectiles from spiders have specific variants
    -- Variant 1 is typically the rock projectile
    local variant = entity.Variant
    
    -- Rock projectiles are usually Variant 1 or have specific tear flags
    -- We identify them by checking if they're not blood/special projectiles
    if variant == ProjectileVariant.PROJECTILE_ROCK then
        return true
    end
    
    -- Alternative check: rocks have high mass/damage characteristics
    local projectile = entity:ToProjectile()
    if projectile then
        -- Rock projectiles often have different damage values
        -- This is a heuristic approach
        return true
    end
    
    return false
end

-- ============================================================================
-- Main update callback - process all entities each frame
-- ============================================================================

local function onPostUpdate()
    local entities = Isaac.GetRoomEntities()
    
    for _, entity in ipairs(entities) do
        if entity.Valid == false then
            goto continue
        end
        
        local etype = entity.Type
        
        -- ========================================
        -- Process enemies
        -- ========================================
        local npc = entity:ToNPC()
        if npc and etype >= 10 and etype ~= 1000 then
            local velocity = npc.Velocity
            local speed = velocity:Length()
            
            -- Skip stationary entities
            if speed >= 0.5 then
                -- Apply speed reduction
                local factor = EasyMode.Config.ENEMY_SPEED_FACTOR
                if npc:IsBoss() then
                    factor = EasyMode.Config.BOSS_SPEED_FACTOR
                end
                
                npc.Velocity = velocity * factor
            end
        end
        
        -- ========================================
        -- Process enemy projectiles (tears, rocks, etc.)
        -- ========================================
        if etype == EntityType.ENTITY_PROJECTILE then
            local velocity = entity.Velocity
            local speed = velocity:Length()
            
            -- Skip zero-speed projectiles
            if speed >= 0.1 then
                local factor = EasyMode.Config.PROJECTILE_SPEED_FACTOR
                
                -- Check if it's a rock/wave projectile for different factor
                if isRockProjectile(entity) then
                    factor = EasyMode.Config.ROCK_WAVE_SPEED_FACTOR
                end
                
                local direction = velocity:Normalized()
                entity.Velocity = direction * (speed * factor)
                
                -- Automatic range compensation based on speed factor
                local projectile = entity:ToProjectile()
                applyRangeCompensation(entity, projectile, factor)
            end
        end
        
        -- ========================================
        -- Process enemy tears
        -- ========================================
        if etype == EntityType.ENTITY_TEAR then
            -- Skip player tears
            if entity.SpawnerType ~= EntityType.ENTITY_PLAYER then
                local velocity = entity.Velocity
                local speed = velocity:Length()
                
                if speed >= 0.1 then
                    local factor = EasyMode.Config.TEAR_SPEED_FACTOR
                    local direction = velocity:Normalized()
                    entity.Velocity = direction * (speed * factor)
                    
                    -- Automatic range compensation based on speed factor
                    local tear = entity:ToTear()
                    applyRangeCompensation(entity, tear, factor)
                end
            end
        end
        
        -- ========================================
        -- Process enemy bombs - extend explosion time
        -- ========================================
        if etype == EntityType.ENTITY_BOMB then
            local bomb = entity:ToBomb()
            if bomb and not processedBombs[bomb] then
                -- Get current countdown
                local currentCountdown = bomb.ExplosionCountdown
                
                if currentCountdown and currentCountdown > 0 then
                    -- Extend explosion time by multiplier
                    local newCountdown = currentCountdown * EasyMode.Config.BOMB_EXPLOSION_DELAY_MULTIPLIER
                    bomb:SetExplosionCountdown(math.floor(newCountdown))
                    processedBombs[bomb] = true
                end
            end
        end
        
        ::continue::
    end
    
    -- Clean up processed bombs that are no longer valid
    for bomb, _ in pairs(processedBombs) do
        if not bomb or not bomb.Valid then
            processedBombs[bomb] = nil
        end
    end
end

-- ============================================================================
-- Mod Callbacks
-- ============================================================================

function EasyMode:onGameStarted()
    processedEntities = {}
    processedBombs = {}
    print("[EasyMode] Mod loaded - game difficulty reduced")
    print(string.format("[EasyMode] Enemy: %.0f%%, Projectile: %.0f%%, Tear: %.0f%%, Bomb: %.0f%% time",
        EasyMode.Config.ENEMY_SPEED_FACTOR * 100,
        EasyMode.Config.PROJECTILE_SPEED_FACTOR * 100,
        EasyMode.Config.TEAR_SPEED_FACTOR * 100,
        EasyMode.Config.BOMB_EXPLOSION_DELAY_MULTIPLIER * 100))
    print("[EasyMode] Automatic range compensation enabled")
end

function EasyMode:onGameEnded()
    print("[EasyMode] Game ended")
end

function EasyMode:onPreGameExit(shouldSave)
    processedEntities = {}
    processedBombs = {}
end

-- Register mod callbacks
EasyMode:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, EasyMode.onGameStarted)
EasyMode:AddCallback(ModCallbacks.MC_POST_GAME_END, EasyMode.onGameEnded)
EasyMode:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, EasyMode.onPreGameExit)

-- ============================================================================
-- Register game callbacks
-- ============================================================================

Isaac.AddCallback(EasyMode, ModCallbacks.MC_POST_UPDATE, onPostUpdate, 0)

return EasyMode
