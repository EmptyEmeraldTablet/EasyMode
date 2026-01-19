-- Easy Mode Mod for The Binding of Isaac: Repentance
-- 此模组通过降低敌人速度、投射物速度和增加攻击间隔来降低游戏难度
-- 不影响玩家属性

local EasyMode = RegisterMod("Easy Mode", 1)

-- 导入模组主逻辑
EasyMode.MainScript = include("EasyMode.mod")

-- 配置存储
EasyMode.Config = {
    ENEMY_SPEED_FACTOR = 0.6,        -- 敌人移动速度 (0.6 = 降低40%)
    BOSS_SPEED_FACTOR = 0.85,        -- Boss移动速度 (0.85 = 轻微降低)
    PROJECTILE_SPEED_FACTOR = 0.6,   -- 敌对投射物速度
    TEAR_SPEED_FACTOR = 0.6,         -- 敌对眼泪速度
    ATTACK_COOLDOWN_MULTIPLIER = 1.5, -- 攻击冷却增加倍数
    SPIKE_DAMAGE_MULTIPLIER = 0.5,   -- 尖刺伤害倍率
    EXPLOSION_DAMAGE_MULTIPLIER = 0.4, -- 爆炸伤害倍率
    FIRE_DAMAGE_MULTIPLIER = 0.7,    -- 火焰伤害倍率
    ENABLE_TRAP_MODIFICATION = true,  -- 是否修改陷阱伤害
    EXCLUDE_FRIENDLY = true,         -- 豁免友好单位
    EXCLUDE_FAMILIARS = true,        -- 豁免跟随物
    ENABLE_ATTACK_SLOWDOWN = false   -- 是否启用攻击减速（实验性功能）
}

function EasyMode:onGameStarted()
    -- 游戏开始时初始化
    if EasyMode.MainScript and EasyMode.MainScript.Init then
        EasyMode.MainScript:Init()
    end
    print("[EasyMode] 模组已加载 - 游戏难度已降低")
    print(string.format("[EasyMode] 敌人速度: %.0f%%, 投射物速度: %.0f%%", 
        EasyMode.Config.ENEMY_SPEED_FACTOR * 100,
        EasyMode.Config.PROJECTILE_SPEED_FACTOR * 100))
end

function EasyMode:onGameEnded()
    -- 游戏结束时清理
    if EasyMode.MainScript and EasyMode.MainScript.Cleanup then
        EasyMode.MainScript:Cleanup()
    end
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
    print(string.format("尖刺伤害倍率: %.2f", EasyMode.Config.SPIKE_DAMAGE_MULTIPLIER))
    print(string.format("爆炸伤害倍率: %.2f", EasyMode.Config.EXPLOSION_DAMAGE_MULTIPLIER))
    print(string.format("火焰伤害倍率: %.2f", EasyMode.Config.FIRE_DAMAGE_MULTIPLIER))
    print("============================")
end

-- 注册回调
EasyMode:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, EasyMode.onGameStarted)
EasyMode:AddCallback(ModCallbacks.MC_POST_GAME_END, EasyMode.onGameEnded)
EasyMode:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, EasyMode.onPreGameExit)

return EasyMode
