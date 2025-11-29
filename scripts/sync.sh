#!/bin/bash
# 安全同步脚本
# 用途：在 git pull 之前自动清理其他团队文件夹的本地修改，避免冲突

# 检查是否有保存的团队配置
TEAM_CONFIG=".git/team-config"
TEAMS_CONFIG=".git/team-folders"

if [ ! -f "$TEAM_CONFIG" ]; then
    echo "❌ 错误：未找到团队配置"
    echo "请先运行：bash scripts/setup-team-tracking.sh"
    exit 1
fi

if [ ! -f "$TEAMS_CONFIG" ]; then
    echo "❌ 错误：未找到团队文件夹配置"
    echo "请先运行：bash scripts/setup-team-tracking.sh"
    exit 1
fi

# 读取配置
MY_TEAM=$(cat "$TEAM_CONFIG")
TEAM_FOLDERS=($(cat "$TEAMS_CONFIG"))

if [ -z "$MY_TEAM" ]; then
    echo "❌ 错误：团队配置为空"
    echo "请先运行：bash scripts/setup-team-tracking.sh"
    exit 1
fi

echo "🔄 同步中... (你的团队: $MY_TEAM)"

# 在 pull 之前，恢复其他团队文件夹到 HEAD 版本
for team in "${TEAM_FOLDERS[@]}"; do
    if [ "$team" != "$MY_TEAM" ] && [ -d "$team" ]; then
        # 1. 先清除该文件夹所有文件的 skip-worktree 标记
        find "$team" -type f -exec git update-index --no-skip-worktree {} \; 2>/dev/null || true

        # 2. 强制恢复到 HEAD 版本（丢弃本地修改）
        git checkout HEAD -- "$team/" 2>/dev/null || true
    fi
done

# 执行 git pull
echo "📥 拉取远程更新..."
git pull

# post-merge hook 会自动重新配置 skip-worktree
echo ""
echo "✅ 同步完成！"
