# Froom Package Publisher

一个用于管理 froom 相关包发布的 Dart 脚本工具。

## 功能

- 从 `version.txt` 读取版本号
- 检查根目录 `CHANGELOG.md` 中是否包含对应版本的更新日志
- 自动同步 CHANGELOG 条目到各个子项目
- 按照发布顺序更新各个包的版本号：`froom_annotation` -> `froom_generator` -> `froom_common` -> `froom`
- 将组件间的 path 依赖更新为版本依赖
- 创建 release 分支并提交更改
- 按顺序发布包到 pub.dev
- 自动等待依赖包在 pub.dev 上可用后再发布下一个包
- 支持重试发布，自动跳过已发布的包
- 智能分支管理，记住原始分支并在完成后恢复
- 支持 dry-run 模式用于测试

## 使用方法

### 安装依赖

```bash
cd publish-kit
dart pub get
```

### 运行命令

```bash
# 显示帮助
dart bin/publish_kit.dart -h

# 更新版本号（dry-run 模式）
dart bin/publish_kit.dart -c update-version --dry-run

# 拷贝README.md到子项目（dry-run 模式）
dart bin/publish_kit.dart -c copy-readme --dry-run

# 创建版本标签并合并到主分支（dry-run 模式）
dart bin/publish_kit.dart -c tag --dry-run

# 更新依赖关系（dry-run 模式）
dart bin/publish_kit.dart -c update-deps --dry-run

# 创建 release 分支并提交
dart bin/publish_kit.dart -c commit-release --dry-run

# 发布包到 pub.dev
dart bin/publish_kit.dart -c publish --dry-run

# 执行完整流程
dart bin/publish_kit.dart -c all --dry-run

# 实际运行（移除 --dry-run）
dart bin/publish_kit.dart -c all
```

## 执行顺序

脚本的完整流程按照以下顺序执行：

1. **update-version** - 更新包版本号并同步CHANGELOG
2. **copy-readme** - 拷贝根目录README.md到子项目
3. **tag** - 提交更改、合并到main分支并创建版本标签 
4. **update-deps** - 更新组件间依赖关系
5. **commit-release** - 创建release分支并提交
6. **publish** - 按顺序发布包到pub.dev

## Tag 命令功能

`tag` 命令会执行以下操作：

1. **提交当前更改** - 如果有未提交的更改，自动提交
2. **切换到main分支** - 自动切换到main分支
3. **合并当前分支** - 如果不在main分支，将当前分支合并到main
4. **创建版本标签** - 创建格式为 `v{version}` 的标签（如 `v2.0.3`）
5. **推送到远程** - 推送main分支和新创建的标签到远程仓库

这确保了版本标签总是基于main分支的最新状态创建。

## Copy-Readme 命令功能

`copy-readme` 命令会执行以下操作：

1. **读取根目录README.md** - 从项目根目录读取README.md文件
2. **更新语言链接路径** - 自动将语言链接（如 `[中文](README_zh.md)`）更新为指向根目录的相对路径（如 `[中文](../README_zh.md)`）
3. **复制到子项目** - 将处理后的README.md内容复制到所有子项目目录
4. **覆盖现有文件** - 如果子项目已存在README.md，会被完全替换

### 语言链接自动处理

脚本会自动识别并处理以下格式的语言链接：
- `[中文](README_zh.md)` → `[中文](../README_zh.md)`
- `[Español](README_es.md)` → `[Español](../README_es.md)`
- `[Français](README_fr.md)` → `[Français](../README_fr.md)`
- 支持任何 `README_xx.md` 或 `README_xx_XX.md` 格式的语言文件

这确保了所有子项目的README.md与根目录保持一致，同时语言链接能正确指向根目录的对应文件，便于包发布时提供统一的多语言文档。

## 包发布顺序

发布包时会按照以下顺序：

1. `froom_annotation` - 注解包，无依赖
2. `froom_generator` - 代码生成器，依赖 froom_annotation
3. `froom_common` - 通用库，依赖 froom_annotation 和 froom_generator
4. `froom` - 主包，依赖前面所有包

## 分步执行

- `dart bin/publish_kit.dart -c update-version` - 仅更新包版本号
- `dart bin/publish_kit.dart -c copy-readme` - 仅拷贝根目录README.md到子项目
- `dart bin/publish_kit.dart -c tag` - 仅提交更改、合并到main并创建版本标签
- `dart bin/publish_kit.dart -c update-deps` - 仅更新组件间依赖关系
- `dart bin/publish_kit.dart -c commit-release` - 仅创建 release 分支并提交  
- `dart bin/publish_kit.dart -c publish` - 仅发布包到 pub.dev

## 发布机制

脚本会自动处理包的依赖关系：

1. **发布顺序控制**：按照依赖关系顺序发布包
2. **依赖等待机制**：发布一个包后，会通过 `dart pub get` 循环检测下一个包的依赖是否在 pub.dev 上可用
3. **超时保护**：最长等待 15 分钟（30 次尝试 × 30 秒），避免无限等待
4. **实时反馈**：显示等待进度和尝试次数
5. **重试支持**：自动跳过已发布的包，支持中断后重新运行
6. **分支管理**：自动管理 release 分支，完成后恢复到原始分支
7. **分支监控**：在等待依赖过程中定期检查分支，防止用户意外切换分支影响发布

## CHANGELOG 管理

脚本会自动管理 CHANGELOG.md：

1. **版本检查**：检查根目录 `CHANGELOG.md` 中是否包含要发布的版本条目
2. **自动同步**：将根目录的 CHANGELOG 条目复制到各个子项目的 CHANGELOG.md
3. **格式保持**：保持原有的 Markdown 格式和结构
4. **重复检测**：如果子项目已包含该版本条目，则跳过

### CHANGELOG 格式要求

根目录的 `CHANGELOG.md` 应包含如下格式：

```markdown
# Changelog

## 2.0.2

### Changes

* Bug fixes and improvements
* Updated dependencies

## 2.0.1
...
```

## 注意事项

- 确保在运行前已经更新了 `version.txt` 文件
- **必须在根目录 `CHANGELOG.md` 中添加对应版本的条目**，否则脚本会报错
- 建议先使用 `--dry-run` 模式测试
- 发布前确保所有测试通过
- 发布包需要有 pub.dev 的发布权限
- 发布过程可能需要较长时间，请耐心等待依赖包在 pub.dev 上同步
- **支持重试**：如果发布过程中断，可以重新运行相同命令，脚本会自动跳过已发布的包
- **分支保护**：脚本会记住当前分支，完成后自动切换回原来的分支
- **分支监控**：在长时间等待依赖过程中，每次重试前都会检查并确保在正确的 release 分支上
