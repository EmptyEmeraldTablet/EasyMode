# Easy Mode Mod for The Binding of Isaac: Repentance

一个通过降低敌人属性来减少游戏难度的模组。

## 功能特性

### 速度控制
- **敌人移动速度**: 默认降低 40%
- **Boss移动速度**: 默认降低 15%
- **敌对投射物速度**: 默认降低 40%
- **敌对眼泪速度**: 默认降低 40%

### 特殊规则
- 玩家和玩家跟随物不受影响
- 友好单位（被魅惑的敌人）不受影响
- 投射物降低速度后自动调整存活时间以保持相同射程

### 伤害控制（已移除）
> ⚠️ 伤害控制功能已移除。游戏伤害为整数（1-2点），无法简单使用倍率缩减。

## 安装方法

1. 确保已安装 The Binding of Isaac: Repentance
2. 启用 Steam 创意工坊或手动安装模组
3. 在游戏模组列表中启用 "Easy Mode"

### 手动安装

将整个 `EasyModeMod` 文件夹复制到游戏的 `mods` 目录：

```
Steam/steamapps/common/The Binding of Isaac Rebirth/mods/EasyModeMod/
```

## 文件结构

```
EasyModeMod/
├── main.lua          # 模组主文件（单一文件结构）
├── metadata.xml      # 模组描述文件
└── README.md         # 本文件
```

## 配置说明

在 `main.lua` 中可以修改以下配置：

```lua
EasyMode.Config = {
    ENEMY_SPEED_FACTOR = 0.6,           -- 敌人速度 (0.6 = 60% 原始速度)
    BOSS_SPEED_FACTOR = 0.85,           -- Boss速度
    PROJECTILE_SPEED_FACTOR = 0.6,      -- 投射物速度
    TEAR_SPEED_FACTOR = 0.6,            -- 眼泪速度
    ATTACK_COOLDOWN_MULTIPLIER = 1.5,   -- 攻击冷却倍数
    ENABLE_TRAP_MODIFICATION = false,   -- 启用陷阱修改（已禁用，伤害为整数无法简单缩减）
    EXCLUDE_FRIENDLY = true,            -- 豁免友好单位
    EXCLUDE_FAMILIARS = true            -- 豁免跟随物
}
```

> ⚠️ 注意：伤害倍率配置已移除。游戏伤害为整数（1-2点），无法简单使用倍率缩减。

## 技术说明

### 工作原理

模组通过以下回调实现功能：

1. `MC_NPC_UPDATE` - 控制敌人移动速度
2. `MC_POST_PROJECTILE_UPDATE` - 控制投射物速度并调整射程
3. `MC_ENTITY_TAKE_DMG` - ~~减少陷阱伤害~~（已移除，伤害为整数无法简单缩减）

### 性能优化

- 使用弱表缓存已处理实体，减少重复计算
- 忽略静止实体以减少不必要的计算
- 使用实体标志进行快速过滤

### 兼容性

- 兼容所有DLC内容
- 不修改玩家属性
- 不影响游戏进度和成就

## 已知问题

1. 某些特殊敌人行为可能受到影响
2. 投射物射程调整可能不适用于所有类型
3. Boss战难度降低可能影响游戏体验

## 未来计划

- [ ] 添加用户可配置界面
- [ ] 添加多难度级别选择
- [ ] 添加单独控制选项
- [ ] 优化性能表现

## 许可证

本模组遵循 MIT 许可证。

## 致谢

- Edmund McMillen 和 Nicalis - 制作了出色的游戏
-模组社区 - 提供了大量参考资料
