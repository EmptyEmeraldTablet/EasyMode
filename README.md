# Easy Mode Mod for The Binding of Isaac: Repentance

一个通过降低敌人属性来减少游戏难度的模组。

## 功能特性

### 速度控制
- **敌人移动速度**: 默认降低 60% (速度因子 0.4)
- **Boss移动速度**: 默认降低 30% (速度因子 0.7)
- **敌对投射物速度**: 默认降低 50% (速度因子 0.5)
- **敌对眼泪速度**: 默认降低 50% (速度因子 0.5)

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
├── main.lua              # 模组主文件（单一文件结构）
├── metadata.xml          # 模组描述文件
├── README.md             # 说明文档
└── DEVELOPMENT_NOTES.md  # 开发笔记（问题与解决方案）
```

## 配置说明

在 `main.lua` 中可以修改以下配置：

```lua
EasyMode.Config = {
    ENEMY_SPEED_FACTOR = 0.4,        -- 敌人速度 (0.4 = 40% 原始速度，即降低60%)
    BOSS_SPEED_FACTOR = 0.7,         -- Boss速度 (0.7 = 70% 原始速度，即降低30%)
    PROJECTILE_SPEED_FACTOR = 0.5,   -- 投射物速度 (0.5 = 50% 原始速度，即降低50%)
    TEAR_SPEED_FACTOR = 0.5,         -- 眼泪速度 (0.5 = 50% 原始速度，即降低50%)
    ATTACK_COOLDOWN_MULTIPLIER = 1.5,-- 攻击冷却倍数
    EXCLUDE_FRIENDLY = true,         -- 豁免友好单位
    EXCLUDE_FAMILIARS = true         -- 豁免跟随物
}
```

## 技术说明

### 工作原理

模组通过以下回调实现功能：

1. `MC_POST_UPDATE` - 每帧扫描房间内所有实体并减速敌人和投射物
2. 使用 `Isaac.GetRoomEntities()` 获取房间内所有实体
3. 使用 `entity:ToNPC()` 检测敌人（比 `IsActiveEnemy()` 更可靠）

### 性能优化

- 忽略静止实体（速度 < 0.5）以减少不必要的计算
- 使用实体类型检查快速过滤非敌人实体
- 代码简洁高效，无冗余日志输出

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
