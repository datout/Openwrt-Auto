# Openwrt-Auto

基于 GitHub Actions 的 OpenWrt 自动编译项目，支持多源码、多架构、SSH `menuconfig`、配置持久化、缓存、失败诊断和固件发布。<br>
A GitHub Actions based OpenWrt build system supporting multiple source trees, targets, SSH `menuconfig`, persistent configuration, caching, diagnostics, and firmware publishing.

> **当前项目版本 / Current release label:** `V1.1.0-beta10`<br>
> **版本事实来源 / Version source of truth:** Git tag / GitHub Release / Git commit

[![Wiki](https://img.shields.io/badge/Wiki-使用帮助-blue?style=for-the-badge)](../../wiki)
[![固件更新下载](https://img.shields.io/badge/dynamic/json?url=https%3A%2F%2Fapi.github.com%2Frepos%2Fdatout%2FOpenwrt-Auto%2Freleases%2Flatest&query=%24.name&style=for-the-badge&label=%E5%9B%BA%E4%BB%B6%E6%9B%B4%E6%96%B0%E4%B8%8B%E8%BD%BD)](https://github.com/datout/Openwrt-Auto/releases/latest)
[![Tag](https://img.shields.io/github/v/tag/datout/Openwrt-Auto?filter=a%2A&sort=date&style=for-the-badge&label=TAG)](https://github.com/datout/Openwrt-Auto/releases/latest)

## 支持源码 / Supported Sources

- LEDE
- ImmortalWrt
- OpenWrt Official
- Lienol
- X-Wrt
- MT798x

不同源码使用独立的配置、seed 和兼容逻辑，尽量避免互相影响。<br>
Each source uses its own configuration, seed, and compatibility logic to minimize cross-source impact.

## 主要功能 / Key Features

- GitHub Actions 云编译，无需本地搭建完整 OpenWrt 编译环境。<br>
  Cloud builds through GitHub Actions without requiring a full local OpenWrt build environment.
- 支持 SSH 进入 `menuconfig`，最终配置通过 `savedefconfig` 保存为最小 seed。<br>
  SSH `menuconfig` support with the final configuration persisted as a minimal seed via `savedefconfig`.
- 两阶段编译：配置与正式编译分离，第二阶段固定使用已保存配置对应的提交。<br>
  Two-stage builds separate configuration from compilation, and the second stage uses the exact saved configuration commit.
- 支持 Toolchain / ccache / `dl` 缓存，减少重复编译时间。<br>
  Toolchain, ccache, and `dl` caching reduce repeated build time.
- 编译失败自动生成诊断信息，记录真实失败包、`.config`、seed、feeds、环境和构建信息。<br>
  Failed builds automatically produce diagnostics covering the failed package, `.config`, seed, feeds, environment, and build metadata.
- 生成 `build-manifest.json`，记录源码提交、自动化仓库提交、配置、feeds 和工具链信息。<br>
  `build-manifest.json` records source commits, automation commit/ref, configuration, feeds, and toolchain information.
- `main` 分支允许正常发布；测试分支默认进入安全模式，不污染正式 Release / AutoUpdate。<br>
  `main` allows normal publishing; non-main branches use safe mode by default and do not publish production Release / AutoUpdate assets.

## 使用方法 / Usage

1. Fork 本项目。<br>
   Fork this repository.
2. 打开仓库 **Actions**。<br>
   Open **Actions** in your repository.
3. 选择需要的源码，例如 **LEDE** 或 **ImmortalWrt**。<br>
   Choose a source, such as **LEDE** or **ImmortalWrt**.
4. 按工作流选项选择分支、架构、SSH 配置等参数并运行。<br>
   Select the branch, target, SSH options, and other workflow parameters, then run the workflow.
5. 如果开启 SSH，在 `menuconfig` 完成选择并正常退出；项目会保存最终 seed，再进入正式编译。<br>
   If SSH is enabled, finish `menuconfig` and exit normally; the final seed is saved before the compilation phase starts.
6. 编译完成后从 Actions Artifacts 或 Release 下载固件。<br>
   Download the firmware from Actions Artifacts or Releases after the build completes.

详细选项和说明见 [Wiki](../../wiki)。<br>
See the [Wiki](../../wiki) for detailed options and instructions.

## Fork 同步 / Fork Synchronization

Fork 不再通过单独的版本文件判断是否落后。编译前会直接比较 Fork 当前提交与 `datout/Openwrt-Auto:main` 的 Git 提交关系。<br>
Forks no longer rely on a separate version file. Before building, the workflow compares the fork's current commit directly with `datout/Openwrt-Auto:main`.

- **上游提交是当前提交的祖先**：已同步或仅领先于上游，允许继续编译。<br>
  **Upstream is an ancestor of the current commit:** synchronized or ahead; the build is allowed.
- **当前提交是上游提交的祖先**：Fork 落后，阻止编译并提示运行 `Sync upstream`。<br>
  **Current commit is an ancestor of upstream:** the fork is behind; the build is blocked and `Sync upstream` is recommended.
- **双方都不是对方祖先**：Git 历史已分叉，阻止编译并要求先处理同步。<br>
  **Neither side is an ancestor:** the histories have diverged; the build is blocked until the Git history is synchronized.

同步入口：`Actions → Sync upstream → Run workflow`。<br>
Sync entry: `Actions → Sync upstream → Run workflow`.

## 版本体系 / Versioning

项目版本标签（例如 `V1.1.0-beta10`）用于 Release / Changelog 等人类可读的版本标识，不参与 Fork 同步判断。<br>
Project release labels such as `V1.1.0-beta10` are human-readable release identifiers for Releases / Changelog and are not used for fork synchronization.

版本事实以 **Git tag、GitHub Release 和 Git commit** 为准；构建清单也记录自动化仓库的 ref 与 commit。<br>
The source of truth is **Git tags, GitHub Releases, and Git commits**; build manifests also record the automation ref and commit.

项目不再使用旧的仓库版本元数据文件或内部脚本版本号机制。<br>
The project no longer uses the retired repository version metadata files or internal script-version mechanism.

## 分支说明 / Branches

- `main`：正式分支，可发布 GitHub Release，并可用于 AutoUpdate。<br>
  `main`: production branch; normal Releases and AutoUpdate are allowed.
- 其他分支：测试模式，默认只保留 Actions Artifacts，不发布正式 Release，也不上传 AutoUpdate 固件。<br>
  Other branches: safe test mode; Actions Artifacts are retained, while production Releases and AutoUpdate uploads are disabled by default.

如果多个源码同时使用 SSH `menuconfig` 并写回同一分支，建议串行执行，避免远端分支变化保护主动终止后完成的任务。<br>
If multiple source workflows use SSH `menuconfig` and write back to the same branch, run them serially to avoid remote-branch protection terminating a completed task.

## 更新记录 / Changelog

### V1.1.0-beta10 · 2026-10-27

- 正式编译前执行 `make download` 预下载与 hash 校验，并复用 `dl/`。<br>
  Run `make download` with hash validation before compilation and reuse `dl/`.
- 现代 ImmortalWrt 的旁路由网关、DNS、广播和关闭 DHCP 第一阶段迁到 `uci-defaults`，减少对上游 `config_generate` 文本结构的依赖。<br>
  Modern ImmortalWrt first-boot side-router gateway, DNS, broadcast, and DHCP settings use `uci-defaults`, reducing dependence on upstream `config_generate` text structure.
- `uci-defaults` 会识别已有旁路由配置并保留，避免升级时覆盖用户设置；LEDE 继续使用原逻辑。<br>
  Existing side-router settings are detected and preserved; LEDE keeps its existing path.
- 完善两阶段编译、缓存、失败诊断和构建清单。<br>
  Improved two-stage builds, caching, failure diagnostics, and build manifests.

### V1.1.0-beta9 · 2026-10-27

- 修复 ImmortalWrt 25.12 与最新 Xray / Go 工具链不匹配的问题。<br>
  Fixed ImmortalWrt 25.12 compatibility with the selected Xray / Go toolchain.
- 修复 ImmortalWrt x86_64 seed 可能静默回落到其他 target 的问题，并增加最终 `.config` 校验。<br>
  Prevented ImmortalWrt x86_64 seeds from silently falling back to another target and added final `.config` validation.
- 整理 SmartDNS 来源并完善项目自检。<br>
  Cleaned up SmartDNS sourcing and strengthened project validation.

### V1.1.0-beta8 · 2026-09

- 完成 LEDE / ImmortalWrt x86_64 实际编译回归。<br>
  Completed real LEDE / ImmortalWrt x86_64 build regression tests.
- 完成 `common.sh` 模块化，拆分 feeds、源码适配、配置、固件、定义等逻辑。<br>
  Modularized `common.sh` into feeds, source adapters, configuration, firmware, definition, and related modules.
- 完善两阶段交接、SSH seed 保存、缓存、失败诊断和构建清单。<br>
  Improved two-stage handoff, SSH seed persistence, caching, failure diagnostics, and build manifests.

## 项目自检 / Validation

仓库包含独立的项目自检工作流，用于检查 Shell / YAML 语法、模块路径、函数位置、seed / target 防漂移规则、两阶段交接、发布安全规则以及关键第三方 Action。<br>
The repository includes an independent validation workflow covering Shell / YAML syntax, module paths, function placement, seed / target drift protection, two-stage handoff, publishing safety, and critical third-party Actions.

修改核心脚本后建议先确认 **项目自检** 通过，再进行正式固件编译。<br>
After changing core scripts, run **Project Validation** successfully before starting a production firmware build.

## 许可证 / License

项目许可证与版权信息保留在 [`LICENSE`](./LICENSE) 中。<br>
License and copyright information are preserved in [`LICENSE`](./LICENSE).
