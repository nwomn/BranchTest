#!/bin/bash
# 安全切换分支脚本
# 用途：在切换分支前清除 skip-worktree，切换后重新配置

if [ -z "$1" ]; then
    echo "用法: git switch-branch <分支名>"
    echo "  或: bash scripts/switch-branch.sh <分支名>"
    exit 1
fi

TARGET_BRANCH="$1"
TEAM_CONFIG=".git/team-config"
TEAMS_CONFIG=".git/team-folders"

# 检查配置
if [ ! -f "$TEAM_CONFIG" ] || [ ! -f "$TEAMS_CONFIG" ]; then
    # 没有团队配置，直接切换
    git checkout "$TARGET_BRANCH"
    exit $?
fi

MY_TEAM=$(cat "$TEAM_CONFIG")
TEAM_FOLDERS=($(cat "$TEAMS_CONFIG"))

echo "🔄 准备切换到分支: $TARGET_BRANCH"

# 1. 清除所有 skip-worktree 标记
echo "  📝 清除 skip-worktree 标记..."
for team in "${TEAM_FOLDERS[@]}"; do
    if [ "$team" != "$MY_TEAM" ] && [ -d "$team" ]; then
        find "$team" -type f -exec git update-index --no-skip-worktree {} \; 2>/dev/null || true
    fi
done

# 2. 恢复其他团队文件夹到 HEAD（丢弃本地修改）
echo "  🔙 恢复其他团队文件夹..."
for team in "${TEAM_FOLDERS[@]}"; do
    if [ "$team" != "$MY_TEAM" ] && [ -d "$team" ]; then
        git checkout HEAD -- "$team/" 2>/dev/null || true
    fi
done

# 3. 切换分支
echo "  🌿 切换分支..."
if ! git checkout "$TARGET_BRANCH"; then
    echo "❌ 切换分支失败"
    # 重新配置 skip-worktree
    for team in "${TEAM_FOLDERS[@]}"; do
        if [ "$team" != "$MY_TEAM" ] && [ -d "$team" ]; then
            find "$team" -type f -exec git update-index --skip-worktree {} \; 2>/dev/null || true
        fi
    done
    exit 1
fi

# 4. 重新配置 skip-worktree
echo "  🔒 重新配置 skip-worktree..."
for team in "${TEAM_FOLDERS[@]}"; do
    if [ "$team" != "$MY_TEAM" ] && [ -d "$team" ]; then
        find "$team" -type f -exec git update-index --skip-worktree {} \; 2>/dev/null || true
    fi
done

echo ""
echo "✅ 已切换到分支: $TARGET_BRANCH"
