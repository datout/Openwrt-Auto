- cd openwrt && make menuconfig
- 从(https://github.com/281677160/build-actions)来的，只是把common仓库合并了。

<details>
<summary>⬆️更新说明（2025年12月25号）</summary>

 

 ---
 <br>
  2025年12月25号
 <br><br>
从(https://github.com/281677160/build-actions/issues/223)Fork来的。
 

 ---
 <br>
  2025年5月29号
 <br><br>

 1、现在开始，远程更新的固件，每次发布之前都会检查对应的tag，比如x86的是[Update-x86]，发现要发布的同类型固件，就会先删除旧的，保留一个，再发布新的，这样就不会造成积累过多
 

 ---
 <br>
  2025年5月25号
 <br><br>

 1、更换 [清理releases和workflows]  《[新的设置方法在这里](https://github.com/danshui-git/delete-releases-workflows)》


 ---
 <br>
  2025年5月24号
 <br><br>

 1、修复[释放Ubuntu磁盘空间]运行时候有报错的问题，以前用的是《[endersonmenezes](https://github.com/endersonmenezes/free-disk-space)》这个作者的源码，我拉取过来修复了一点点东西，修复过后比以前多2~3G空间吧


 ---
 <br>
  2025年5月19号
 <br><br>

 1、修复了一些小问题，增加删除缓存功能，如果编译的时候出现奇怪的错误，一般都是【ERROR: target/linux failed to build.】这样的，或者就是缓存弄的，把缓存的[√]去掉，再编译，就会先清理缓存，在编译的时候再次缓存，如果你一直去掉[√]编译，就等于一直不使用缓存


 ---
 <br>
  2025年5月11号
 <br><br>

 1、Lienol源码那里删除了几个低版本的luci分支，我在脚本当中也删除了对官方的低版本luci编译，还有删除了天灵的低版本luci的，实在是passwall和ssr-plus更新太快了，4月24号成修复不能编译NaiveProxy问题，现在又不能编译了，如果你们不需要编译这些，你们可以自己加回去编译的


 ---
 <br>
  2025年4月24号
 <br><br>

 1、修复了23.05以下不能编译的NaiveProxy问题


 ---
 <br>
  2025年4月23号
 <br><br>

 1、把脚本重新整理了一遍，23.05或者以下的版本编译passwall和ssr-plus都强制使用shadowsocks-libev编译了，使用Shadowsocks_Rust因为passwall更新太快，源码跟不上会导致编译失败，23.05以下版本强制去掉NaiveProxy
 
 2、diy-part.sh文件内容有小修改，别直接复制
 
 3、不想用这个仓库编译的话，可以使用 https://github.com/281677160/actions-openwrt 此仓库，原汁原味，啥都没修改过的


 ---
 <br>
  2025年3月30号
 <br><br>

 1、去除选择服务器CPU编译的操作，测试了一下，现在可以看到的CPU基本都全是AMD的一个型号了，如果使用了选择服务器CPU编译的话，会一直循环寻找CPU当中，不会进行编译了


 ---
<br>
  2025年3月26号
 <br><br>

 1、将《[padavanonly](https://github.com/padavanonly/immortalwrt-mt798x-24.10)》和《[hanwckf](https://github.com/hanwckf/immortalwrt-mt798x)》的仓库整合成Mt798x的了
 
 2、选择hanwckf-21.02分支编译是[hanwckf](https://github.com/hanwckf/immortalwrt-mt798x)作者仓库的openwrt-21.02分支，选择其他分支编译的是[padavanonly](https://github.com/padavanonly/immortalwrt-mt798x-24.10)作者的仓库，均为mtk闭源网卡驱动
 
 3、openwrt-23.05和hanwckf-21.02的【mt7981和mt7986】可以编译机型文件均拉取于[padavanonly](https://github.com/padavanonly/immortalwrt-mt798x-24.10)作者仓库的2410分支，也就是说【mt7981和mt7986】类的机型都同时同步与[padavanonly](https://github.com/padavanonly/immortalwrt-mt798x-24.10)作者的2410分支.

 ---
 <br>
  2025年3月25号
 <br><br>

 1、修复个别源码开启 export Enable_IPV6_function="1" 选项编译错误，个别源码编译选择ipv6会缺依赖造成编译错误
 
 2、修复个别源码开启 export Enable_IPV4_function="1"  选项编译错误，个别源码是不能完整清除IPV6来编译的，会造成编译错误
 
 3、修复低版本源码编译出现 WARNING: Makefile 'package/feeds/datout/v2raya/Makefile' has a dependency on 'kmod-nft-tproxy', which does not exist 错误

 ---
<br>
  2025年3月21号
 <br><br>

 修复脚本长期没更新导致的各种问题，增加 https://github.com/padavanonly/immortalwrt-mt798x-24.10 此仓库源码

 ---
<br>
  2024年1月14号
 <br><br>

 修复私库不能启动编译和同步更新上游仓库问题，要注意的是如果你把仓库设置成私库，在线更新固件功能是不可以使用的，因为私库是检测不到的，就没办法下载您在私库releases的固件
 
 ---
 <br>
  2023年9月2号
 <br><br>

 增加<释放Ubuntu磁盘空间>解决最近因为服务器空间不足而编译失败的问题
 
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
 
 以上机型文件仅供参考，自己在对应源码SSH连接多看吧
 ---


---

<details>
<summary>🔎各种教程</summary>
<br><br>

《[github actions编译教程](https://github.com/danshui-git/shuoming#%E7%BC%96%E8%AF%91%E6%95%99%E7%A8%8B)》

《[Amlogic、Rockchip系列固件打包设置教程](https://github.com/danshui-git/shuoming/blob/master/Amlogic.md)》

《[在线更新固件插件说明](https://github.com/danshui-git/shuoming/blob/master/%E5%AE%9A%E6%97%B6%E6%9B%B4%E6%96%B0%E6%8F%92%E4%BB%B6.md)》

<br/>
</details>

---

<details>
<summary>📳本地编译</summary>
<br><br>

《[本地Ubuntu一键编译OpenWrt固件](https://github.com/281677160/bendi)》

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
