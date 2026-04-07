# 为 OpenCode 安装 Superpowers

通过 OpenCode 原生插件机制启用 Superpowers，并确保安装源指向当前团队维护的 GitHub 仓库与分支。

本安装说明对应当前团队维护的 fork。OpenCode 默认安装源应使用 `joseph-bing-han/superpowers` 的 `openspec` 分支，这样才能拿到当前仓库里的最新修改以及新增的 skills / bootstrap 内容。

## 前置要求

- 已安装 [OpenCode.ai](https://opencode.ai)

## 安装

把 superpowers 加到你的 `opencode.json` 的 `plugin` 数组中（可以是全局配置，也可以是项目级配置）：

```json
{
  "plugin": [
    "superpowers@git+https://github.com/joseph-bing-han/superpowers.git#openspec"
  ]
}
```

然后重启 OpenCode。

当前安装方式会自动完成以下事情：

- 从 `joseph-bing-han/superpowers` 的 `openspec` 分支安装插件
- 加载仓库内的 `.opencode/plugins/superpowers.js`
- 在运行时自动把仓库里的 `skills/` 目录加入 OpenCode 的 skills 搜索路径
- 自动注入 `using-superpowers` bootstrap
- 让当前仓库新增的 skills（例如 `spec-governed-development`）和后续新增内容在重启后可被发现

说明：当前 `openspec` 分支在 Superpowers 侧暴露的 OpenSpec 治理入口是 `spec-governed-development`。它负责先判断当前任务是否应进入 OpenSpec lane；它不是 `openspec-apply-change` 的改名。`openspec-apply-change` 仍然是独立的 OpenSpec 执行 skill，会在已经进入 OpenSpec lane 且准备开始实现时作为后续 skill 使用。

## 从旧安装方式迁移

如果你之前使用的是旧的 symlink / 本地 clone / upstream 仓库安装方式，请先清理旧配置：

```bash
# 移除旧的插件或技能软链接
rm -f ~/.config/opencode/plugins/superpowers.js
rm -rf ~/.config/opencode/skills/superpowers

# 可选：删除旧的本地 clone
rm -rf ~/.config/opencode/superpowers
```

然后检查你的 `opencode.json`：

1. 如果原来写的是 `obra/superpowers`，改成当前团队 fork：
   `joseph-bing-han/superpowers.git#openspec`
2. 如果你曾手动为 superpowers 配置过 `skills.paths`，并且它指向旧 clone 或旧目录，删除那段旧配置，避免继续加载过期内容
3. 重启 OpenCode

## 验证

可以让 OpenCode 直接列出技能：

```text
use skill tool to list skills
```

你应该能看到来自 superpowers 的技能列表。

也可以进一步验证新增内容是否可见：

```text
use skill tool to load superpowers/spec-governed-development
```

如果能成功加载，说明当前安装已经指向团队维护 fork，并且新的 skill 内容已经生效。

注意：`using-superpowers` 是通过插件自动注入的 bootstrap。通常不需要再次手动加载它。

## 使用

在 OpenCode 中，优先使用原生 `skill` 工具：

```text
use skill tool to list skills
use skill tool to load superpowers/brainstorming
use skill tool to load superpowers/spec-governed-development
```

## 更新

默认情况下，OpenCode 在重启后会重新解析 git 插件源。

只要你的 `opencode.json` 仍然指向：

```json
{
  "plugin": [
    "superpowers@git+https://github.com/joseph-bing-han/superpowers.git#openspec"
  ]
}
```

重启 OpenCode 后，就会继续跟随当前 fork 的 `openspec` 分支。

如果你想固定到某个提交，可以把 `#openspec` 改成具体 commit SHA。

## 故障排查

### 插件没有加载

1. 检查日志：`opencode run --print-logs "hello" 2>&1 | grep -i superpowers`
2. 确认 `opencode.json` 里的插件地址使用的是 `joseph-bing-han/superpowers.git#openspec`
3. 确认你使用的是较新的 OpenCode 版本

### 技能找不到

1. 先用 `skill` 工具列出当前已发现的 skills
2. 确认插件已加载成功
3. 检查是否仍有旧的 `skills.paths` 或旧目录覆盖了当前安装内容
4. 重新启动 OpenCode

### 工具映射说明

当 skills 里提到 Claude Code 的工具时，在 OpenCode 中按下面方式理解：

- `TodoWrite` → `todowrite`
- `Task`（带 subagents）→ OpenCode 的 `@mention` 子代理机制
- `Skill` tool → OpenCode 原生 `skill` 工具
- 文件操作类工具 → OpenCode / 当前环境提供的原生文件工具

## 获取帮助

- 问题反馈：https://github.com/joseph-bing-han/superpowers/issues
- OpenCode 说明文档：https://github.com/joseph-bing-han/superpowers/blob/openspec/docs/README.opencode.md
