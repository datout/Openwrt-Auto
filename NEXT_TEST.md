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

- 两阶段交接的 seed / SEED_COMMIT 核心协议（本轮仅修正可观测性与超时）
- seed_finalize / savedefconfig
- 固件命名
- 编译失败诊断
- build-manifest schema
- Beta7 feeds priority 和 `dl/` 缓存 key

## 6. 第一阶段交接状态回归

针对第一阶段已触发第二阶段、但 GitHub UI 仍长期显示“自定义配置”运行中的问题：

- SSH menuconfig、最终 seed、配置快照上传、触发第二阶段必须显示为独立顶层步骤
- `need` composite 内不再嵌套 debugger 或 upload-artifact
- 第二阶段标题必须携带第一阶段 run number 与唯一 `HANDOFF_ID`
- GitHub dispatch 请求最多等待 60 秒，不得无限卡住
- dispatch 兼容 HTTP 200（返回运行地址）与历史 HTTP 204
- 网络在服务端接收 POST 后断开时，只查询确认已有第二阶段，不盲目重发 POST，避免重复编译
- 第二阶段已出现后，第一阶段应在数分钟内正常结束为 Success

## Runner 环境回归

- [ ] 日志显示工作目录为 `/workdir`，不得出现 `mkdir -p /`、`chown ... /` 或 `/openwrt`。
- [ ] “全部依赖安装完毕”后依次显示“编译依赖脚本执行完成”“时区设置完成”“编译工作目录已准备”。
- [ ] 部署环境步骤正常结束并进入下载源码。
- [ ] 编译期间 Runner 不再出现无日志失联；如仍失联，保留完整日志继续区分 GitHub 平台故障与 OOM。
