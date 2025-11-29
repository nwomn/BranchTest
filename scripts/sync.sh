#!/bin/bash
# 安全同步脚本
# 用途：在 git pull 之前自动清理其他团队文件夹的本地修改，避免冲突

# 检查是否有保存的团队配置
TEAM_CONFIG=".git/team-config"

if [ ! -f "$TEAM_CONFIG" ]; then
    echo "❌ 错误：未找到团队配置"
    echo "请先运行：bash scripts/setup-team-tracking.sh"
    exit 1
fi

# 读取配置的团队
MY_TEAM=$(cat "$TEAM_CONFIG")

if [ -z "$MY_TEAM" ]; then
    echo "❌ 错误：团队配置为空"
    echo "请先运行：bash scripts/setup-team-tracking.sh"
    exit 1
fi

echo "🔄 同步中... (你的团队: $MY_TEAM)"

# 获取所有团队文件夹
TEAM_FOLDERS=($(ls -d */ 2>/dev/null | grep "^team" | sed 's|/||'))

if [ ${#TEAM_FOLDERS[@]} -eq 0 ]; then
    echo "❌ 错误：未找到任何 team* 文件夹"
    exit 1
fi

# 【关键】在 pull 之前，恢复其他团队文件夹到 HEAD 版本
# 这样就不会产生冲突
for team in "${TEAM_FOLDERS[@]}"; do
    if [ "$team" != "$MY_TEAM" ]; then
        # 检查该文件夹是否有本地修改（包括 skip-worktree 的文件）
        # 使用 git checkout 强制恢复到 HEAD
        git checkout HEAD -- "$team/" 2>/dev/null || true
    fi
done

# 执行 git pull
echo "📥 拉取远程更新..."
git pull

# post-merge hook 会自动重新配置 skip-worktree
echo ""
echo "✅ 同步完成！"
