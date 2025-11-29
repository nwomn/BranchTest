#!/bin/bash
# 团队文件夹追踪配置脚本
# 用途：配置 Git 只追踪你负责的团队文件夹的修改

set -e

echo "===================================="
echo "  团队文件夹追踪配置工具"
echo "===================================="
echo ""
echo "这个脚本会配置 Git，让你："
echo "  ✅ 可以查看所有团队的文件夹"
echo "  ✅ git pull 会拉取所有文件夹的更新"
echo "  ✅ 但 git status 只显示你团队文件夹的修改"
echo "  ✅ 防止误提交其他团队的代码"
echo ""

# 检查是否在 Git 仓库中
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo "❌ 错误：当前目录不是 Git 仓库"
    echo "请先 cd 到 BranchTest 目录"
    exit 1
fi

# 获取所有团队文件夹
TEAM_FOLDERS=($(ls -d */ 2>/dev/null | grep "^team" | sed 's|/||'))

if [ ${#TEAM_FOLDERS[@]} -eq 0 ]; then
    echo "❌ 错误：未找到任何 team* 文件夹"
    exit 1
fi

echo "发现以下团队文件夹："
for i in "${!TEAM_FOLDERS[@]}"; do
    echo "  $((i+1))) ${TEAM_FOLDERS[$i]}"
done
echo ""

# 选择团队
read -p "请输入你的团队编号 (1-${#TEAM_FOLDERS[@]}): " choice

if ! [[ "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -gt ${#TEAM_FOLDERS[@]} ]; then
    echo "❌ 无效的选项"
    exit 1
fi

MY_TEAM="${TEAM_FOLDERS[$((choice-1))]}"
echo ""
echo "✅ 你选择了：$MY_TEAM"
echo ""

# 首先清除所有 skip-worktree 标记
echo "正在配置 Git 追踪设置..."
echo "  🔄 清除之前的配置..."
git ls-files -v | grep ^S | cut -c3- | xargs -r git update-index --no-skip-worktree 2>/dev/null || true

# 对其他团队文件夹设置 skip-worktree
for team in "${TEAM_FOLDERS[@]}"; do
    if [ "$team" != "$MY_TEAM" ]; then
        echo "  🔒 忽略追踪：$team/"
        find "$team" -type f -exec git update-index --skip-worktree {} \; 2>/dev/null || true
    else
        echo "  ✅ 追踪修改：$team/"
    fi
done

# 保存团队配置
echo "  💾 保存团队配置..."
echo "$MY_TEAM" > .git/team-config

# 安装 post-merge hook（自动化）
echo "  🪝 安装自动化 Git Hook..."
HOOK_SOURCE="hooks/post-merge"
HOOK_TARGET=".git/hooks/post-merge"

if [ -f "$HOOK_SOURCE" ]; then
    cp "$HOOK_SOURCE" "$HOOK_TARGET"
    chmod +x "$HOOK_TARGET"
    echo "  ✅ 已安装 post-merge hook（git pull 后自动重新配置）"
else
    echo "  ⚠️  警告：未找到 hooks/post-merge 模板文件"
fi

echo ""
echo "===================================="
echo "  ✅ 配置完成！"
echo "===================================="
echo ""
echo "现在的效果："
echo "  ✅ 所有文件夹都在本地，可以查看所有代码"
echo "  ✅ git pull 会拉取所有文件夹的更新"
echo "  ✅ git status 只显示 $MY_TEAM/ 的修改"
echo "  ✅ git add . 只会添加 $MY_TEAM/ 的修改"
echo "  ✅ 每次 git pull 后自动重新配置（无需手动运行）"
echo ""
echo "如需修改其他团队的代码，请使用："
echo "  git update-index --no-skip-worktree <文件路径>"
echo ""
echo "如需重新配置团队，再次运行此脚本即可。"
echo ""
