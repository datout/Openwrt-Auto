# V1.1.0-beta1 / next 分支测试说明

本版本用于在不影响 `main` 的情况下验证两阶段编译交接重构。

## 安全策略

- `next` 等非 `main` 分支会自动进入安全模式。
- 强制关闭普通 Release 发布。
- 强制关闭 AutoUpdate 在线更新云端上传。
- seed 只提交回当前测试分支，不会写入 `main`。
- 交接过程中不再使用 `git push --force`。
- 如果远端分支在 `menuconfig` 期间被其他提交更新，本次交接直接停止，不自动 rebase、不覆盖远端。

## 新的两阶段流程

1. 第一阶段下载源码并执行 Web2/SSH `make menuconfig`。
2. 使用 Kconfig minimal seed 保存本次最终配置。
3. 仅将 `build/<源码>/seed/<机型>` 提交回当前分支。
4. 通过 GitHub `workflow_dispatch` API 显式启动 `compile.yml`。
5. 第二阶段检出第一阶段记录的精确 `SEED_COMMIT` 后开始正式编译。

不再通过修改 `compile.yml`、`relevance/start` 或 force push 来触发第二阶段。

## 测试时应看到

第一阶段结束：

```text
第二阶段固定使用提交：<commit sha>
独立编译已触发：Lede-master-x86_64
```

第二阶段开始：

```text
配置来源提交: <同一个 commit sha>
源码类型: Lede / COOLSNOWWOLF
配置文件: x86_64
```

在 `next` 分支还应看到：

```text
测试分支安全模式：已强制关闭 Release 发布和在线更新云端上传
```

## REPO_TOKEN

当前项目仍兼容原有 `REPO_TOKEN` 设计。测试账号的 token 需要能够：

- 写入仓库内容（保存 seed）
- 调用 GitHub Actions workflow dispatch（触发第二阶段）

## 回滚

如果测试不满意，直接删除 `next` 分支即可，`main` 不受影响。
