-- Easy Mode Mod - 测试脚本
-- 使用方法：在游戏中按 ~ 打开控制台，输入以下命令

-- 测试配置
dofile("mods/EasyModeMod/main.lua")

-- 打印当前配置
if Mod and Mod.printConfig then
    Mod:printConfig()
end

-- 启用调试输出（如果已实现）
-- Mod.DebugEnabled = true

print("Easy Mode 测试完成")
