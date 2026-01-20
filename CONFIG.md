# Easy Mode Mod 配置说明

## 简介

Easy Mode Mod 是一个通过降低敌人属性来减少《以撒的结合：忏悔》游戏难度的模组。

## 配置文件

| 文件 | 说明 |
|------|------|
| `config.lua` | 用户配置文件（独立管理，不产生 git 冲突） |
| `config.lua.example` | 默认配置模板 |
| `CONFIG.md` | 本配置说明文档 |
| `CONFIG.en.md` | English documentation |

## 快速开始

### 1. 修改配置

编辑 `config.lua` 文件。推荐使用文本编辑器（如 VS Code、Notepad++）打开：

```lua
return {
    ENEMY_SPEED_FACTOR = 0.4,              -- 敌人移动速度 (0.4 = 60% 减速)
    BOSS_SPEED_FACTOR = 0.7,               -- Boss 移动速度 (0.7 = 30% 减速)
    PROJECTILE_SPEED_FACTOR = 0.95,        -- 投射物速度 (0.95 = ~10% 减速, ~19% 射程减少)
    TEAR_SPEED_FACTOR = 0.95,              -- 眼泪速度 (同上)
    ROCK_WAVE_SPEED_FACTOR = 0.9,          -- 岩石/波浪速度 (0.9 = ~19% 射程减少)
    BOMB_EXPLOSION_DELAY_MULTIPLIER = 1.5, -- 炸弹爆炸延迟 (1.5x)
    ATTACK_COOLDOWN_MULTIPLIER = 1.5,      -- 攻击冷却倍率
    EXCLUDE_FRIENDLY = true,               -- 豁免友好单位
    EXCLUDE_FAMILIARS = true,              -- 豁免跟随物
    ENABLE_ATTACK_SLOWDOWN = false         -- 启用攻击减速（实验性）
}
```

### 2. 重启游戏

修改 `config.lua` 后需要**完全重启游戏**（不只是重新加载模组）才能生效。

## 物理原理

### 抛物线运动与射程

投射物遵循抛物线运动轨迹，射程公式为：

```
R = (v² × sin(2θ)) / g
```

**关键发现：射程与速度的平方成正比！**

| 速度因子 | 实际速度 | 预期射程 | 射程衰减 |
|---------|---------|---------|---------|
| 1.0 | 100% | 100% | 无衰减 |
| 0.98 | 98% | **96%** | -4% |
| 0.95 | 95% | **90%** | -10% |
| 0.9 | 90% | **81%** | -19% |
| 0.85 | 85% | **72%** | -28% |
| 0.8 | 80% | **64%** | -36% |

**示例：**
- 速度因子 0.95 → 速度减少 5%，但射程减少约 10%
- 速度因子 0.9 → 速度减少 10%，但射程减少约 19%

### 配置建议

根据你想要的难度调整：

| 难度级别 | PROJECTILE/TEAR_SPEED | ROCK_WAVE_SPEED | 射程减少 |
|---------|----------------------|-----------------|---------|
| 轻度 | 0.98 | 0.95 | ~4-10% |
| 中度 | 0.95 | 0.9 | ~10-19% |
| 重度 | 0.9 | 0.85 | ~19-28% |

## 配置参数详解

### 速度控制参数

#### ENEMY_SPEED_FACTOR
- **默认值**: `0.4`
- **说明**: 普通敌人（Type 10-999）的移动速度因子
- **效果**: 敌人移动速度降低 60%

#### BOSS_SPEED_FACTOR
- **默认值**: `0.7`
- **说明**: Boss 的移动速度因子
- **效果**: Boss 移动速度降低 30%
- **注意**: Boss 受到攻击后可能不会减速（游戏机制限制）

#### PROJECTILE_SPEED_FACTOR
- **默认值**: `0.95`
- **说明**: 敌人投射物（Type 9, Spawner >= 10）的速度因子
- **效果**: 投射物速度降低约 5%，射程减少约 10%
- **物理原理**: 射程与速度平方成正比

#### TEAR_SPEED_FACTOR
- **默认值**: `0.95`
- **说明**: 敌人眼泪（Type 2, Spawner != Player）的速度因子
- **效果**: 与投射物相同
- **注意**: 敌人眼泪实际上也是 Type 9 (ENTITY_PROJECTILE)，但通过 SpawnerType 区分

#### ROCK_WAVE_SPEED_FACTOR
- **默认值**: `0.9`
- **说明**: 特殊投射物（石刃波、岩石等）的速度因子
- **效果**: 特殊投射物速度降低约 10%，射程减少约 19%
- **识别方式**: 只对 `ProjectileVariant.PROJECTILE_ROCK` 生效

