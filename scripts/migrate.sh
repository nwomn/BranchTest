#!/bin/bash
# 迁移脚本：将团队协作配置复制到目标项目

set -e

echo "===================================="
echo "  团队协作配置迁移工具"
echo "===================================="
echo ""

# 检查参数
if [ -z "$1" ]; then
    echo "用法: bash migrate.sh <目标项目路径>"
    echo ""
    echo "例如:"
    echo "  bash migrate.sh /path/to/your-project"
    echo "  bash migrate.sh ~/my-real-project"
    echo ""
    exit 1
fi

TARGET_DIR="$1"

# 检查目标目录是否存在
if [ ! -d "$TARGET_DIR" ]; then
    echo "❌ 错误：目标目录不存在: $TARGET_DIR"
    exit 1
fi

# 检查是否是 Git 仓库
if [ ! -d "$TARGET_DIR/.git" ]; then
    echo "❌ 错误：目标目录不是 Git 仓库: $TARGET_DIR"
    exit 1
fi

echo "目标项目: $TARGET_DIR"
echo ""

# 获取脚本所在目录（BranchTest 项目目录）
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SOURCE_DIR="$( cd "$SCRIPT_DIR/.." && pwd )"

echo "源项目: $SOURCE_DIR"
echo ""

# 确认迁移
read -p "确认要迁移配置到上述目标项目吗？(y/n): " confirm
if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
    echo "已取消"
    exit 0
fi

echo ""
echo "开始迁移..."
echo ""

# 创建目录
echo "1️⃣  创建目录结构..."
mkdir -p "$TARGET_DIR/scripts"
mkdir -p "$TARGET_DIR/hooks"

# 复制文件
echo "2️⃣  复制配置脚本..."
cp "$SOURCE_DIR/scripts/setup-team-tracking.sh" "$TARGET_DIR/scripts/"
chmod +x "$TARGET_DIR/scripts/setup-team-tracking.sh"
echo "   ✅ scripts/setup-team-tracking.sh"

cp "$SOURCE_DIR/scripts/sync.sh" "$TARGET_DIR/scripts/"
chmod +x "$TARGET_DIR/scripts/sync.sh"
echo "   ✅ scripts/sync.sh"

cp "$SOURCE_DIR/scripts/switch-branch.sh" "$TARGET_DIR/scripts/"
chmod +x "$TARGET_DIR/scripts/switch-branch.sh"
echo "   ✅ scripts/switch-branch.sh"

echo "3️⃣  复制 Git Hook..."
cp "$SOURCE_DIR/hooks/post-merge" "$TARGET_DIR/hooks/"
chmod +x "$TARGET_DIR/hooks/post-merge"
echo "   ✅ hooks/post-merge"

# 处理 .gitignore
echo "4️⃣  处理 .gitignore..."
if [ -f "$TARGET_DIR/.gitignore" ]; then
    echo "   ⚠️  目标项目已有 .gitignore，跳过（需要手动合并）"
    echo "   💡 提示：可以从 $SOURCE_DIR/.gitignore 复制需要的内容"
else
    cp "$SOURCE_DIR/.gitignore" "$TARGET_DIR/.gitignore"
    echo "   ✅ .gitignore"
fi

echo ""
echo "===================================="
echo "  ✅ 迁移完成！"
echo "===================================="
echo ""
echo "已复制的文件："
echo "  📁 scripts/setup-team-tracking.sh"
echo "  📁 scripts/sync.sh"
echo "  📁 scripts/switch-branch.sh"
echo "  📁 hooks/post-merge"
if [ ! -f "$TARGET_DIR/.gitignore" ]; then
    echo "  📁 .gitignore"
fi
echo ""
echo "下一步："
echo "  1. cd $TARGET_DIR"
echo "  2. git add scripts/ hooks/ .gitignore"
echo "  3. git commit -m \"feat: 添加多团队协作配置\""
echo "  4. git push"
echo ""
echo "团队成员使用："
echo "  bash scripts/setup-team-tracking.sh   # 首次配置"
echo "  git sync                               # 同步更新（避免冲突）"
echo ""
