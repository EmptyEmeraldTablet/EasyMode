# Easy Mode Mod 配置说明

## 配置文件

- `config.lua` - 用户配置文件（独立管理，不产生 git 冲突）
- `config.lua.example` - 默认配置模板

## 使用方法

### 1. 修改配置

编辑 `config.lua` 文件：

```lua
return {
    ENEMY_SPEED_FACTOR = 0.4,              -- 敌人移动速度 (0.4 = 60% 减速)
    BOSS_SPEED_FACTOR = 0.7,               -- Boss 移动速度 (0.7 = 30% 减速)
    PROJECTILE_SPEED_FACTOR = 0.7,         -- 投射物速度 (0.7 = 30% 减速)
    TEAR_SPEED_FACTOR = 0.7,               -- 眼泪速度 (0.7 = 30% 减速)
    ROCK_WAVE_SPEED_FACTOR = 0.6,          -- 岩石/波浪速度 (0.6 = 40% 减速)
    BOMB_EXPLOSION_DELAY_MULTIPLIER = 1.5, -- 炸弹爆炸延迟 (1.5x)
    ATTACK_COOLDOWN_MULTIPLIER = 1.5,      -- 攻击冷却倍率
    EXCLUDE_FRIENDLY = true,               -- 豁免友好单位
    EXCLUDE_FAMILIARS = true,              -- 豁免跟随物
    ENABLE_ATTACK_SLOWDOWN = false         -- 启用攻击减速（实验性）
}
```

### 2. Git 冲突保护

`config.lua` 已配置为**忽略本地修改，不会产生 git 合并冲突**。

- 拉取更新时，你的本地配置不会被覆盖
- 你可以随时修改配置而不影响其他用户
- 如果想提交你的配置更改，按下方步骤操作

### 3. 提交配置更改

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

### 4. 恢复默认配置

如果想重置为默认配置：

```bash
# 临时取消保护
git update-index --no-skip-worktree config.lua

# 恢复模板
cp config.lua.example config.lua

# 提交恢复操作（可选）
git add config.lua
git commit -m "Reset config to defaults"

# 重新启用保护
git update-index --skip-worktree config.lua
```

## 配置参数说明

| 参数 | 默认值 | 说明 |
|------|--------|------|
| ENEMY_SPEED_FACTOR | 0.4 | 敌人移动速度倍率 (60% 减速) |
| BOSS_SPEED_FACTOR | 0.7 | Boss 移动速度倍率 (30% 减速) |
| PROJECTILE_SPEED_FACTOR | 0.7 | 投射物速度倍率 (30% 减速) |
| TEAR_SPEED_FACTOR | 0.7 | 眼泪速度倍率 (30% 减速) |
| ROCK_WAVE_SPEED_FACTOR | 0.6 | 岩石/波浪速度倍率 (40% 减速) |
| BOMB_EXPLOSION_DELAY_MULTIPLIER | 1.5 | 炸弹爆炸延迟倍数 |
| ATTACK_COOLDOWN_MULTIPLIER | 1.5 | 攻击冷却时间倍率 |
| EXCLUDE_FRIENDLY | true | 是否豁免友好单位（被魅惑的敌人） |
| EXCLUDE_FAMILIARS | true | 是否豁免跟随物 |
| ENABLE_ATTACK_SLOWDOWN | false | 是否启用攻击减速（实验性功能） |

## 速度因子说明

- `1.0` = 原速
- `0.7` = 30% 减速（70% 速度）
- `0.5` = 50% 减速（50% 速度）
- `0.4` = 60% 减速（40% 速度）

值越小，减速越明显。
