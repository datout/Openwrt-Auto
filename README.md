# Openwrt-Auto

基于 GitHub Actions 的 OpenWrt 自动编译项目，支持多源码、多架构、SSH `menuconfig`、配置持久化、缓存、失败诊断和固件发布。

> 当前项目版本：`V1.1.0-beta9`  
> 内部脚本版本：`2.12.1`

[![Wiki](https://img.shields.io/badge/Wiki-使用帮助-blue?style=for-the-badge)](../../wiki)
[![固件更新下载](https://img.shields.io/badge/dynamic/json?url=https%3A%2F%2Fapi.github.com%2Frepos%2Fdatout%2FOpenwrt-Auto%2Freleases%2Flatest&query=%24.name&style=for-the-badge&label=%E5%9B%BA%E4%BB%B6%E6%9B%B4%E6%96%B0%E4%B8%8B%E8%BD%BD)](https://github.com/datout/Openwrt-Auto/releases/latest)
[![Tag](https://img.shields.io/github/v/tag/datout/Openwrt-Auto?filter=a%2A&sort=date&style=for-the-badge&label=TAG)](https://github.com/datout/Openwrt-Auto/releases/latest)

## 支持源码

- LEDE
- ImmortalWrt
- OpenWrt Official
- Lienol
- X-Wrt
- MT798x

不同源码使用独立的配置、seed 和兼容逻辑，尽量避免互相影响。

## 主要功能

- GitHub Actions 云编译，无需本地搭建完整 OpenWrt 编译环境。
- 支持 SSH 进入 `menuconfig`，最终配置通过 `savedefconfig` 保存为最小 seed。
- 两阶段编译：配置与正式编译分离，第二阶段固定使用已保存配置对应的提交。
- 支持 Toolchain / ccache / `dl` 缓存，减少重复编译时间。
- 编译失败自动生成诊断信息，记录真实失败包、`.config`、seed、feeds、环境和构建信息。
- 生成 `build-manifest.json`，方便比较不同构建的源码、feeds、配置和工具链。
- `main` 分支允许正常发布；测试分支默认进入安全模式，不污染正式 Release / AutoUpdate。
- Fork 会通过 `UPSTREAM_VERSION` 检查是否落后于上游，版本变化时提示先执行 `Sync upstream`。

## 使用方法

1. Fork 本项目。
2. 打开仓库 **Actions**。
3. 选择需要的源码，例如 **LEDE** 或 **ImmortalWrt**。
4. 按工作流选项选择分支、架构、SSH 配置等参数并运行。
5. 如果开启 SSH，在 `menuconfig` 完成选择并正常退出；项目会保存最终 seed，再进入正式编译。
6. 编译完成后从 Actions Artifacts 或 Release 下载固件。

详细选项和说明见 [Wiki](../../wiki)。

## Fork 更新

项目根目录的：

```text
UPSTREAM_VERSION
```

用于判断 Fork 是否落后于 `datout/Openwrt-Auto`。

当上游版本更新后，旧 Fork 在编译前会检测到版本不一致，并提示运行：

```text
Actions → Sync upstream → Run workflow
```

`common/common.sh` 中的 `ACTIONS_VERSION` 属于项目内部脚本版本，与 `UPSTREAM_VERSION` 用途不同。

## 分支说明

- `main`：正式分支，可发布 GitHub Release，并可用于 AutoUpdate。
- 其他分支：测试模式，默认只保留 Actions Artifacts，不发布正式 Release，也不上传 AutoUpdate 固件。

如果多个源码同时使用 SSH `menuconfig` 并写回同一分支，建议串行执行，避免远端分支变化保护主动终止后完成的任务。

## 更新记录

### V1.1.0-beta9 · 2026-10-27

- 修复 ImmortalWrt 25.12 与最新 Xray / Go 工具链不匹配的问题：25.12 使用与上游稳定分支匹配的 Xray，LEDE / master 保持新版逻辑。
- 修复 ImmortalWrt x86_64 seed 可能静默回落到其他 target 的问题，并增加最终 `.config` 校验。
- 修正 `savedefconfig` 对 x86_64 默认项省略导致的误判；minimal seed 允许省略默认值，展开后的完整配置继续严格校验。
- 适配 ImmortalWrt 25.12 网络生成方式变化，恢复旁路由网关 / DNS 等设置。
- 整理 SmartDNS 来源：LEDE / ImmortalWrt 使用持续同步的 SmartDNS 包，避免 Theme 分支旧包导致 hash mismatch。
- 统一内部版本检查，项目自检不再硬编码具体 `ACTIONS_VERSION`。
- `UPSTREAM_VERSION` 提升到 `V1.1.0-beta9`，让 Fork 能识别本轮更新。

### V1.1.0-beta8 · 2026-09

- 完成 LEDE / ImmortalWrt x86_64 实际编译回归。
- 完成 `common.sh` 模块化，拆分 feeds、源码适配、配置、固件、定义等逻辑。
- 完善两阶段交接、SSH seed 保存、缓存、失败诊断和 `build-manifest.json`。
- 增加非 `main` 分支安全模式和项目自检。
- 优化 GitHub Actions 步骤名称、Runner 环境和工作目录处理。

### 2026 年早期更新

- 增加 FW4、AdGuardHome、aria2 下载加速和编译错误日志输出。
- 持续适配 LEDE、ImmortalWrt、OpenWrt 等上游源码变化。

## 项目自检

仓库包含独立的项目自检工作流，用于检查：

- Shell / YAML 基础语法。
- 模块路径、函数位置和版本一致性。
- seed / target 防漂移规则。
- 两阶段交接和发布安全规则。
- 关键第三方 Action 与构建流程假设。

修改核心脚本后建议先确认 **项目自检** 通过，再进行正式固件编译。

## 鸣谢

感谢以下项目及开发者：

[`coolsnowwolf/lede`](https://github.com/coolsnowwolf/lede) ·
[`immortalwrt/immortalwrt`](https://github.com/immortalwrt/immortalwrt) ·
[`openwrt/openwrt`](https://github.com/openwrt/openwrt) ·
[`Lienol/openwrt`](https://github.com/Lienol/openwrt) ·
[`x-wrt/x-wrt`](https://github.com/x-wrt/x-wrt) ·
[`P3TERX/Actions-OpenWrt`](https://github.com/P3TERX/Actions-OpenWrt) ·
[`ophub/amlogic-s9xxx-openwrt`](https://github.com/ophub/amlogic-s9xxx-openwrt) ·
[`klever1988/cachewrtbuild`](https://github.com/klever1988/cachewrtbuild) ·
[`jerrykuku/luci-theme-argon`](https://github.com/jerrykuku/luci-theme-argon)

以及本项目使用到的其他 OpenWrt 社区项目和 GitHub Actions。
