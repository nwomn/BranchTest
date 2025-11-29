# BranchTest 项目

多团队协作的单仓库项目，使用 Git skip-worktree 实现权限隔离。

## 团队文件夹结构

- `teamA/` - A 团队负责
- `teamB/` - B 团队负责

## ✨ 核心特性

- ✅ **所有文件夹都在本地** - 可以查看、浏览所有团队的代码
- ✅ **git pull 拉取全部更新** - 所有团队的更新都会自动拉取
- ✅ **只追踪你的团队文件夹** - Git 只检测和提交你负责的修改
- ✅ **防止误提交** - 修改其他团队的代码不会出现在 `git status` 中

## 🚀 新成员配置指南（一键配置）

### 方法 1：使用自动化脚本（推荐）

```bash
# 1. 克隆仓库
git clone https://github.com/nwomn/BranchTest
cd BranchTest

# 2. 运行配置脚本
bash scripts/setup-team-tracking.sh
# 根据提示选择你的团队即可
```

### 方法 2：手动配置

**TeamA 成员**：
```bash
# 1. 克隆仓库
git clone https://github.com/nwomn/BranchTest
cd BranchTest

# 2. 标记其他团队的文件夹为 skip-worktree
find teamB -type f -exec git update-index --skip-worktree {} \;

# 3. 验证配置（修改 teamA 和 teamB 的文件，看看 git status）
echo "test" >> teamA/HelloTeamA.txt
echo "test" >> teamB/HelloTeamB.txt
git status
# 应该只显示 teamA/HelloTeamA.txt 的修改

# 4. 清理测试
git restore teamA/HelloTeamA.txt
git show HEAD:teamB/HelloTeamB.txt > teamB/HelloTeamB.txt
```

**TeamB 成员**：
```bash
git clone https://github.com/nwomn/BranchTest
cd BranchTest
find teamA -type f -exec git update-index --skip-worktree {} \;
```

### ✅ 配置后的效果

让我用实际例子演示：

```bash
# 同时修改两个团队的文件
echo "TeamA 修改" >> teamA/HelloTeamA.txt
echo "TeamB 修改" >> teamB/HelloTeamB.txt

# 查看 Git 状态 - 只显示你团队的修改！
$ git status
On branch main
Changes not staged for commit:
  modified:   teamA/HelloTeamA.txt

# teamB/ 的修改被自动忽略了！

# git add . 也只会添加你团队的文件
$ git add .
$ git status
Changes to be committed:
  modified:   teamA/HelloTeamA.txt
```

**关键点**：
- 你**可以查看**所有文件夹（用编辑器打开、阅读代码）
- 你**可以修改**其他文件夹的文件（本地测试、临时修改）
- 但这些修改**不会被 Git 追踪**，`git status` 看不到，`git add .` 也不会添加
- `git pull` **仍然会拉取**其他团队文件夹的更新

## 📝 日常工作流程

```bash
# 1. 拉取最新代码（所有团队的更新都会拉取）
git pull

# 2. 创建功能分支
git checkout -b teamA/my-feature

# 3. 修改文件（可以修改任何文件夹，但只有 teamA/ 会被追踪）
vim teamA/some-file.txt

# 你甚至可以参考或临时修改其他团队的代码
vim teamB/other-file.txt  # 这个修改不会被 Git 追踪

# 4. 查看状态（只显示 teamA/ 的修改）
git status

# 5. 提交
git add .
git commit -m "feat(teamA): 添加新功能"

# 6. 推送并创建 PR
git push origin teamA/my-feature
```

## 🔧 高级用法

### 临时需要修改其他团队的文件夹

如果需要协助其他团队修改代码并提交：

```bash
# 1. 取消 teamB 文件夹的 skip-worktree 标记
find teamB -type f -exec git update-index --no-skip-worktree {} \;

# 2. 现在可以修改和提交 teamB/ 的内容
vim teamB/some-file.txt
git add teamB/
git commit -m "feat(teamB): 协助修复bug"

# 3. 完成后，重新标记为 skip-worktree
find teamB -type f -exec git update-index --skip-worktree {} \;
```

### 查看哪些文件被标记为 skip-worktree

```bash
git ls-files -v | grep ^S
# S 开头的文件就是被标记为 skip-worktree 的文件
```

### 重新配置团队（切换团队）

```bash
# 再次运行配置脚本，选择新的团队即可
bash scripts/setup-team-tracking.sh
```

### 取消所有 skip-worktree 配置

```bash
# 取消所有 skip-worktree 标记，恢复正常 Git 行为
git ls-files -v | grep ^S | cut -c3- | xargs git update-index --no-skip-worktree
```

## 📋 分支命名规范

- TeamA: `teamA/feature-name` 或 `teamA/bugfix-name`
- TeamB: `teamB/feature-name` 或 `teamB/bugfix-name`

## 📝 提交信息规范

使用 [Conventional Commits](https://www.conventionalcommits.org/) 格式：

- `feat(teamA): 添加新功能`
- `fix(teamB): 修复bug`
- `docs(teamA): 更新文档`
- `refactor(teamB): 重构代码`

## ❓ 常见问题

### Q: 我克隆下来后能看到其他团队的文件夹吗？

**A**: 可以！所有文件夹都在本地，你可以用编辑器打开、查看、学习其他团队的代码。skip-worktree 只是让 Git **忽略追踪**这些文件的修改，文件本身完全可见。

### Q: 我不小心修改了其他团队的文件夹怎么办？

**A**: 不用担心！配置了 skip-worktree 后，这些修改不会被 Git 检测到：
- `git status` 不会显示
- `git add .` 不会添加
- `git commit` 不会提交

你的修改只在本地，不会影响仓库。

### Q: git pull 会拉取其他团队的更新吗？

**A**: 会！这正是这个方案的优势。`git pull` 会拉取所有团队文件夹的更新，你可以看到其他团队的最新代码，但你对其他团队文件的修改不会被追踪。

### Q: 如果我真的需要提交其他团队的代码怎么办？

**A**: 使用 `git update-index --no-skip-worktree` 取消标记即可。参见"高级用法"部分。

### Q: skip-worktree 和 sparse-checkout 有什么区别？

**A**:
- **sparse-checkout**：隐藏其他文件夹，工作目录中看不到
- **skip-worktree**：所有文件夹都可见，但 Git 忽略标记文件的修改

我们使用 skip-worktree 是因为你需要**查看所有代码**，而不是隐藏它们。

### Q: 新加入的文件会被自动标记吗？

**A**: 不会。如果其他团队在他们的文件夹中添加了新文件，这些新文件不会自动被标记为 skip-worktree。你需要：

**方法 1**：运行配置脚本重新配置
```bash
bash scripts/setup-team-tracking.sh
```

**方法 2**：手动标记新文件
```bash
find teamB -type f -exec git update-index --skip-worktree {} \;
```

建议定期（比如每周）重新运行一次配置脚本，确保新文件也被正确标记。

### Q: 这个配置会影响其他开发者吗？

**A**: 不会。skip-worktree 是**本地配置**，不会提交到仓库，也不会影响其他开发者。每个人都需要自己配置。

## 📚 更多信息

- [Git update-index 文档](https://git-scm.com/docs/git-update-index)
- [Conventional Commits 规范](https://www.conventionalcommits.org/)

---

**提示**：记得在第一次克隆后立即运行配置脚本，否则可能会意外提交其他团队的代码！