### 时间控制参数

#### BOMB_EXPLOSION_DELAY_MULTIPLIER
- **默认值**: `1.5`
- **说明**: 炸弹爆炸延迟倍率
- **效果**: 炸弹爆炸时间延长 50%
- **实现方式**: 使用 `EntityBomb:SetExplosionCountdown()`

#### ATTACK_COOLDOWN_MULTIPLIER
- **默认值**: `1.5`
- **说明**: 敌人攻击冷却时间倍率
- **效果**: 敌人攻击间隔延长 50%（实验性功能）

### 豁免参数

#### EXCLUDE_FRIENDLY
- **默认值**: `true`
- **说明**: 是否豁免友好单位（被魅惑的敌人）
- **效果**: 被魅惑的敌人不会减速

#### EXCLUDE_FAMILIARS
- **默认值**: `true`
- **说明**: 是否豁免跟随物
- **效果**: 玩家的跟随物不会受到影响

#### ENABLE_ATTACK_SLOWDOWN
- **默认值**: `false`
- **说明**: 是否启用攻击减速（实验性功能）
- **注意**: 此功能可能不稳定

## Git 冲突保护

`config.lua` 使用 Git 的 `skip-worktree` 功能保护，**本地修改不会产生 git 合并冲突**。

### 优点
- ✅ 拉取更新时，本地配置不会被覆盖
- ✅ 可以随时修改配置而不影响其他用户
- ✅ 适合个人化设置

### 提交配置更改

如果希望将你的配置更改提交到仓库：

```bash
# 1. 临时取消 skip-worktree 保护
git update-index --no-skip-worktree config.lua

# 2. 提交更改
git add config.lua
git commit -m "Update config with my settings"

# 3. 重新启用保护
git update-index --skip-worktree config.lua
```

### 恢复默认配置

如果想重置为默认配置：

```bash
# 1. 临时取消保护
git update-index --no-skip-worktree config.lua

# 2. 恢复模板
cp config.lua.example config.lua

# 3. 提交恢复操作（可选）
git add config.lua
git commit -m "Reset config to defaults"

# 4. 重新启用保护
git update-index --skip-worktree config.lua
```

## 预设配置方案

### 轻度难度降低（推荐新手）

```lua
return {
    ENEMY_SPEED_FACTOR = 0.5,
    BOSS_SPEED_FACTOR = 0.8,
    PROJECTILE_SPEED_FACTOR = 0.98,
    TEAR_SPEED_FACTOR = 0.98,
    ROCK_WAVE_SPEED_FACTOR = 0.95,
    BOMB_EXPLOSION_DELAY_MULTIPLIER = 1.2,
    ATTACK_COOLDOWN_MULTIPLIER = 1.2,
    EXCLUDE_FRIENDLY = true,
    EXCLUDE_FAMILIARS = true,
    ENABLE_ATTACK_SLOWDOWN = false
}
```

### 中度难度降低（推荐大多数玩家）

```lua
return {
    ENEMY_SPEED_FACTOR = 0.4,
    BOSS_SPEED_FACTOR = 0.7,
    PROJECTILE_SPEED_FACTOR = 0.95,
    TEAR_SPEED_FACTOR = 0.95,
    ROCK_WAVE_SPEED_FACTOR = 0.9,
    BOMB_EXPLOSION_DELAY_MULTIPLIER = 1.5,
    ATTACK_COOLDOWN_MULTIPLIER = 1.5,
    EXCLUDE_FRIENDLY = true,
    EXCLUDE_FAMILIARS = true,
    ENABLE_ATTACK_SLOWDOWN = false
}
```

### 重度难度降低（挑战模式）

```lua
return {
    ENEMY_SPEED_FACTOR = 0.3,
    BOSS_SPEED_FACTOR = 0.6,
    PROJECTILE_SPEED_FACTOR = 0.9,
    TEAR_SPEED_FACTOR = 0.9,
    ROCK_WAVE_SPEED_FACTOR = 0.85,
    BOMB_EXPLOSION_DELAY_MULTIPLIER = 2.0,
    ATTACK_COOLDOWN_MULTIPLIER = 2.0,
    EXCLUDE_FRIENDLY = true,
    EXCLUDE_FAMILIARS = true,
    ENABLE_ATTACK_SLOWDOWN = false
}
```

## 支持的实体类型

