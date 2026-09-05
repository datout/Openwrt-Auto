# next 分支测试清单 — V1.1.0-beta3

V1.1.0-beta3 在 beta1/beta2 已验证通过的两阶段构建、seed 持久化、编译诊断基础上，开始进行第一阶段代码模块化。本轮目标是**降低 common.sh 耦合，但不改变现有构建行为**。

## 1. 项目自检必须先通过

`项目自检` workflow 应确认：

- `common/common.sh`、`common/lib/*.sh` 均通过 `bash -n`
- 新增 `core.sh / feeds.sh / sources.sh` 通过 ShellCheck
- common.sh 能正确 source 三个模块
- `TIME / variable / detect_upstream_luci_edition` 不再重复定义在 common.sh
- 各源码专用 `Diy_*` 函数能从 `sources.sh` 正常加载
- `Diy_feed_postprocess` 能从 `feeds.sh` 正常加载

## 2. 第一阶段行为不应变化

从 `next` 运行任意源码（建议先 Lede x86_64）：

1. 正常下载源码和 feeds
2. Web2/SSH 正常出现
3. `make menuconfig` 正常使用
4. seed 继续使用 Kconfig minimal seed + 回放校验
5. 第一阶段仍以普通 push 保存 seed，并 workflow_dispatch 第二阶段

如果第一阶段在 feeds 处理阶段报错，重点查看是否发生在 `Diy_feed_postprocess`。

## 3. datout feed 与插件行为检查

Lede 测试至少确认：

- `datout` / `datouttheme` feed 正常更新
- PassWall、Nikki、SSR Plus 等当前选中的插件仍由预期 feed 提供
- 不出现同名包重复安装/重复定义错误
- Rust、packr、node-prebuilt、tproxy 兼容处理仍正常

本轮只把原 common.sh 中已有逻辑移动到 `common/lib/feeds.sh`，没有设计新的包优先级规则。

## 4. 源码专用逻辑检查

`common/lib/sources.sh` 现在承载：

- `Diy_COOLSNOWWOLF`
- `Diy_LIENOL`
- `Diy_IMMORTALWRT`
- `Diy_XWRT`
- `Diy_OFFICIAL`
- `Diy_MT798X`

第一轮建议继续用已经验证最充分的 Lede；Lede 通过后再选择一个 ImmortalWrt/Official 做快速回归。

## 5. 第二阶段不回归

第二阶段仍必须看到：

- `GIT_REFNAME: next`
- `SAFE_BRANCH_MODE: true`
- 精确 `SEED_COMMIT`
- Release / AutoUpdate 云端上传关闭
- 成功时生成 `build-manifest-*` Artifact
- 失败时生成 `build-diagnostics-*` Artifact

## 6. beta3 暂时不做的事情

本轮**不改**：

- 两阶段 workflow_dispatch 交接
- seed_finalize 核心算法
- compile_firmware 错误诊断算法
- 缓存策略
- AutoUpdate 发布协议
- 固件命名

这些已经在前两轮验证成功，模块化期间先冻结，避免一次改动过大。
