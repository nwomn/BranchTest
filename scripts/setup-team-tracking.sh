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
echo "  ✅ git sync 会拉取所有文件夹的更新"
echo "  ✅ 但 git status 只显示你团队文件夹的修改"
echo "  ✅ 防止误提交其他团队的代码"
echo ""

# 检查是否在 Git 仓库中
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo "❌ 错误：当前目录不是 Git 仓库"
    exit 1
fi

# 检查是否有已保存的团队文件夹配置
TEAMS_CONFIG=".git/team-folders"

if [ -f "$TEAMS_CONFIG" ]; then
    echo "检测到已有团队文件夹配置："
    cat "$TEAMS_CONFIG" | while read folder; do
        echo "  - $folder"
    done
    echo ""
    read -p "是否使用此配置？(y/n，选 n 重新配置): " use_existing

    if [ "$use_existing" = "y" ] || [ "$use_existing" = "Y" ]; then
        TEAM_FOLDERS=($(cat "$TEAMS_CONFIG"))
    fi
fi

# 如果没有配置，让用户选择团队文件夹
if [ -z "$TEAM_FOLDERS" ] || [ ${#TEAM_FOLDERS[@]} -eq 0 ]; then
    echo "请选择哪些文件夹是团队文件夹（每个团队负责一个文件夹）"
    echo ""

    # 获取所有顶级目录（排除常见的非团队目录）
    ALL_DIRS=($(ls -d */ 2>/dev/null | sed 's|/||' | grep -v -E '^(\.git|node_modules|vendor|dist|build|target|\.idea|\.vscode|__pycache__|\.cache|scripts|hooks)$' || true))

    if [ ${#ALL_DIRS[@]} -eq 0 ]; then
        echo "❌ 错误：未找到任何文件夹"
        echo "请先创建团队文件夹，例如："
        echo "  mkdir frontend backend devops"
        exit 1
    fi

    echo "发现以下文件夹："
    for i in "${!ALL_DIRS[@]}"; do
        echo "  $((i+1))) ${ALL_DIRS[$i]}"
    done
    echo ""
    echo "请输入团队文件夹的编号（用空格分隔，例如: 1 2 3）"
    read -p "> " choices

    TEAM_FOLDERS=()
    for choice in $choices; do
        if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le ${#ALL_DIRS[@]} ]; then
            TEAM_FOLDERS+=("${ALL_DIRS[$((choice-1))]}")
        fi
    done

    if [ ${#TEAM_FOLDERS[@]} -lt 2 ]; then
        echo "❌ 错误：至少需要选择 2 个团队文件夹"
        exit 1
    fi

    # 保存团队文件夹配置
    printf "%s\n" "${TEAM_FOLDERS[@]}" > "$TEAMS_CONFIG"
    echo ""
    echo "✅ 已保存团队文件夹配置"
fi

echo ""
echo "团队文件夹："
for i in "${!TEAM_FOLDERS[@]}"; do
    echo "  $((i+1))) ${TEAM_FOLDERS[$i]}"
done
echo ""

# 选择自己的团队
read -p "请输入【你的团队】编号 (1-${#TEAM_FOLDERS[@]}): " my_choice

if ! [[ "$my_choice" =~ ^[0-9]+$ ]] || [ "$my_choice" -lt 1 ] || [ "$my_choice" -gt ${#TEAM_FOLDERS[@]} ]; then
    echo "❌ 无效的选项"
    exit 1
fi

MY_TEAM="${TEAM_FOLDERS[$((my_choice-1))]}"
echo ""
echo "✅ 你选择了：$MY_TEAM"
echo ""

# 首先清除所有 skip-worktree 标记
echo "正在配置 Git 追踪设置..."
echo "  🔄 清除之前的配置..."
SKIP_FILES=$(git ls-files -v | grep ^S | cut -c3-)
if [ -n "$SKIP_FILES" ]; then
    echo "$SKIP_FILES" | xargs git update-index --no-skip-worktree 2>/dev/null || true
fi

# 对其他团队文件夹设置 skip-worktree
for team in "${TEAM_FOLDERS[@]}"; do
    if [ "$team" != "$MY_TEAM" ]; then
        echo "  🔒 忽略追踪：$team/"
        find "$team" -type f -exec git update-index --skip-worktree {} \; 2>/dev/null || true
    else
        echo "  ✅ 追踪修改：$team/"
    fi
done

# 保存我的团队配置
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

# 安装 git sync 别名
echo "  🔗 安装 git 命令别名..."
REPO_ROOT=$(git rev-parse --show-toplevel)
git config alias.sync "!bash $REPO_ROOT/scripts/sync.sh"
git config alias.switch-branch "!bash $REPO_ROOT/scripts/switch-branch.sh"
echo "  ✅ git sync        - 安全同步（避免冲突）"
echo "  ✅ git switch-branch - 安全切换分支"

echo ""
echo "===================================="
echo "  ✅ 配置完成！"
echo "===================================="
echo ""
echo "现在的效果："
echo "  ✅ 所有文件夹都在本地，可以查看所有代码"
echo "  ✅ git status 只显示 $MY_TEAM/ 的修改"
echo "  ✅ git add . 只会添加 $MY_TEAM/ 的修改"
echo ""
echo "⭐ 推荐使用的命令："
echo "  git sync                  # 同步远程更新（避免冲突）"
echo "  git switch-branch <分支>  # 安全切换分支"
echo ""
echo "如需重新配置团队，再次运行此脚本即可。"
echo ""
