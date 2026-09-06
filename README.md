## 使用帮助
[![Wiki](https://img.shields.io/badge/Wiki-使用帮助-blue?style=for-the-badge)](../../wiki)

> `V1.1.0-beta6` 建议先在 `next` 测试分支验证，测试流程见 [`NEXT_TEST.md`](NEXT_TEST.md)。

 ##### 固件更新下载:

[![固件更新下载](https://img.shields.io/badge/dynamic/json?url=https%3A%2F%2Fapi.github.com%2Frepos%2Fdatout%2FOpenwrt-Auto%2Freleases%2Flatest&query=%24.name&style=for-the-badge&label=%E5%9B%BA%E4%BB%B6%E6%9B%B4%E6%96%B0%E4%B8%8B%E8%BD%BD)](https://github.com/datout/Openwrt-Auto/releases/latest)
[![Tag](https://img.shields.io/github/v/tag/datout/Openwrt-Auto?filter=a%2A&sort=date&style=for-the-badge&label=TAG)](https://github.com/datout/Openwrt-Auto/releases/latest)


<details>
<summary>⬆️更新说明（2026年9月6号）</summary>

 ---
 <br>
  2026年9月6号（V1.1.0-beta6 / next 测试分支）
 <br><br>
  1.完成 common.sh 模块化收尾：Diy_definition → definition.sh，Diy_prevent → prevent.sh，两个大函数均保持原样迁移
  2.迁移时增加函数正文 SHA256 对比，确保移动前后逐字一致；common.sh 只保留模块加载、Diy_menu* 调度和入口
  3.同步修正项目自检中的旧函数位置假设，新增 definition/prevent 模块加载、唯一性和 common.sh 行数边界检查
  4.本轮不改两阶段、seed、编译诊断、缓存、AutoUpdate、发布协议及 Diy_definition/Diy_prevent 内部行为
 ---
 <br>
  2026年9月6号（V1.1.0-beta5 / next 测试分支）
 <br><br>
  1.继续低风险拆分 common.sh：Diy_variable/Diy_feedsconf → bootstrap.sh，Diy_checkout → checkout.sh，Diy_management → finalize.sh
  2.本轮仍保持函数体原样迁移，不改外部 Diy_menu/Diy_menu5/Diy_menu6/Diy_feedsconf 调用接口，也不改 Diy_definition/Diy_prevent 行为
  3.项目自检的 bash -n 改为自动发现 common/lib/*.sh，避免新增模块后因手工名单遗漏导致未检查
  4.历史迁移模块的 ShellCheck 也改为自动发现：error 级问题阻断，warning/info/style 持续记录但不影响低风险迁移回归
  5.两阶段、seed、编译诊断、Manifest、缓存、AutoUpdate 和固件发布继续冻结
 ---
 <br>
  2026年9月5号（V1.1.0-beta4 / next 测试分支）
 <br><br>
  1.修正 build-manifest：内核系列从 target Makefile 回退识别，Go 版本从运行时或 OpenWrt golang Makefile 获取，避免空字段
  2.过滤 feeds/*.tmp 及非独立 Git worktree，避免临时目录错误记录为 LEDE 主源码 commit；Manifest schema 提升到 2
  3.继续低风险拆分 common.sh：Diy_partsh/Diy_scripts/Diy_profile → config.sh，Diy_firmware → firmware.sh，gitsvn → git.sh
  4.大块 Diy_management/Diy_definition/Diy_prevent 暂不移动；两阶段、seed、编译诊断、缓存和 AutoUpdate 继续冻结
 ---
 <br>
  2026年9月5号（V1.1.0-beta3 / next 测试分支）
 <br><br>
 1.开始拆分长期膨胀的 common.sh：新增 common/lib/core.sh、feeds.sh、sources.sh，保持原有外部调用接口不变
 2.基础日志/变量/上游版本检测迁移到 core.sh；datout feed 冲突处理与公共依赖整理迁移到 feeds.sh
 3.Lede、Lienol、ImmortalWrt、Official、XWrt、MT798X 的源码专用调整迁移到 sources.sh，减少不同源码逻辑互相影响的风险
 4.本轮不改两阶段交接、seed、编译诊断、固件发布和 AutoUpdate 核心逻辑，优先验证模块化本身不引入行为变化
 5.项目自检增加模块边界、函数加载和新 lib ShellCheck 检查；common.sh ACTIONS_VERSION 提升到 2.9.0

 ---
 <br>
  2026年9月5号（V1.1.0-beta2 / next 测试分支）
 <br><br>
 1.编译失败后先单线程 V=s 定位真实失败包，仅在 xray-core/gVisor 对应错误时执行 Go 1.26 专用修复，避免无关包失败时误清理或重编 Xray
 2.新增失败诊断 Artifact：自动保存主编译日志、真实失败目标 V=sc 日志、.config、seed、packageinfo、feeds 和运行环境信息
 3.新增 build-manifest.json，记录自动化提交、上游源码 commit、feeds commit、配置哈希、目标和工具版本，方便比较两次构建差异
 4.缓存标识改为源码 + 分支 + TARGET_BOARD + TARGET_SUBTARGET；继续复用 cachewrtbuild 自带的 toolchain hash 和 ccache 恢复逻辑
 5.将 actions/checkout 升级到 v5、actions/upload-artifact 升级到 v7，适配 GitHub Actions Node.js 24；自检增加 ShellCheck 和 actionlint 观察项
 6.beta1 的两阶段交接和 next 安全模式保持不变，本轮不改 seed 持久化核心逻辑

 ---
 <br>
  2026年9月4号（V1.1.0-beta1 / next 测试分支）
 <br><br>
 1.保留“两阶段编译”架构，但重构阶段交接：第一阶段只保存最终 seed，再通过 workflow_dispatch 显式触发独立编译
 2.移除交接过程中的 compile.yml 动态改写、relevance/start 触发文件和 git push --force，改为普通 push + 冲突即停止
 3.第二阶段固定检出第一阶段保存 seed 后的精确提交 SHA，避免分支后续提交导致配置漂移
 4.新增测试分支安全模式：非 main 分支强制关闭 Release 发布和在线更新云端上传，便于 next 分支安全验证
 5.新增同源配置并发锁和项目自检流程，并将官方 actions/upload-artifact 固定到 v4

 ---
 <br>
  2026年9月4号
 <br><br>
 1.重构 SSH menuconfig 的 seed 刷新机制，不再依赖“本次 y→n”差异判断
 2.seed 改用 Kconfig 原生 savedefconfig 生成，仅持久化真正需要的显式选择，自动依赖不再写回下一次 seed
 3.新增 seed 回放校验：重新展开 minimal seed 并与本次最终 .config 对比，一致后才允许覆盖；同时清理已确认的 Nikki/mihomo 历史孤儿

 ---
 <br>
  2026年9月3号
 <br><br>
 1.改进编译失败诊断，自动识别真实失败的软件包及 host 编译目标
 2.失败后使用单线程详细日志重跑真实报错目标，避免二次错误掩盖根因

 ---
 <br>
  2026年7月25号
 <br><br>
 1.适配新版 AutoUpdate 环境配置与固定发布标签
 2.修复固件更新页面打开缓慢、环境变量乱码和卡顿
 3.适配 x86 Legacy/UEFI 在线更新固件识别

 ---
 <br>
  2026年4月20号
 <br><br>
 1.修复autoupdate
 2.增加编译报错后打印错误日志

 ---
 <br>
  2026年2月24号
 <br><br>
 修复用Imm源码编译某些插件报错问题

 ---
 <br>
  2026年2月23号
 <br><br>
 编译下载时增加aria2c加快下载（优化云编译默认拉去国内源慢）
 
 ---
 <br>
  2026年1月24号
 <br><br>
加了FW4开关，更新了AdGuardhome，等 

 ---
 <br>
  2025年12月25号
 <br><br>
基于上游脚本二次维护（已移除对外部个人仓库的依赖）。
 
 
 ---
 <br>
  2023年6月16号
 <br><br>
 
 修复个别源码不能编译N1固件的问题
 
 有些源码的【armvirt】文件夹已经改成了【armsr】，机型文件也跟着改变的，查看源码文件夹在对应源码分支的[target/linux]里面查看，要么有【armvirt】，要么就是【armsr】
 
 以前的机型文件一般为：
 ````
CONFIG_TARGET_armvirt=y
CONFIG_TARGET_armvirt_64=y
CONFIG_TARGET_armvirt_64_Default=y
 ````
 
 现在的机型文件有些改为：
 ````
CONFIG_TARGET_armvirt=y
CONFIG_TARGET_armvirt_64=y
CONFIG_TARGET_armvirt_64_DEVICE_generic=y
 ````
 
 如果源码文件为【armsr】的，机型文件一般为：
 ````
CONFIG_TARGET_armsr=y
CONFIG_TARGET_armsr_armv8=y
CONFIG_TARGET_armsr_armv8_DEVICE_generic=y
 ````
</details> 
 
 ---



<details>
<summary>🔎教程</summary>
<br><br>

[![Wiki](https://img.shields.io/badge/Wiki-使用帮助-blue)](../../wiki)

<br/>
</details>




---

 ### 鸣谢！
 感谢以下各位大佬（排名无分先后）<br />
 
 [`coolsnowwolf`](https://github.com/coolsnowwolf/lede)
 [`Lienol`](https://github.com/Lienol/openwrt)
 [`immortalwrt`](https://github.com/immortalwrt/immortalwrt)
 [`openwrt`](https://github.com/openwrt/openwrt)
 [`x-wrt`](https://github.com/x-wrt/x-wrt)
 [`P3TERX`](https://github.com/P3TERX/Actions-OpenWrt)
 [`Hyy2001X`](https://github.com/Hyy2001X/AutoBuild-Actions-Template)
 [`dhxh`](https://github.com/dhxh/Openwrt-Build)
 [`ophub`](https://github.com/ophub/amlogic-s9xxx-openwrt)
 [`nicholas-opensource`](https://github.com/nicholas-opensource/OpenWrt-Autobuild)
 [`hx210`](https://github.com/hx210/Actions-OpenWrt)
 [`hyird`](https://github.com/hyird/EasyTier)
 [`World Peace`](#/README.md)
 [`klever1988`](https://github.com/klever1988/cachewrtbuild)
 [`actions`](https://github.com/actions/upload-artifact)
 [`svenstaro`](https://github.com/svenstaro/upload-release-action)
 [`jerrykuku`](https://github.com/jerrykuku/luci-theme-argon)
