-- Easy Mode Mod for The Binding of Isaac: Repentance
-- This mod reduces game difficulty by slowing down enemies and projectiles
-- Does not affect player attributes

local EasyMode = RegisterMod("Easy Mode", 1)

-- ============================================================================
-- 配置
-- ============================================================================

EasyMode.Config = {
    ENEMY_SPEED_FACTOR = 0.6,        -- 敌人移动速度 (0.6 = 降低40%)
    BOSS_SPEED_FACTOR = 0.85,        -- Boss移动速度 (0.85 = 轻微降低)
    PROJECTILE_SPEED_FACTOR = 0.6,   -- 敌对投射物速度
    TEAR_SPEED_FACTOR = 0.6,         -- 敌对眼泪速度
    ATTACK_COOLDOWN_MULTIPLIER = 1.5, -- 攻击冷却增加倍数
    EXCLUDE_FRIENDLY = true,         -- 豁免友好单位
    EXCLUDE_FAMILIARS = true,        -- 豁免跟随物
    ENABLE_ATTACK_SLOWDOWN = false   -- 是否启用攻击减速（实验性功能）
}

-- ============================================================================
-- 缓存已处理的实体以提高性能
-- ============================================================================

local processedEntities = setmetatable({}, {__mode = "k"})
local projectileData = setmetatable({}, {__mode = "k"})

-- ============================================================================
-- 实体类型检查函数
-- ============================================================================

local function isNPCEntity(entity)
    -- 检查是否是NPC实体（敌人）
    -- 实体ID 10-999 是敌人，1000是特效，1是玩家
    if not entity then return false end
    local etype = entity.Type
    return etype >= 10 and etype ~= 1000
end

local function isEnemyProjectile(entity)
    -- 检查是否是敌对投射物
    if not entity or not entity.Type then
        return false
    end

    -- 检查发射者类型
    if entity.SpawnerType then
        if entity.SpawnerType >= 10 and entity.SpawnerType ~= 1000 then
            return true
        end
    end

    -- 检查特殊标志
    if entity.HasProjectileFlags and entity:HasProjectileFlags(ProjectileFlags.CANT_HIT_PLAYER) then
        return true
    end

    -- 玩家眼泪是Type 2，但SpawnerType应该是1（玩家）
    if entity.Type == EntityType.ENTITY_TEAR then
        if entity.SpawnerType == EntityType.ENTITY_PLAYER then
            return false  -- 玩家眼泪
        end
        if entity.SpawnerType and entity.SpawnerType >= 10 then
            return true   -- 敌人眼泪
        end
    end

    return false
end

local function isFriendlyOrFamiliar(entity)
    -- 检查是否是友好单位或跟随物
    if not entity then return false end

    -- 检查友好标志
    if EasyMode.Config.EXCLUDE_FRIENDLY and entity:HasEntityFlags(EntityFlag.FLAG_FRIENDLY) then
        return true
    end

    -- 检查跟随物
    if EasyMode.Config.EXCLUDE_FAMILIARS and entity.Type == EntityType.ENTITY_FAMILIAR then
        return true
    end

    return false
end

-- ============================================================================
-- 主回调函数
-- ============================================================================

local function onNPCUpdate(npc)
    -- 检查 npc 是否存在
    if not npc then return end

    local npcType = npc.Type
    local npcVariant = npc.Variant
    print(string.format("[DEBUG] onNPCUpdate: Type=%d, Variant=%d", npcType or -1, npcVariant or -1))

    -- 只处理敌人实体
    if not isNPCEntity(npc) then
        print("[DEBUG] Not NPC entity (Type < 10 or Type == 1000), skipping")
        return
    end

    -- 豁免友好单位和跟随物
    if isFriendlyOrFamiliar(npc) then
        print("[DEBUG] Friendly/familiar entity, skipping")
        return
    end

    -- 忽略已死亡的实体
    if npc:IsDead() then
        print("[DEBUG] Entity is dead, skipping")
        return
    end

    local velocity = npc.Velocity
    local speed = velocity:Length()
    print(string.format("[DEBUG] Entity speed before: %.2f", speed))

    -- 忽略静止或几乎静止的实体
    if speed < 0.5 then
        print("[DEBUG] Speed too low (< 0.5), skipping")
        return
    end

    -- 根据实体类型选择减速因子
    local factor = EasyMode.Config.ENEMY_SPEED_FACTOR
    if npc:IsBoss() then
        factor = EasyMode.Config.BOSS_SPEED_FACTOR
        print("[DEBUG] Entity is Boss, using BOSS_SPEED_FACTOR")
    else
        print(string.format("[DEBUG] Entity is normal enemy, using ENEMY_SPEED_FACTOR: %.2f", factor))
    end

    -- 应用速度减速
    npc.Velocity = velocity * factor
    print(string.format("[DEBUG] Applied factor %.2f, new velocity: (%.2f, %.2f)", factor, npc.Velocity.X, npc.Velocity.Y))

    -- 记录处理过的实体
    processedEntities[npc] = true
end

