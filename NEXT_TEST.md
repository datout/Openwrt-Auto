# next 分支测试清单 — V1.1.0-beta4

V1.1.0-beta4 在 beta1/beta2/beta3 已验证通过的两阶段构建、seed 持久化、编译诊断和第一轮模块化基础上，继续做**低风险模块拆分**，并修正 build-manifest 中已实际观察到的空字段和临时 feed 噪声。

## 1. 项目自检必须先通过

`项目自检` workflow 应确认：

- `common/common.sh` 与 `common/lib/*.sh` 均通过 `bash -n`
- `git.sh / config.sh / firmware.sh` 能被 common.sh 正常 source
- `gitsvn / Diy_partsh / Diy_scripts / Diy_profile / Diy_firmware` 能正常加载
- 上述函数已经不再重复定义在 common.sh
- beta1~beta3 的两阶段、seed、诊断检查仍继续通过

## 2. build-manifest 修复检查

成功编译后的 `build-manifest-*.zip` 中应满足：

- `target.kernel_patchver` 不再为空；Lede x86_64 当前应显示类似 `6.12`
- `host.go` 不再为空；若 Runner 没有全局 Go，会回退显示 OpenWrt golang 声明版本
- 新增 `toolchain.openwrt_go_declared` 和 `toolchain.go_runtime`
- `feeds` 中不再出现 `datout.tmp / packages.tmp / luci.tmp ...`
- 真正的 datout、luci、packages、routing、telephony 等 feed commit 继续存在

## 3. 第二批 common.sh 模块化

本轮只移动原函数，不改变函数内部行为：

- `common/lib/config.sh`
  - `Diy_partsh`
  - `Diy_scripts`
  - `Diy_profile`
- `common/lib/firmware.sh`
  - `Diy_firmware`
- `common/lib/git.sh`
  - `gitsvn`

大块的 `Diy_management / Diy_definition / Diy_prevent` 暂时仍留在 common.sh，等 beta4 实机回归后再拆，避免单轮改动过大。

## 4. 完整回归

建议继续用 Lede x86_64：

1. Web2 / Telegram 正常
2. `make menuconfig` 正常
3. feeds 与插件列表正常
4. seed minimal + 回放校验正常
5. 第一阶段普通 push + workflow_dispatch 第二阶段正常
6. 第二阶段 `GIT_REFNAME=next`、`SAFE_BRANCH_MODE=true`
7. 正式编译成功
8. `build-manifest-*` Artifact 正常生成并满足第 2 节要求

## 5. 本轮继续冻结

- 两阶段交接机制
- seed_finalize 核心算法
- compile_firmware 错误诊断算法
- cachewrtbuild 策略
- AutoUpdate 发布协议
- 固件命名

这些部分已经实际验证通过，本轮不混入额外行为变化。
