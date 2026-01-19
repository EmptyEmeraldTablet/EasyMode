-- Easy Mode Mod for The Binding of Isaac: Repentance
-- 此模组通过降低敌人速度、投射物速度来降低游戏难度
-- 不影响玩家属性，伤害控制因游戏伤害为整数已移除

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
local callbacks = {}

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

    -- 只处理敌人实体
    if not isNPCEntity(npc) then
        return
    end

    -- 豁免友好单位和跟随物
    if isFriendlyOrFamiliar(npc) then
        return
    end

    -- 忽略已死亡的实体
    if npc:IsDead() then
        return
    end

    local velocity = npc.Velocity
    local speed = velocity:Length()

    -- 忽略静止或几乎静止的实体
    if speed < 0.5 then
        return
    end

    -- 根据实体类型选择减速因子
    local factor = EasyMode.Config.ENEMY_SPEED_FACTOR
    if npc:IsBoss() then
        factor = EasyMode.Config.BOSS_SPEED_FACTOR
    end

    -- 应用速度减速
    npc.Velocity = velocity * factor

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

    -- 检查是否是敌对眼泪
    if tear.SpawnerType == EntityType.ENTITY_PLAYER then
        return  -- 玩家眼泪，不处理
    end

    if tear.SpawnerType and tear.SpawnerType >= 10 then
        tear.Velocity = tear.Velocity * EasyMode.Config.TEAR_SPEED_FACTOR
    end
end

local function onRoomUpdate()
    -- 房间级别的更新逻辑
    -- 可以用于清理已移除的投射物数据
end

-- ============================================================================
-- 初始化和清理
-- ============================================================================

local function Init()
    -- 注册所有回调
    callbacks = {
        { ModCallbacks.MC_NPC_UPDATE, onNPCUpdate },
        { ModCallbacks.MC_POST_PROJECTILE_UPDATE, onProjectileUpdate },
        { ModCallbacks.MC_POST_TEAR_UPDATE, onTearUpdate },
        { ModCallbacks.MC_POST_UPDATE, onRoomUpdate }
    }

    for _, callback in ipairs(callbacks) do
        Isaac.AddCallback(Mod, callback[1], callback[2], 0)
    end

    -- 清理缓存
    processedEntities = {}
    projectileData = {}

    print("[EasyMode] 模组已加载 - 游戏难度已降低")
    print(string.format("[EasyMode] 敌人速度: %.0f%%, 投射物速度: %.0f%%",
        EasyMode.Config.ENEMY_SPEED_FACTOR * 100,
        EasyMode.Config.PROJECTILE_SPEED_FACTOR * 100))
end

local function Cleanup()
    -- 移除所有回调
    for _, callback in ipairs(callbacks or {}) do
        Isaac.RemoveCallback(Mod, callback[1], callback[2])
    end
    callbacks = {}

    -- 清理缓存
    processedEntities = {}
    projectileData = {}
end

-- ============================================================================
-- 模组回调
-- ============================================================================

function EasyMode:onGameStarted()
    Init()
end

function EasyMode:onGameEnded()
    Cleanup()
end

function EasyMode:onPreGameExit(shouldSave)
    -- 游戏退出前保存配置（如果需要持久化）
end

-- 调试功能：打印当前配置
function EasyMode:printConfig()
    print("=== Easy Mode 当前配置 ===")
    print(string.format("敌人速度因子: %.2f", EasyMode.Config.ENEMY_SPEED_FACTOR))
    print(string.format("Boss速度因子: %.2f", EasyMode.Config.BOSS_SPEED_FACTOR))
    print(string.format("投射物速度因子: %.2f", EasyMode.Config.PROJECTILE_SPEED_FACTOR))
    print(string.format("攻击冷却倍数: %.2f", EasyMode.Config.ATTACK_COOLDOWN_MULTIPLIER))
    print("============================")
end

-- 注册回调
EasyMode:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, EasyMode.onGameStarted)
EasyMode:AddCallback(ModCallbacks.MC_POST_GAME_END, EasyMode.onGameEnded)
EasyMode:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, EasyMode.onPreGameExit)

return EasyMode