local function onProjectileUpdate(projectile)
    -- 检查是否是敌对投射物
    if not isEnemyProjectile(projectile) then
        return
    end

    local velocity = projectile.Velocity
    local speed = velocity:Length()

    print(string.format("[DEBUG] Projectile: Type=%d, SpawnerType=%d, speed=%.2f", 
        projectile.Type or -1, projectile.SpawnerType or -1, speed))

    -- 忽略速度为0的投射物
    if speed < 0.1 then
        return
    end

    -- 应用速度减速
    local factor = EasyMode.Config.PROJECTILE_SPEED_FACTOR
    local newSpeed = speed * factor

    -- 保持方向不变
    local direction = velocity:Normalized()
    projectile.Velocity = direction * newSpeed

    print(string.format("[DEBUG] Projectile speed: %.2f -> %.2f (factor %.2f)", speed, newSpeed, factor))

    -- 调整射程：速度降低后，增加存活时间来保持相同射程
    -- 射程 = 速度 × 时间
    -- 新时间 = 旧时间 / factor
    if projectile.Lifetime and projectile.Lifetime > 0 then
        -- 使用自定义数据存储调整后的剩余时间
        if not projectileData[projectile] then
            projectileData[projectile] = {
                adjustedLifetime = projectile.Lifetime,
                originalSpeed = speed
            }
            print(string.format("[DEBUG] Projectile Lifetime: %d, adjusting", projectile.Lifetime))
        end

        -- 调整剩余存活时间
        local data = projectileData[projectile]
        if data.adjustedLifetime > 0 then
            -- 逐渐调整，保持平滑过渡
            data.adjustedLifetime = data.adjustedLifetime - 1
            if data.adjustedLifetime <= 0 then
                -- 移除投射物
                projectile:Remove()
            end
        end
    end

    -- 调整MaxDistance（如果存在）
    if projectile.MaxDistance and projectile.MaxDistance > 0 then
        local data = projectileData[projectile]
        if data and data.originalSpeed > 0 then
            -- 根据原始速度比例调整最大距离
            projectile.MaxDistance = data.originalSpeed * data.adjustedLifetime / 60
        end
    end
end

local function onTearUpdate(tear)
    -- 检查 tear 是否存在
    if not tear then return end

    local spawnerType = tear.SpawnerType
    print(string.format("[DEBUG] onTearUpdate: Type=%d, SpawnerType=%d", tear.Type or -1, spawnerType or -1))

    -- 检查是否是敌对眼泪
    if spawnerType == EntityType.ENTITY_PLAYER then
        print("[DEBUG] Player tear, skipping")
        return  -- Player tear, skip
    end

    if spawnerType and spawnerType >= 10 then
        local oldVelocity = tear.Velocity
        tear.Velocity = oldVelocity * EasyMode.Config.TEAR_SPEED_FACTOR
        print(string.format("[DEBUG] Enemy tear slowed: (%.2f, %.2f) -> (%.2f, %.2f)",
            oldVelocity.X, oldVelocity.Y, tear.Velocity.X, tear.Velocity.Y))
    else
        print(string.format("[DEBUG] Tear SpawnerType=%d not enemy, skipping", spawnerType or -1))
    end
end

local function onRoomUpdate()
    -- Room-level update logic (no-op for now)
end

-- ============================================================================
-- Mod Callbacks
-- ============================================================================
-- Mod Callbacks
-- ============================================================================

function EasyMode:onGameStarted()
    -- Clean cache on new game
    processedEntities = {}
    projectileData = {}
    print("[EasyMode] Mod loaded - game difficulty reduced")
    print(string.format("[EasyMode] Enemy speed: %.0f%%, Projectile speed: %.0f%%",
        EasyMode.Config.ENEMY_SPEED_FACTOR * 100,
        EasyMode.Config.PROJECTILE_SPEED_FACTOR * 100))
end

function EasyMode:onGameEnded()
    -- Cleanup is handled automatically when callbacks are removed
    print("[EasyMode] Game ended")
end

function EasyMode:onPreGameExit(shouldSave)
    print("[EasyMode] Game exiting, cleaning up...")
    -- Clear all cached data
    processedEntities = {}
    projectileData = {}
end

-- Register mod callbacks
EasyMode:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, EasyMode.onGameStarted)
EasyMode:AddCallback(ModCallbacks.MC_POST_GAME_END, EasyMode.onGameEnded)
EasyMode:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, EasyMode.onPreGameExit)

-- ============================================================================
-- Register game callbacks immediately (not in onGameStarted)
-- ============================================================================

-- Register NPC update callback
Isaac.AddCallback(EasyMode, ModCallbacks.MC_NPC_UPDATE, onNPCUpdate, 0)
print("[DEBUG] Registered MC_NPC_UPDATE")

-- Register projectile update callback
Isaac.AddCallback(EasyMode, ModCallbacks.MC_POST_PROJECTILE_UPDATE, onProjectileUpdate, 0)
print("[DEBUG] Registered MC_POST_PROJECTILE_UPDATE")

-- Register tear update callback
Isaac.AddCallback(EasyMode, ModCallbacks.MC_POST_TEAR_UPDATE, onTearUpdate, 0)
print("[DEBUG] Registered MC_POST_TEAR_UPDATE")

-- Register room update callback
Isaac.AddCallback(EasyMode, ModCallbacks.MC_POST_UPDATE, onRoomUpdate, 0)
print("[DEBUG] Registered MC_POST_UPDATE")

return EasyMode
