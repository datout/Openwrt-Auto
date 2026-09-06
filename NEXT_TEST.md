# next 分支测试清单 — V1.1.0-beta5

V1.1.0-beta5 在 beta1~beta4 已验证通过的两阶段构建、seed、编译诊断、Manifest 和前两轮模块化基础上，继续做**低风险纯迁移**。本轮重点是把启动/源码整理阶段继续从 `common.sh` 拆出，并把项目自检改成自动发现 `common/lib/*.sh`，避免以后新增模块时漏检。

## 1. 项目自检必须先通过

`项目自检` workflow 应确认：

- `common/common.sh` 与全部 `common/lib/*.sh` 自动通过 `bash -n`，不再靠手工维护模块名单
- `core.sh / feeds.sh / sources.sh` 与编译诊断脚本继续执行严格 ShellCheck
- 其余历史迁移模块执行 ShellCheck：`error` 级问题阻断；warning/info/style 继续显示但不阻断
- `bootstrap.sh / checkout.sh / finalize.sh` 都能被 `common.sh` 正常 source
- `Diy_variable / Diy_feedsconf / Diy_checkout / Diy_management` 只存在一份定义，且已不在 `common.sh` 中
- beta1~beta4 的两阶段、seed、编译诊断和 Manifest 回归检查继续通过

## 2. 本轮模块迁移

本轮只移动原函数，不修改函数内部行为：

- `common/lib/bootstrap.sh`
  - `Diy_variable`
  - `Diy_feedsconf`
- `common/lib/checkout.sh`
  - `Diy_checkout`
- `common/lib/finalize.sh`
  - `Diy_management`

外部调用保持不变：

```bash
bash common.sh Diy_menu
bash common.sh Diy_menu5
bash common.sh Diy_menu6
bash common.sh Diy_feedsconf
```

`Diy_definition` 和 `Diy_prevent` 仍留在 `common.sh`，等 beta5 完整回归后再单独处理，避免一次迁移过大。

## 3. 第一阶段回归

建议继续用 Lede x86_64：

1. 源码与 feeds 正常下载
2. Argon、datout、datouttheme 等插件源整理正常
3. Web2 / Telegram 正常，Telegram 命令完整显示 `cd openwrt && make menuconfig`
4. `make menuconfig` 正常
5. seed minimal + 回放校验正常
6. `Diy_menu5` 正常执行，不出现 `Diy_management: command not found`
7. 第一阶段普通 push + workflow_dispatch 第二阶段正常

重点留意是否出现：

```text
Diy_variable: command not found
Diy_feedsconf: command not found
Diy_checkout: command not found
Diy_management: command not found
No such file or directory: common/lib/...
```

## 4. 第二阶段回归

第二阶段仍应满足：

- `GIT_REFNAME=next`
- `SAFE_BRANCH_MODE=true`
- 精确 `SEED_COMMIT`
- Release / AutoUpdate 云端上传关闭
- 正式编译成功
- `build-manifest-*` Artifact 正常生成
- Manifest schema 仍为 2，kernel / Go / feeds 信息保持 beta4 的正确结果

## 5. 本轮继续冻结

- 两阶段 workflow_dispatch 交接
- seed_finalize 核心算法
- compile_firmware 错误诊断算法
- cachewrtbuild 策略
- AutoUpdate 发布协议
- 固件命名
- `Diy_definition / Diy_prevent` 内部行为

这些部分已实际验证或耦合较高，本轮不混入行为变化。
