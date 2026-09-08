# V1.1.0-beta8 验证记录

Beta8 不再重构编译核心，重点完成 GitHub Actions 稳定性、ImmortalWrt host 依赖兼容、AutoUpdate 发布顺序、项目自检和分支安全策略收尾。

## 1. 已完成验证

- ✅ 项目自检整体 Success
- ✅ LEDE x86_64 正常编译
- ✅ LEDE SSH `menuconfig` 正常
- ✅ LEDE 非 SSH 自动编译正常
- ✅ LEDE Cache 成功恢复，日志确认 `Cache restored successfully` / `Toolchain building skipped`
- ✅ ImmortalWrt 25.12 x86_64 正常编译
- ✅ ImmortalWrt SSH `menuconfig` 正常
- ✅ ImmortalWrt + `luci-theme-argon` 正常编译
- ✅ seed / `savedefconfig` 回放正常
- ✅ 第二阶段精确 `SEED_COMMIT` 正常
- ✅ next 安全模式正常，只上传 Artifacts，不发布 Release / AutoUpdate 云端固件
- ✅ 同步 main 后再次运行项目自检，全绿

## 2. ImmortalWrt node host 依赖兼容

当 packages feed 的 Makefile 引用 `node-yarn/host` 或 `node-pnpm/host`，而当前 feed 又没有对应目录时，自动补充：

```text
package/compat/node-yarn
package/compat/node-pnpm
```

兼容包来自 ImmortalWrt `openwrt-24.10` packages 分支，只在确认当前源码确实缺失对应 host 包时补充，不覆盖已有实现。

## 3. 分支安全策略

### main

允许正常执行：

```text
GitHub Release
AutoUpdate 在线更新固件上传
```

### next / 其他非 main 分支

自动设置安全模式：

```text
UPLOAD_RELEASE=false
UPDATE_FIRMWARE_ONLINE=false
```

测试固件仍可通过 GitHub Artifacts 获取。

`armsr_rootfs_tar_gz` / aarch 流程同样受安全模式约束，不能从非 main 分支旁路发布 Release。

## 4. 并发行为

不同源码可以独立编译，但多个源码同时进行 SSH `menuconfig` 并向同一 Git 分支保存 seed 时，如果先完成的任务已经推进远端分支，后完成的任务会触发远端变化保护并主动停止。

这是防止自动 merge / force push 覆盖配置的安全保护。实际使用建议 LEDE、ImmortalWrt 的 SSH 配置串行进行。

## 5. B8 最终自检覆盖

- Workflow / composite Action YAML
- `common/`、`build/` Shell 语法
- 本地 Action 路径
- `SOURCE_CODE -> Diy_*` 函数映射
- `CONFIG_FILE -> seed` 映射
- 模块迁移后的函数加载、唯一性与调用位置
- stale grep / 旧硬编码路径
- `BUILD_CONTEXT` 两阶段参数交接
- `SEED_COMMIT` 精确 checkout
- 禁止 trigger 使用 force push
- `actions_version` 一致性
- next / main 安全模式
- 第三方 Action 固定 commit

## 6. 合并 main 后最终发布回归

B8 在 `next` 中不会执行真实 Release / AutoUpdate 云端上传。合并到 `main` 后建议使用 LEDE x86_64 做一次最终正式发布回归，确认：

```text
正式编译成功
    ↓
GitHub Release 上传成功
    ↓
AutoUpdate 新固件上传成功
    ↓
再清理同机型旧资产
    ↓
本次新固件不会被误删
```

除上述 main 发布回归外，Beta8 的 LEDE / ImmortalWrt 核心编译测试已完成。
