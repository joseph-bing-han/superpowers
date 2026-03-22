# 团队 Codex 安装来源定制设计

**日期：** 2026-03-22 13:41  
**线路：** Superpowers-only  
**状态：** 设计已确认，待进入 implementation plan

---

## 1. 背景

当前仓库的 `openspec` 分支已经承载了团队自己的 Superpowers 定制内容，但 Codex 安装链路仍然保留 upstream `obra/superpowers` 的默认入口。

这会导致团队成员即使按照文档进行本地安装，也会拉取 upstream 的 `main`，而不是团队维护的定制分支，最终无法直接获得团队内部约定的技能、文档和交互规则。

本次工作需要把 Codex 安装链路切换到团队 fork `joseph-bing-han/superpowers` 的 `openspec` 分支，使团队成员可以直接按文档完成本地安装。

---

## 2. 目标

### 2.1 本次目标

1. 让 Codex 快速安装入口默认指向 `joseph-bing-han/superpowers` 的 `openspec` 分支。
2. 让 Codex 详细安装文档中的 clone / update 命令明确绑定到团队 fork 与 `openspec` 分支。
3. 在 Codex 相关文档中说明该安装来源是团队定制版入口。
4. 消除 Codex 安装链路中仍指向 `obra/superpowers` 的关键文案。

### 2.2 非目标

1. 不修改 OpenCode 安装入口。
2. 不修改 Gemini CLI 安装入口。
3. 不对整仓所有外链进行全面品牌替换。
4. 不改动实际技能内容或安装机制本身，只改 Codex 安装入口与文案。

---

## 3. 范围

本次只纳入以下文件：

- `README.md` 中的 Codex 快装入口
- `docs/README.codex.md`
- `.codex/INSTALL.md`

如果在这条链路中发现辅助链接仍明显指向 upstream，也一并修正，但只限于 Codex 相关说明，不扩展到其它平台文档。

---

## 4. 方案

### 4.1 快速安装入口

将 `README.md` 与 `docs/README.codex.md` 中的“Tell Codex”提示统一改为：

```text
Fetch and follow instructions from https://raw.githubusercontent.com/joseph-bing-han/superpowers/refs/heads/openspec/.codex/INSTALL.md
```

这样用户在 Codex 中直接复制该提示时，就会命中团队 fork 的 `openspec` 分支。

### 4.2 详细安装命令

将 `docs/README.codex.md` 与 `.codex/INSTALL.md` 中的 clone 命令改为：

```bash
git clone --branch openspec --single-branch https://github.com/joseph-bing-han/superpowers.git ~/.codex/superpowers
```

将 update 命令改为：

```bash
cd ~/.codex/superpowers && git pull origin openspec
```

这样可以避免团队成员因为远端默认分支不同而拉到非团队定制分支。

### 4.3 团队来源说明

在 `docs/README.codex.md` 与 `.codex/INSTALL.md` 中增加简短说明，明确：

1. 该安装来源为团队定制版。
2. 默认应安装 `openspec` 分支。
3. 除非有特殊要求，否则不要改回 upstream 默认入口。

### 4.4 辅助链接

将 `docs/README.codex.md` 中的：

- `Report issues`
- `Main documentation`

改到团队 fork，避免团队成员沿着帮助入口又回到 upstream 仓库。

---

## 5. 验收标准

本次完成后，应满足：

1. `README.md` 的 Codex 快装入口不再指向 `obra/superpowers`。
2. `docs/README.codex.md` 的 raw 安装地址、clone 命令、update 命令均指向团队 fork `openspec`。
3. `.codex/INSTALL.md` 的 clone / update 命令均指向团队 fork `openspec`。
4. `docs/README.codex.md` 中的帮助链接指向团队 fork。
5. 使用搜索命令检查这 3 个文件时，不再出现 Codex 安装链路中的 upstream 地址残留。

---

## 6. 测试策略

本次不涉及可执行代码逻辑，验证以文档链路检查为主：

1. 用 `rg` 检查上述目标文件中是否仍残留 `obra/superpowers` 的 Codex 安装入口。
2. 逐个检查 raw 地址、clone 命令、update 命令与帮助链接。
3. 确认只改动 Codex 安装链路，不误伤 OpenCode / Gemini 文档。
