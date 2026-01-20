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

local processedEntities = setmetatable({}, {__mode = "k"})
local processedBombs = setmetatable({}, {__mode = "k"})

-- DEBUG: Track seen entity types (persist across frames, reset per room)
local seenEntityTypes = {}
local seenTearSpawners = {}

-- DEBUG: Track ALL entities for diagnosis
local allEntitiesThisFrame = {}

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
    
    -- DEBUG: Count entities per type for diagnosis
    local entityCounts = {}
    
    for _, entity in ipairs(entities) do
        if entity.Valid == false then
            goto continue
        end
        
        local etype = entity.Type
        local variant = entity.Variant
        local spawner = entity.SpawnerType
        
        -- DEBUG: Count entities
        if not entityCounts[etype] then
            entityCounts[etype] = 0
        end
        entityCounts[etype] = entityCounts[etype] + 1
        
        -- DEBUG: Track entity types (only print each type once)
        if not seenEntityTypes[etype] then
            seenEntityTypes[etype] = true
            local projectile = entity:ToProjectile()
            local tear = entity:ToTear()
            print(string.format("[EasyMode DEBUG] New entity: Type=%d, Variant=%d, Spawner=%d, IsProjectile=%s, IsTear=%s",
                etype, variant, spawner or -1, tostring(projectile ~= nil), tostring(tear ~= nil)))
        end
        
        -- DEBUG: Check for projectiles with non-player spawners
        if etype == EntityType.ENTITY_PROJECTILE and spawner and spawner >= 10 then
            if not seenTearSpawners[spawner] then
                seenTearSpawners[spawner] = true
                print(string.format("[EasyMode DEBUG] Enemy projectile detected: Type=%d, Variant=%d, Spawner=%d",
                    etype, variant, spawner))
            end
        end
        
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
            end
        end
        
        -- ========================================
        -- Process enemy tears
        -- ========================================
        if etype == EntityType.ENTITY_TEAR then
            -- DEBUG: Print tear spawner info once per spawner type
            local spawnerKey = spawner or 0
            if not seenTearSpawners[spawnerKey] then
                seenTearSpawners[spawnerKey] = true
                print(string.format("[EasyMode DEBUG] Tear found: Spawner=%d (Player=%d), IsEnemyTear=%s",
                    spawner, EntityType.ENTITY_PLAYER, tostring(spawner ~= EntityType.ENTITY_PLAYER)))
            end
            
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
    
    -- DEBUG: Print entity counts once per room
    if not seenEntityTypes["_counts_printed"] then
        seenEntityTypes["_counts_printed"] = true
        local countMsg = "[EasyMode DEBUG] Entity counts: "
        for etype, count in pairs(entityCounts) do
            countMsg = countMsg .. string.format("Type%d=%d ", etype, count)
        end
        print(countMsg)
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
-- Mod Callbacks
-- ============================================================================

function EasyMode:onGameStarted()
    processedEntities = {}
    processedBombs = {}
    seenEntityTypes = {}  -- Reset debug tracking for new room
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
