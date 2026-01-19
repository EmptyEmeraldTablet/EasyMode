-- Easy Mode Mod for The Binding of Isaac: Repentance
-- This mod reduces game difficulty by slowing down enemies and projectiles
-- Does not affect player attributes

local EasyMode = RegisterMod("Easy Mode", 1)

-- ============================================================================
-- Configuration
-- ============================================================================

EasyMode.Config = {
    ENEMY_SPEED_FACTOR = 0.4,        -- Enemy move speed (0.4 = 60% reduction)
    BOSS_SPEED_FACTOR = 0.7,         -- Boss move speed (0.7 = 30% reduction)
    PROJECTILE_SPEED_FACTOR = 0.5,   -- Enemy projectile speed (50% reduction)
    TEAR_SPEED_FACTOR = 0.5,         -- Enemy tear speed (50% reduction)
    ATTACK_COOLDOWN_MULTIPLIER = 1.5, -- Attack cooldown multiplier
    EXCLUDE_FRIENDLY = true,         -- Exclude friendly units
    EXCLUDE_FAMILIARS = true,        -- Exclude familiars
    ENABLE_ATTACK_SLOWDOWN = false   -- Enable attack slowdown (experimental)
}

-- ============================================================================
-- Cached entity processing for performance
-- ============================================================================

local processedEntities = setmetatable({}, {__mode = "k"})
local lastLoggedFrame = 0

-- ============================================================================
-- Entity type check functions
-- ============================================================================

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

-- ============================================================================
-- Main update callback - process all entities each frame
-- ============================================================================

local function onPostUpdate()
    local entities = Isaac.GetRoomEntities()
    
    for _, entity in ipairs(entities) do
        -- Process enemies
        local npc = entity:ToNPC()
        if npc and (entity.Valid ~= false) then
            local etype = entity.Type
            -- Skip if not a valid enemy type
            if etype >= 10 and etype ~= 1000 then
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
        end

        -- Process enemy projectiles
        if entity.Type == EntityType.ENTITY_PROJECTILE and (entity.Valid ~= false) then
            local velocity = entity.Velocity
            local speed = velocity:Length()
            
            -- Skip zero-speed projectiles
            if speed >= 0.1 then
                local factor = EasyMode.Config.PROJECTILE_SPEED_FACTOR
                local direction = velocity:Normalized()
                entity.Velocity = direction * (speed * factor)
            end
        end
    end
end

-- ============================================================================
-- Mod Callbacks
-- ============================================================================

function EasyMode:onGameStarted()
    processedEntities = {}
    print("[EasyMode] Mod loaded - game difficulty reduced")
    print(string.format("[EasyMode] Enemy speed: %.0f%%, Projectile speed: %.0f%%",
        EasyMode.Config.ENEMY_SPEED_FACTOR * 100,
        EasyMode.Config.PROJECTILE_SPEED_FACTOR * 100))
end

function EasyMode:onGameEnded()
    print("[EasyMode] Game ended")
end

function EasyMode:onPreGameExit(shouldSave)
    processedEntities = {}
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
