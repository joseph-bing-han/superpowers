# Task 4 重复 Key Tail Block 修复记录

## 任务背景

当前 `tests/shared/workflow-contract-helpers.sh` 已经只会解析文件末尾连续的
machine-readable tail block，但当同一个最终 tail block 中同一 key 重复出现时，
仍会把最后一个值当成有效值。

这会导致如下坏情况被误判为合法：

```text
REVIEW_VERDICT: APPROVED | CHANGES_REQUIRED
REVIEW_VERDICT: CHANGES_REQUIRED
```

以及：

```text
BLOCKING_ISSUE_COUNT: non-negative integer
BLOCKING_ISSUE_COUNT: 2
```

## 红灯构造

本次使用临时文件构造了两个合成样例，并在修复前直接 source 当前 helper：

1. `REVIEW_VERDICT` 在同一个最终 tail block 内重复出现
2. `BLOCKING_ISSUE_COUNT` 在同一个最终 tail block 内重复出现

修复前的实际结果：

- `extract_named_field` 会分别读出 `CHANGES_REQUIRED` 和 `2`
- `assert_named_field` 会错误返回通过

这证明原实现存在“最后一个值胜出”的漏洞。

## 修复规则

本次仅修改 `tests/shared/workflow-contract-helpers.sh`，保留
`print_machine_readable_tail_block` 的“只解析最终连续 tail block”逻辑不变，
只收紧同名字段提取规则：

- 同一个 key 在最终 tail block 中必须出现且只能出现一次
- 出现 0 次：按缺失处理
- 出现 2 次及以上：按无效处理
- 只有出现次数恰好为 1 次时，才返回其 value

`assert_named_field` 与 `extract_named_field` 现在都统一走上述规则。

## 本地验证

已执行：

```bash
bash -n tests/shared/workflow-contract-helpers.sh \
  tests/claude-code/test-helpers.sh \
  tests/claude-code/test-document-review-system.sh
```

结果：通过

已执行 smoke：

1. 重复 `REVIEW_VERDICT` 样例
2. 重复 `BLOCKING_ISSUE_COUNT` 样例
3. 正常单值 tail block 样例

结果：

- 重复 `REVIEW_VERDICT`：`extract_named_field` 读空，`assert_named_field` 失败
- 重复 `BLOCKING_ISSUE_COUNT`：`extract_named_field` 读空，`assert_named_field` 失败
- 正常单值 tail block：`extract_named_field` 返回真实值，`assert_named_field` 通过

已执行：

```bash
git diff --check -- tests/shared/workflow-contract-helpers.sh \
  tests/claude-code/test-helpers.sh \
  tests/claude-code/test-document-review-system.sh
```

结果：通过

## 改动文件

- `tests/shared/workflow-contract-helpers.sh`
- `docs/2026-03-23-09-55-task4-duplicate-tail-key-fix.md`
