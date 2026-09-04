## 使用帮助
[![Wiki](https://img.shields.io/badge/Wiki-使用帮助-blue?style=for-the-badge)](../../wiki)

> `V1.1.0-beta1` 建议先在 `next` 测试分支验证，测试流程见 [`NEXT_TEST.md`](NEXT_TEST.md)。

 ##### 固件更新下载:

[![固件更新下载](https://img.shields.io/badge/dynamic/json?url=https%3A%2F%2Fapi.github.com%2Frepos%2Fdatout%2FOpenwrt-Auto%2Freleases%2Flatest&query=%24.name&style=for-the-badge&label=%E5%9B%BA%E4%BB%B6%E6%9B%B4%E6%96%B0%E4%B8%8B%E8%BD%BD)](https://github.com/datout/Openwrt-Auto/releases/latest)
[![Tag](https://img.shields.io/github/v/tag/datout/Openwrt-Auto?filter=a%2A&sort=date&style=for-the-badge&label=TAG)](https://github.com/datout/Openwrt-Auto/releases/latest)


<details>
<summary>⬆️更新说明（2026年9月4号）</summary>

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
