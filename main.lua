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

local function isActiveEnemy(entity)
    -- Use the game's built-in enemy detection
    if not entity then return false end
    return entity:IsActiveEnemy(false) and entity:IsVulnerableEnemy()
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

    -- Check tear type
    if entity.Type == EntityType.ENTITY_TEAR then
        -- Player tears have SpawnerType == ENTITY_PLAYER
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

    for _, entity in ipairs(entities) do
        if not entity or not entity.Valid then
            goto continue
        end

        -- Process enemies
        if isActiveEnemy(entity) then
            local npc = entity:ToNPC()
            if npc then
                enemyCount = enemyCount + 1
                print(string.format("[DEBUG] Found enemy #%d: Type=%d, Variant=%d", 
                    enemyCount, entity.Type, entity.Variant))

                -- Skip friendly/familiar
                if isFriendlyOrFamiliar(npc) then
                    print("[DEBUG] Skipping friendly/familiar")
                    goto continue
                end

                -- Skip dead entities
                if npc:IsDead() then
                    print("[DEBUG] Skipping dead entity")
                    goto continue
                end

                -- Get velocity
                local velocity = npc.Velocity
                local speed = velocity:Length()
                print(string.format("[DEBUG] Enemy speed before: %.2f", speed))

                -- Skip stationary entities
                if speed < 0.5 then
                    print("[DEBUG] Speed too low, skipping")
                    goto continue
                end

                -- Apply speed reduction
                local factor = EasyMode.Config.ENEMY_SPEED_FACTOR
                if npc:IsBoss() then
                    factor = EasyMode.Config.BOSS_SPEED_FACTOR
                    print("[DEBUG] Entity is Boss, using BOSS_SPEED_FACTOR")
                end

                npc.Velocity = velocity * factor
                print(string.format("[DEBUG] Applied factor %.2f, new velocity: (%.2f, %.2f)", 
                    factor, npc.Velocity.X, npc.Velocity.Y))

                processedEntities[npc] = true
            end
        end

        -- Process enemy projectiles
        if isEnemyProjectile(entity) then
            projectileCount = projectileCount + 1
            print(string.format("[DEBUG] Found enemy projectile #%d: Type=%d, SpawnerType=%d", 
                projectileCount, entity.Type, entity.SpawnerType or -1))

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

            print(string.format("[DEBUG] Projectile speed: %.2f -> %.2f (factor %.2f)", 
                speed, newSpeed, factor))
        end

        ::continue::
    end

    print(string.format("[DEBUG] Scan complete: %d enemies, %d enemy projectiles processed", 
        enemyCount, projectileCount))
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
