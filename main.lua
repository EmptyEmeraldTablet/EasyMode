-- Easy Mode Mod for The Binding of Isaac: Repentance
-- This mod reduces game difficulty by slowing down enemies and projectiles
-- Does not affect player attributes

local EasyMode = RegisterMod("Easy Mode", 1)

-- ============================================================================
-- Configuration
-- ============================================================================

EasyMode.Config = {
    ENEMY_SPEED_FACTOR = 0.6,        -- Enemy move speed (0.6 = 40% reduction)
    BOSS_SPEED_FACTOR = 0.85,        -- Boss move speed (0.85 = slight reduction)
    PROJECTILE_SPEED_FACTOR = 0.6,   -- Enemy projectile speed
    TEAR_SPEED_FACTOR = 0.6,         -- Enemy tear speed
    ATTACK_COOLDOWN_MULTIPLIER = 1.5, -- Attack cooldown multiplier
    EXCLUDE_FRIENDLY = true,         -- Exclude friendly units
    EXCLUDE_FAMILIARS = true,        -- Exclude familiars
    ENABLE_ATTACK_SLOWDOWN = false   -- Enable attack slowdown (experimental)
}

-- ============================================================================
-- Cached entity processing for performance
-- ============================================================================

local processedEntities = setmetatable({}, {__mode = "k"})
local projectileData = setmetatable({}, {__mode = "k"})

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

local function isFriendlyOrFamiliar(entity)
    -- Check if entity is friendly or familiar
    if not entity then return false end

    -- Check friendly flag
    if EasyMode.Config.EXCLUDE_FRIENDLY and entity:HasEntityFlags(EntityFlag.FLAG_FRIENDLY) then
        return true
    end

    -- Check familiar type
    if EasyMode.Config.EXCLUDE_FAMILIARS and entity.Type == EntityType.ENTITY_FAMILIAR then
        return true
    end

    return false
end

-- ============================================================================
-- Main update callback - process all entities each frame
-- ============================================================================

local function onPostUpdate()
    -- Get all entities in the current room
    local entities = Isaac.GetRoomEntities()
    print(string.format("[DEBUG] onPostUpdate: scanning %d entities", #entities))

    local enemyCount = 0
    local projectileCount = 0
    local npcCount = 0
    local projectileTypeCount = 0
    local tearTypeCount = 0
    local otherCount = 0

    for _, entity in ipairs(entities) do
        -- Debug: print all entities first
        local eType = entity.Type
        local eVariant = entity.Variant
        local eSubType = entity.SubType
        local eValid = entity.Valid
        local eIndex = entity.Index
        
        -- Try ToNPC
        local npc = entity:ToNPC()
        if npc then
            npcCount = npcCount + 1
            print(string.format("[DEBUG] Entity #%d: Type=%d, Variant=%d, SubType=%d, Valid=%s, ToNPC()=YES",
                npcCount + projectileTypeCount + tearTypeCount + otherCount + 1, eType, eVariant, eSubType, tostring(eValid)))
        elseif eType == EntityType.ENTITY_PROJECTILE then
            projectileTypeCount = projectileTypeCount + 1
            print(string.format("[DEBUG] Entity #%d: Type=%d (PROJECTILE), Variant=%d, SubType=%d, Valid=%s",
                npcCount + projectileTypeCount + tearTypeCount + otherCount + 1, eType, eVariant, eSubType, tostring(eValid)))
        elseif eType == EntityType.ENTITY_TEAR then
            tearTypeCount = tearTypeCount + 1
            print(string.format("[DEBUG] Entity #%d: Type=%d (TEAR), Variant=%d, SubType=%d, Valid=%s, SpawnerType=%d",
                npcCount + projectileTypeCount + tearTypeCount + otherCount + 1, eType, eVariant, eSubType, tostring(eValid), entity.SpawnerType or -1))
        else
            otherCount = otherCount + 1
            print(string.format("[DEBUG] Entity #%d: Type=%d, Variant=%d, SubType=%d, Valid=%s - OTHER",
                npcCount + projectileTypeCount + tearTypeCount + otherCount, eType, eVariant, eSubType, tostring(eValid)))
        end
        
        -- Process enemies
        if npc and eValid then
            enemyCount = enemyCount + 1
            
            -- Get velocity
            local velocity = npc.Velocity
            local speed = velocity:Length()
            print(string.format("[DEBUG] ENEMY #%d speed: %.2f", enemyCount, speed))

            -- Skip stationary entities
            if speed < 0.5 then
                print("[DEBUG] Speed too low, skipping")
                goto continue
            end

            -- Apply speed reduction
            local factor = EasyMode.Config.ENEMY_SPEED_FACTOR
            if npc:IsBoss() then
                factor = EasyMode.Config.BOSS_SPEED_FACTOR
            end

            npc.Velocity = velocity * factor
            print(string.format("[DEBUG] ENEMY #%d slowed: %.2f -> %.2f (factor %.2f)", 
                enemyCount, speed, speed * factor, factor))
        end

        -- Process enemy projectiles
        if eType == EntityType.ENTITY_PROJECTILE and eValid then
            projectileCount = projectileCount + 1
            
            local velocity = entity.Velocity
            local speed = velocity:Length()

            -- Skip zero-speed projectiles
            if speed < 0.1 then
                goto continue
            end

            -- Apply speed reduction
            local factor = EasyMode.Config.PROJECTILE_SPEED_FACTOR
            local newSpeed = speed * factor

            -- Maintain direction
            local direction = velocity:Normalized()
            entity.Velocity = direction * newSpeed

            print(string.format("[DEBUG] PROJECTILE #%d slowed: %.2f -> %.2f", 
                projectileCount, speed, newSpeed))
        end

        ::continue::
    end

    print(string.format("[DEBUG] Summary: %d total, NPC=%d, PROJECTILE=%d, TEAR=%d, OTHER=%d",
        #entities, npcCount, projectileTypeCount, tearTypeCount, otherCount))
    print(string.format("[DEBUG] Processed: %d enemies, %d enemy projectiles", enemyCount, projectileCount))
end

-- ============================================================================
-- Mod Callbacks
-- ============================================================================

function EasyMode:onGameStarted()
    -- Clear cache on new game
    processedEntities = {}
    projectileData = {}
    print("[EasyMode] Mod loaded - game difficulty reduced")
    print(string.format("[EasyMode] Enemy speed: %.0f%%, Projectile speed: %.0f%%",
        EasyMode.Config.ENEMY_SPEED_FACTOR * 100,
        EasyMode.Config.PROJECTILE_SPEED_FACTOR * 100))
end

function EasyMode:onGameEnded()
    print("[EasyMode] Game ended")
end

function EasyMode:onPreGameExit(shouldSave)
    print("[EasyMode] Game exiting, cleaning up...")
    processedEntities = {}
    projectileData = {}
end

-- Register mod callbacks
EasyMode:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, EasyMode.onGameStarted)
EasyMode:AddCallback(ModCallbacks.MC_POST_GAME_END, EasyMode.onGameEnded)
EasyMode:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, EasyMode.onPreGameExit)

-- ============================================================================
-- Register game callbacks
-- ============================================================================

-- Use MC_POST_UPDATE to scan all entities each frame
Isaac.AddCallback(EasyMode, ModCallbacks.MC_POST_UPDATE, onPostUpdate, 0)
print("[DEBUG] Registered MC_POST_UPDATE for entity scanning")

return EasyMode
