# Installing Superpowers for Codex

Enable Superpowers in Codex via native skill discovery and a repo-managed instruction bootstrap.

This installer is for the team-maintained fork. The default team installation source is the `openspec` branch in `joseph-bing-han/superpowers`.

## Prerequisites

- Git

## Installation

1. **Clone the superpowers repository:**
   ```bash
   git clone --branch openspec --single-branch https://github.com/joseph-bing-han/superpowers.git ~/.codex/superpowers
   ```

2. **Run the Codex installer:**
   ```bash
   bash ~/.codex/superpowers/.codex/install-codex.sh
   ```

   This installer does three things:
   - creates the `~/.agents/skills/superpowers` symlink for native skill discovery
   - configures `model_instructions_file` in `~/.codex/config.toml`
   - points that setting at the repo-managed canonical file `~/.codex/superpowers/.codex/instruction.md`

   All discoverable skills, including `spec-governed-development`, now live under the `skills/` tree at `~/.codex/superpowers/skills`. No separate root-level skill copy is required for Codex discovery.

   If `~/.codex/config.toml` already contains a different `model_instructions_file`, the installer stops instead of overwriting it. Merge that setting manually if you intentionally use a custom global instruction file.

   说明：当前 `openspec` 分支在 Superpowers 侧暴露的 OpenSpec 治理入口是 `spec-governed-development`。它负责先判断当前任务是否应进入 OpenSpec lane；它不是 `openspec-apply-change` 的改名。`openspec-apply-change` 仍然是独立的 OpenSpec 执行 skill，会在已经进入 OpenSpec lane 且准备开始实现时作为后续 skill 使用。

   **Windows (PowerShell):**
   ```powershell
   New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\.agents\skills"
   cmd /c mklink /J "$env:USERPROFILE\.agents\skills\superpowers" "$env:USERPROFILE\.codex\superpowers\skills"
   ```

   Then add this line to `$env:USERPROFILE\.codex\config.toml` if it is not already present:
   ```toml
   model_instructions_file = "C:/Users/<you>/.codex/superpowers/.codex/instruction.md"
   ```

3. **Restart Codex** (quit and relaunch the CLI) to discover the skills.

## Migrating from old bootstrap

If you installed superpowers before native skill discovery, you need to:

1. **Update the repo:**
   ```bash
   cd ~/.codex/superpowers && git pull origin openspec
   ```

2. **Run the installer** (step 2 above) — this refreshes both the skills symlink and the repo-managed `model_instructions_file` bootstrap.

3. **Remove the old bootstrap block** from `~/.codex/AGENTS.md` — any block referencing `superpowers-codex bootstrap` is no longer needed.

4. **Restart Codex.**

## Verify

```bash
ls -la ~/.agents/skills/superpowers
```

You should see a symlink (or junction on Windows) pointing to your superpowers skills directory.

Also verify the instruction bootstrap:

```bash
rg -n '^model_instructions_file = ' ~/.codex/config.toml
```

You should see it pointing at `~/.codex/superpowers/.codex/instruction.md`.

如果你在 `~/.agents/skills/superpowers` 下看到的是 `spec-governed-development`，而不是同级的 `openspec-apply-change`，这是当前安装设计的预期结果，不表示安装缺失或命名错误。

## Updating

```bash
cd ~/.codex/superpowers && git pull origin openspec
bash ~/.codex/superpowers/.codex/install-codex.sh
```

Skills update instantly through the symlink. Re-running the installer also keeps the repo-managed instruction bootstrap aligned with the current clone.

## 可选：显式 opt-in 的 endgate wrapper 过渡方案

如果你暂时还没有原生 structured carrier，但又希望把终端里的
`ENDGATE_*` 行隐藏掉，可以手动运行下面这个 wrapper：

```bash
bash ~/.codex/superpowers/.codex/codex-endgate-wrapper.sh
```

如果你平时会给 `codex` 传参数，也直接追加在后面：

```bash
bash ~/.codex/superpowers/.codex/codex-endgate-wrapper.sh --help
```

边界说明：

- 这是**显式 opt-in** 的过渡方案；只有你手动运行这个 wrapper 时才会生效
- 它**不会**修改 `install-codex.sh`
- 它**不会**替换你原本默认的 `codex` 入口
- 长期标准仍然是**原生 structured carrier**
- wrapper 只负责过滤 terminal render，不负责定义 canonical contract
- wrapper 会保持底层 `codex` 运行在 PTY/TTY 语义里，而不是把它降级成普通 pipe

如果你想把被隐藏的 packet 额外镜像到本地 sidecar 文件用于调试，可以显式开启：

```bash
CODEX_ENDGATE_WRITE_DEBUG_MIRROR=1 \
bash ~/.codex/superpowers/.codex/codex-endgate-wrapper.sh
```

默认镜像目录是仓库内的 `.codex/.runtime/`。如需临时改到别的目录，可再传：

```bash
CODEX_ENDGATE_WRITE_DEBUG_MIRROR=1 \
CODEX_ENDGATE_RUNTIME_DIR=/tmp/codex-endgate-runtime \
bash ~/.codex/superpowers/.codex/codex-endgate-wrapper.sh
```

请注意：

- `.codex/.runtime/endgate-state.jsonl` 与 `.codex/.runtime/latest-endgate.json`
  只是 **debug mirror**
- sidecar 只用于本地排障或观察 wrapper 行为
- 即使 sidecar 存在，**canonical contract 仍然必须来自 transcript 中的
  structured carrier 或合法 tail-block fallback**
- 不要把 sidecar 当成正式协议来源

## Uninstalling

```bash
rm ~/.agents/skills/superpowers
```

Optionally delete the clone: `rm -rf ~/.codex/superpowers`.
