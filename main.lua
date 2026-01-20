-- Easy Mode Mod for The Binding of Isaac: Repentance
-- This mod reduces game difficulty by slowing down enemies and projectiles
-- Does not affect player attributes

-- Load configuration (can be overridden by user config.lua)
local EasyMode = RegisterMod("Easy Mode", 1)

-- Try to load user config, fall back to defaults
local success, userConfig = pcall(require, "config")

-- Debug: Print config loading status
local configLoaded = false
if success and userConfig and type(userConfig) == "table" then
    Config = userConfig
    configLoaded = true
else
    Config = {
        ENEMY_SPEED_FACTOR = 0.4,
        BOSS_SPEED_FACTOR = 0.7,
        PROJECTILE_SPEED_FACTOR = 0.7,
        TEAR_SPEED_FACTOR = 0.7,
        ROCK_WAVE_SPEED_FACTOR = 0.6,
        BOMB_EXPLOSION_DELAY_MULTIPLIER = 1.5,
        ATTACK_COOLDOWN_MULTIPLIER = 1.5,
        EXCLUDE_FRIENDLY = true,
        EXCLUDE_FAMILIARS = true,
        ENABLE_ATTACK_SLOWDOWN = false
    }
end

-- ============================================================================
-- Cached entity processing for performance
-- ============================================================================

local processedProjectiles = setmetatable({}, {__mode = "k"})
local processedBombs = setmetatable({}, {__mode = "k"})

-- ============================================================================
-- Entity type check functions
-- ============================================================================

local function isRockProjectile(entity)
    if entity.Type ~= EntityType.ENTITY_PROJECTILE then
        return false
    end
    
    -- Rock projectiles from spiders have specific variants
    -- Variant 1 (PROJECTILE_ROCK) is the rock projectile
    local variant = entity.Variant
    
    -- Only return true for actual rock projectiles
    if variant == ProjectileVariant.PROJECTILE_ROCK then
        return true
    end
    
    -- Other projectile variants are NOT rock projectiles
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
        local spawner = entity.SpawnerType
        
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
                local factor = Config.ENEMY_SPEED_FACTOR
                if npc:IsBoss() then
                    factor = Config.BOSS_SPEED_FACTOR
                end
                
                npc.Velocity = velocity * factor
            end
        end
        
        -- ========================================
        -- Process enemy projectiles (tears, rocks, etc.)
        -- ========================================
        if etype == EntityType.ENTITY_PROJECTILE then
            -- Skip if already processed this frame
            if processedProjectiles[entity] then
                goto continue
            end
            
            local velocity = entity.Velocity
            local speed = velocity:Length()
            
            -- Skip zero-speed projectiles
            if speed >= 0.1 then
                local factor = Config.PROJECTILE_SPEED_FACTOR
                
                -- Check if it's a rock/wave projectile for different factor
                if isRockProjectile(entity) then
                    factor = Config.ROCK_WAVE_SPEED_FACTOR
                end
                
                local direction = velocity:Normalized()
                entity.Velocity = direction * (speed * factor)
                
                -- Mark as processed
                processedProjectiles[entity] = true
            end
        end
        
        -- ========================================
        -- Process enemy tears
        -- ========================================
        if etype == EntityType.ENTITY_TEAR then
            -- Skip player tears
            if spawner ~= EntityType.ENTITY_PLAYER then
                local velocity = entity.Velocity
                local speed = velocity:Length()
                
                if speed >= 0.1 then
                    local factor = Config.TEAR_SPEED_FACTOR
                    local direction = velocity:Normalized()
                    entity.Velocity = direction * (speed * factor)
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
                    local newCountdown = currentCountdown * Config.BOMB_EXPLOSION_DELAY_MULTIPLIER
                    bomb:SetExplosionCountdown(math.floor(newCountdown))
                    processedBombs[bomb] = true
                end
            end
        end
        
        ::continue::
    end
    
    -- Clean up processed projectiles and bombs that are no longer valid
    for proj, _ in pairs(processedProjectiles) do
        if not proj or not proj.Valid then
            processedProjectiles[proj] = nil
        end
    end
    for bomb, _ in pairs(processedBombs) do
        if not bomb or not bomb.Valid then
            processedBombs[bomb] = nil
        end
    end
end

-- ============================================================================
-- Mod Callbacks
-- ============================================================================
-- Mod Callbacks
-- ============================================================================

function EasyMode:onGameStarted()
    processedProjectiles = {}
    processedBombs = {}
    print("[EasyMode] Mod loaded - game difficulty reduced")
    print(string.format("[EasyMode] Enemy: %.0f%%, Projectile: %.0f%%, Tear: %.0f%%, Rock: %.0f%%",
        Config.ENEMY_SPEED_FACTOR * 100,
        Config.PROJECTILE_SPEED_FACTOR * 100,
        Config.TEAR_SPEED_FACTOR * 100,
        Config.ROCK_WAVE_SPEED_FACTOR * 100))
    if configLoaded then
        print("[EasyMode] Config: LOADED FROM FILE")
    else
        print("[EasyMode] Config: USING DEFAULTS (file not found or invalid)")
    end
    if Config.TEAR_SPEED_FACTOR >= 1.0 and Config.PROJECTILE_SPEED_FACTOR >= 1.0 then
        print("[EasyMode] NOTE: Projectile/tear speed is 100%% (no slowdown)")
    end
    print("[EasyMode] Range compensation: DISABLED")
end

function EasyMode:onGameEnded()
    print("[EasyMode] Game ended")
end

function EasyMode:onPreGameExit(shouldSave)
    processedProjectiles = {}
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
