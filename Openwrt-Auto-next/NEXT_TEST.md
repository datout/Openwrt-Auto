# next 分支测试清单 — V1.1.0-beta8

Beta8 不再重构编译核心，重点收紧 GitHub Actions、ImmortalWrt host 依赖、AutoUpdate 发布顺序和第三方 Action 稳定性。

## 1. 项目自检

- 必须整体 Success
- Actionlint 存在历史观察项时只应出现黄色 Warning，不应再出现红色 `Process completed with exit code 1`
- beta8 自检需确认 debugger/free-disk/cachewrtbuild/AutoUpdate release-action 已固定到指定 commit
- AutoUpdate 步骤必须是先发布、后清理

## 2. ImmortalWrt node host 依赖

当 packages feed 中 Makefile 引用 `node-yarn/host` 或 `node-pnpm/host`，而当前 feed 又没有对应目录时，应自动补充：

```text
package/compat/node-yarn
package/compat/node-pnpm
```

ImmortalWrt `make menuconfig` 不应再出现 cloudreve/filebrowser/sub-web 缺失 `node-yarn/host` / `node-pnpm/host` 的 warning。

## 3. LEDE + ImmortalWrt 回归

两个源都需确认：

- Web2 / Telegram 正常，命令完整显示 `cd openwrt && make menuconfig`
- seed/savedefconfig 回放正常
- 第二阶段精确 SEED_COMMIT 正常
- Beta7 datout priority + `dl/` + ccache 行为不变
- 正式编译成功
- build-manifest Artifact 正常

## 4. AutoUpdate 发布回归

`next` 分支仍由 `SAFE_BRANCH_MODE=true` 强制禁止 Release / AutoUpdate 上传，因此 Beta8 先验证 Workflow 顺序和静态自检。

合并 main 前再实际验证：

```text
上传新 AutoUpdate 固件
        ↓
上传成功
        ↓
清理同机型旧资产
        ↓
本次新固件不能被误删
```

## 5. 本轮继续冻结

- 两阶段交接协议
- seed_finalize / savedefconfig
- 固件命名
- 编译失败诊断
- build-manifest schema
- Beta7 feeds priority 和 `dl/` 缓存 key