| 实体类型 | EntityType 值 | SpawnerType | 处理方式 |
|---------|--------------|-------------|----------|
| 普通敌人 | 10-999 | - | 使用 ENEMY_SPEED_FACTOR |
| Boss | 特殊值 | - | 使用 BOSS_SPEED_FACTOR |
| 敌人投射物 | 9 | >= 10 | 使用 PROJECTILE_SPEED_FACTOR |
| 敌人眼泪 | 2 | >= 10 | 使用 TEAR_SPEED_FACTOR |
| 玩家眼泪 | 2 | 1 | 不处理 |
| 岩石投射物 | 9 (Variant=1) | - | 使用 ROCK_WAVE_SPEED_FACTOR |
| 炸弹 | 4 | - | 使用 BOMB_EXPLOSION_DELAY_MULTIPLIER |

## 常见问题

### Q: 修改配置后需要做什么？

A: 需要**完全重启游戏**，不只是重新加载模组。

### Q: 为什么投射物射程减少比预期多？

A: 射程与速度的平方成正比。如果速度因子是 0.9，射程会是 0.81（减少 19%）。

### Q: 可以完全禁用投射物减速吗？

A: 可以，将 PROJECTILE_SPEED_FACTOR 和 TEAR_SPEED_FACTOR 设为 1.0。

### Q: Boss 为什么不减速？

A: 某些 Boss 有特殊的移动逻辑，可能不受速度因子影响。这是游戏机制限制。

### Q: 配置不生效怎么办？

1. 确保完全重启游戏
2. 检查 config.lua 语法是否正确（可以使用在线 Lua 语法检查器）
3. 检查是否被其他模组覆盖

## 技术说明

### 工作原理

模组通过 `MC_POST_UPDATE` 回调每帧扫描房间内所有实体：

1. 获取房间内所有实体：`Isaac.GetRoomEntities()`
2. 检测实体类型并应用对应减速
3. 使用弱表缓存已处理实体避免重复计算

### 性能优化

- 每个投射物只处理一次（使用 `processedProjectiles` 追踪）
- 忽略静止实体（速度 < 0.5）
- 使用实体类型快速过滤

## 相关文件

- `main.lua` - 模组主逻辑
- `config.lua` - 用户配置
- `config.lua.example` - 配置模板
- `README.md` - 模组说明
- `CONFIG.md` - 本配置文档
- `CONFIG.en.md` - English documentation

## 进阶玩法：挑战自我 🎮

### 想要更高的难度？没问题！

本模组支持将参数设置为 **大于 1.0** 来实现「困难模式」甚至「自虐模式」！

```lua
return {
    ENEMY_SPEED_FACTOR = 1.5,              -- 敌人跑得比你还快！
    BOSS_SPEED_FACTOR = 2.0,               -- Boss 的速度是正常值的 2 倍！
    PROJECTILE_SPEED_FACTOR = 1.5,        -- 投射物快得像子弹！
    BOMB_EXPLOSION_DELAY_MULTIPLIER = 0.5, -- 炸弹爆炸更快了！
}
```

### 效果预览

| 参数 | 正常值 | 自虐值 | 效果 |
|------|--------|--------|------|
| ENEMY_SPEED_FACTOR | 0.4 | 1.5 | 敌人移动速度提高 275% |
| BOSS_SPEED_FACTOR | 0.7 | 2.0 | Boss 移动速度提高 186% |
| PROJECTILE_SPEED_FACTOR | 0.95 | 1.5 | 投射物速度提高 58%，射程增加 125% |

### ⚠️ 温馨提示

> **这不是警告，这是来自开发者的忠告：**
>
> - 设置 ENEMY_SPEED_FACTOR > 1 意味着敌人可能比你跑得还快
> - PROJECTILE_SPEED_FACTOR > 1 会让投射物飞得更远更快
> - 你可能需要更强的走位技巧和更快的反应速度
> - 我们不保证你能活着通过第一章
> - 开发者对任何摔手柄、砸键盘、显示器进水等后果概不负责

### 成就解锁

如果你成功用以下配置通关，请务必联系开发者：

```lua
ENEMY_SPEED_FACTOR = 3.0
BOSS_SPEED_FACTOR = 5.0
PROJECTILE_SPEED_FACTOR = 2.0
ATTACK_COOLDOWN_MULTIPLIER = 0.1  -- 攻击冷却更短 = 敌人攻击更频繁
```

**祝你好运！记得多买几张纸巾擦眼泪。** 🧻

---

## 许可证

本模组遵循 MIT 许可证。
