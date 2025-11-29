# BranchTest 项目

多团队协作的单仓库项目，使用 Git Sparse Checkout 实现权限隔离。

## 团队文件夹结构

- `teamA/` - A 团队负责
- `teamB/` - B 团队负责

## 新成员配置指南

### 🚀 第一次克隆仓库（必须按团队配置）

**TeamA 成员**：
```bash
# 1. 克隆仓库（会下载所有文件）
git clone https://github.com/nwomn/BranchTest
cd BranchTest

# 2. 启用 sparse-checkout（cone 模式）
git sparse-checkout init --cone

# 3. 设置只追踪 teamA/ 文件夹
git sparse-checkout set teamA/

# 4. 验证配置
git sparse-checkout list
# 应该输出：teamA/
```

**TeamB 成员**：
```bash
git clone https://github.com/nwomn/BranchTest
cd BranchTest
git sparse-checkout init --cone
git sparse-checkout set teamB/
```

### ✅ 配置后的效果

- ✅ **所有文件都在本地**，可以用编辑器查看所有文件夹的内容
- ✅ **但 Git 只追踪你团队的文件夹**，修改其他文件夹不会被 Git 检测
- ✅ **`git status` 只显示你负责的文件夹**的修改
- ✅ **`git add .` 只会添加你负责的文件夹**的修改
- ✅ **防止误提交**其他团队的代码

### 📝 日常工作流程

```bash
# 1. 创建功能分支（建议使用团队前缀）
git checkout -b teamA/my-feature

# 2. 修改文件
# 你可以修改任何文件夹，但只有 teamA/ 的修改会被 Git 追踪
vim teamA/some-file.txt
vim teamB/other-file.txt  # 修改了，但 Git 不会检测到

# 3. 查看状态
git status
# 只会显示：modified: teamA/some-file.txt
# teamB/ 的修改不会出现

# 4. 提交
git add .
git commit -m "feat(teamA): 添加新功能"

# 5. 推送并创建 PR
git push origin teamA/my-feature
```

### 🔧 高级用法

#### 临时需要修改其他团队的文件夹

如果需要协助其他团队修改代码：

```bash
# 临时添加 teamB/ 到追踪列表
git sparse-checkout add teamB/

# 现在可以修改和提交 teamB/ 的内容
vim teamB/some-file.txt
git add teamB/
git commit -m "feat(teamB): 协助修复bug"

# 完成后，恢复只追踪 teamA/
git sparse-checkout set teamA/
```

#### 查看当前追踪的文件夹

```bash
git sparse-checkout list
```

#### 禁用 sparse-checkout（追踪所有文件）

```bash
git sparse-checkout disable
# 之后所有文件夹的修改都会被追踪
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

## 🔐 代码审查

所有修改都需要通过 Pull Request 提交。根据 CODEOWNERS 配置：
- 修改 `teamA/` 的 PR 会自动指定 TeamA 负责人审查
- 修改 `teamB/` 的 PR 会自动指定 TeamB 负责人审查

## ❓ 常见问题

### Q: 我克隆下来后看不到其他团队的文件夹？

**A**: 这是正常的。在 sparse-checkout 模式下，虽然文件都已下载，但工作区只显示你配置追踪的文件夹。你可以通过文件管理器或编辑器的文件浏览器查看所有文件。

**注意**：实际上，所有文件都已经下载到本地了，只是 Git 工作区（Working Directory）中只显示你配置的文件夹。你依然可以通过绝对路径访问其他文件夹的文件。

### Q: 我不小心修改了其他团队的文件夹怎么办？

**A**: 不用担心，配置了 sparse-checkout 后，Git 不会追踪其他文件夹的修改。即使你修改了，`git status` 也不会显示，`git add .` 也不会添加。

### Q: 如何取消 sparse-checkout 配置？

**A**: 运行 `git sparse-checkout disable` 即可恢复正常模式，之后所有文件夹的修改都会被追踪。

### Q: sparse-checkout 会减少磁盘占用吗？

**A**: 不会。在 cone 模式下，所有文件都会下载到本地。这个配置的目的是**限制 Git 追踪范围**，而不是减少磁盘占用。

如果你需要减少磁盘占用，可以在克隆时使用：
```bash
git clone --depth=1 https://github.com/nwomn/BranchTest
```

## 📚 更多信息

- [Git Sparse Checkout 文档](https://git-scm.com/docs/git-sparse-checkout)
- [Conventional Commits 规范](https://www.conventionalcommits.org/)
- [GitHub CODEOWNERS 文档](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-code-owners)

---

**注意**：记得在第一次克隆后立即配置 sparse-checkout，否则可能会意外提交其他团队的代码！
