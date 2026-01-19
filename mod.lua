-- ============================================================================
-- Easy Mode Mod - 主逻辑文件
-- 用于控制敌人速度、投射物速度和攻击频率
-- ============================================================================

local EasyMode = {}

-- 缓存已处理的实体以提高性能
local processedEntities = setmetatable({}, {__mode = "k"})
local projectileData = setmetatable({}, {__mode = "k"})

-- 回调注册表
EasyMode.callbacks = {}

-- 默认配置（从主文件读取）
function EasyMode:GetConfig()
    if Mod and Mod.Config then
        return Mod.Config
    end
    -- 默认配置
    return {
        ENEMY_SPEED_FACTOR = 0.6,
        BOSS_SPEED_FACTOR = 0.85,
        PROJECTILE_SPEED_FACTOR = 0.6,
        TEAR_SPEED_FACTOR = 0.6,
        ATTACK_COOLDOWN_MULTIPLIER = 1.5,
        SPIKE_DAMAGE_MULTIPLIER = 0.5,
        EXPLOSION_DAMAGE_MULTIPLIER = 0.4,
        FIRE_DAMAGE_MULTIPLIER = 0.7,
        ENABLE_TRAP_MODIFICATION = true,
        EXCLUDE_FRIENDLY = true,
        EXCLUDE_FAMILIARS = true,
        ENABLE_ATTACK_SLOWDOWN = false
    }
end

-- ============================================================================
-- 实体类型检查函数
-- ============================================================================

function EasyMode:isNPCEntity(entity)
    -- 检查是否是NPC实体（敌人）
    -- 实体ID 10-999 是敌人，1000是特效，1是玩家
    if not entity then return false end
    local etype = entity.Type
    return etype >= 10 and etype ~= 1000
end

function EasyMode:isEnemyProjectile(entity)
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

function EasyMode:isFriendlyOrFamiliar(entity)
    -- 检查是否是友好单位或跟随物
    if not entity then return false end
    
    local config = self:GetConfig()
    
    -- 检查友好标志
    if config.EXCLUDE_FRIENDLY and entity:HasEntityFlags(EntityFlag.FLAG_FRIENDLY) then
        return true
    end
    
    -- 检查跟随物
    if config.EXCLUDE_FAMILIARS and entity.Type == EntityType.ENTITY_FAMILIAR then
        return true
    end
    
    return false
end

-- ============================================================================
-- 主回调函数
-- ============================================================================

function EasyMode:onNPCUpdate(npc)
    -- 只处理敌人实体
    if not self:isNPCEntity(npc) then
        return
    end
    
    -- 豁免友好单位和跟随物
    if self:isFriendlyOrFamiliar(npc) then
        return
    end
    
    -- 忽略已死亡的实体
    if npc:IsDead() then
        return
    end
    
    local config = self:GetConfig()
    local velocity = npc.Velocity
    local speed = velocity:Length()
    
    -- 忽略静止或几乎静止的实体
    if speed < 0.5 then
        return
    end
    
    -- 根据实体类型选择减速因子
    local factor = config.ENEMY_SPEED_FACTOR
    if npc:IsBoss() then
        factor = config.BOSS_SPEED_FACTOR
    end
    
    -- 应用速度减速
    npc.Velocity = velocity * factor
    
    -- 记录处理过的实体
    processedEntities[npc] = true
end

function EasyMode:onProjectileUpdate(projectile)
    -- 检查是否是敌对投射物
    if not self:isEnemyProjectile(projectile) then
        return
    end
    
    local config = self:GetConfig()
    local velocity = projectile.Velocity
    local speed = velocity:Length()
    
    -- 忽略速度为0的投射物
    if speed < 0.1 then
        return
    end
    
    -- 应用速度减速
    local factor = config.PROJECTILE_SPEED_FACTOR
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

function EasyMode:onTearUpdate(tear)
    -- 检查是否是敌对眼泪
    if tear.SpawnerType == EntityType.ENTITY_PLAYER then
        return  -- 玩家眼泪，不处理
    end
    
    if tear.SpawnerType and tear.SpawnerType >= 10 then
        local config = self:GetConfig()
        tear.Velocity = tear.Velocity * config.TEAR_SPEED_FACTOR
    end
end

function EasyMode:onEntityTakeDamage(entity, damage, flags, source, countdown)
    -- 陷阱伤害减免
    local config = self:GetConfig()
    
    if not config.ENABLE_TRAP_MODIFICATION then
        return nil
    end
    
    local newDamage = damage
    
    -- 尖刺伤害
    if flags & DamageFlag.DAMAGE_SPIKES ~= 0 then
        newDamage = damage * config.SPIKE_DAMAGE_MULTIPLIER
    -- 爆炸伤害
    elseif flags & DamageFlag.DAMAGE_EXPLOSION ~= 0 then
        newDamage = damage * config.EXPLOSION_DAMAGE_MULTIPLIER
    -- 火焰伤害
    elseif flags & DamageFlag.DAMAGE_FIRE ~= 0 then
        newDamage = damage * config.FIRE_DAMAGE_MULTIPLIER
    end
    
    return newDamage
end

function EasyMode:onRoomUpdate()
    -- 房间级别的更新逻辑
    -- 可以用于清理已移除的投射物数据
end

-- ============================================================================
-- 初始化和清理
-- ============================================================================

function EasyMode:Init()
    -- 注册所有回调
    self.callbacks = {
        { ModCallbacks.MC_NPC_UPDATE, self.onNPCUpdate },
        { ModCallbacks.MC_POST_PROJECTILE_UPDATE, self.onProjectileUpdate },
        { ModCallbacks.MC_POST_TEAR_UPDATE, self.onTearUpdate },
        { ModCallbacks.MC_ENTITY_TAKE_DMG, self.onEntityTakeDamage },
        { ModCallbacks.MC_POST_UPDATE, self.onRoomUpdate }
    }
    
    for _, callback in ipairs(self.callbacks) do
        Isaac.AddCallback(Mod, callback[1], callback[2], 0)
    end
    
    -- 清理缓存
    processedEntities = {}
    projectileData = {}
end

function EasyMode:Cleanup()
    -- 移除所有回调
    for _, callback in ipairs(self.callbacks or {}) do
        Isaac.RemoveCallback(Mod, callback[1], callback[2])
    end
    self.callbacks = {}
    
    -- 清理缓存
    processedEntities = {}
    projectileData = {}
end

-- ============================================================================
-- 工具函数
-- ============================================================================

function EasyMode:resetEntitySpeed(entity)
    -- 重置实体速度（如果需要）
    if entity and processedEntities[entity] then
        -- 由于我们直接修改速度，无法直接恢复
        -- 但可以记录原始速度（复杂实现）
        processedEntities[entity] = nil
    end
end

return EasyMode
