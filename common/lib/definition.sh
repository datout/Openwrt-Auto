#!/usr/bin/env bash
# shellcheck shell=bash
# final system/profile definition helper; sourced by common.sh.

function Diy_definition() {
cd ${HOME_PATH}
source "${DIY_PT2_SH}"
# 获取源码文件的IP
lan="/set network.\$1.netmask/a"
ipadd="$(grep "ipaddr:-" "${GENE_PATH}" |grep -v 'addr_offset' |grep -Eo "[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+")"
netmas="$(grep "netmask:-" "${GENE_PATH}" |grep -Eo "[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+")"
opname="$(grep "hostname=" "${GENE_PATH}" |grep -v '\$hostname' |cut -d "'" -f2)"
if [[ -n "$(grep "set network.\${1}6.device" "${GENE_PATH}")" ]]; then
  ifnamee="uci set network.ipv6.device='@lan'"
  set_add="uci add_list firewall.@zone[0].network='ipv6'"
else
  ifnamee="uci set network.ipv6.ifname='@lan'"
  set_add="uci set firewall.@zone[0].network='lan ipv6'"
fi

if [[ "${SOURCE_CODE}" == "OFFICIAL" ]] && [[ "${REPO_BRANCH}" == "openwrt-19.07" ]]; then
  devicee="uci set network.ipv6.device='@lan'"
fi

if [[ "${Ipv4_ipaddr}" == "0" ]] || [[ -z "${Ipv4_ipaddr}" ]]; then
  echo "不进行,修改后台IP"
elif [[ -n "${Ipv4_ipaddr}" ]]; then
  Kernel_Pat="$(echo ${Ipv4_ipaddr} |grep -Eo "[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+")"
  ipadd_Pat="$(echo ${ipadd} |grep -Eo "[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+")"
  if [[ -n "${Kernel_Pat}" ]] && [[ -n "${ipadd_Pat}" ]]; then
     sed -i "s/${ipadd}/${Ipv4_ipaddr}/g" "${GENE_PATH}"
     echo "openwrt后台IP[${Ipv4_ipaddr}]修改完成"
   else
     TIME r "因IP获取有错误，后台IP更换不成功，请检查IP是否填写正确，如果填写正确，那就是获取不了源码内的IP了"
   fi
fi

if [[ "${Netmask_netm}" == "0" ]] || [[ -z "${Netmask_netm}" ]]; then
  echo "不进行,子网掩码修改"
elif [[ -n "${Netmask_netm}" ]]; then
  Kernel_netm="$(echo ${Netmask_netm} |grep -Eo "[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+")"
  ipadd_mas="$(echo ${netmas} |grep -Eo "[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+")"
  if [[ -n "${Kernel_netm}" ]] && [[ -n "${ipadd_mas}" ]]; then
     sed -i "s/${netmas}/${Netmask_netm}/g" "${GENE_PATH}"
     echo "子网掩码[${Netmask_netm}]修改完成"
   else
     TIME r "因子网掩码获取有错误，子网掩码设置失败，请检查IP是否填写正确，如果填写正确，那就是获取不了源码内的IP了"
  fi
fi

if [[ ! "${Default_theme}" == "0" ]] && [[ -n "${Default_theme}" ]]; then
  if [[ `grep -c "${Default_theme}=y" ${HOME_PATH}/.config` -eq '0' ]]; then
    TIME r "没有${Default_theme}此主题存在，默认主题设置失败"
  else
    echo "uci set luci.main.mediaurlbase='/luci-static/${Default_theme}'" >> "${DEFAULT_PATH}"
    echo "uci commit luci" >> "${DEFAULT_PATH}"
    echo "默认主题[${Default_theme}]设置完成"
  fi
else
  echo "不进行,默认主题设置"
fi

if [[ ! "${Mandatory_theme}" == "0" ]] && [[ -n "${Mandatory_theme}" ]]; then
  if [[ `grep -c "${Mandatory_theme}=y" ${HOME_PATH}/.config` -eq '1' ]]; then
    [[ -f "$HOME_PATH/feeds/luci/collections/luci/Makefile" ]] && sed -i -E "s/(\+luci-theme-)[^ \\]*/\1${Mandatory_theme}/g" "$HOME_PATH/feeds/luci/collections/luci/Makefile"
    [[ -f "$HOME_PATH/feeds/luci/collections/luci-light/Makefile" ]] && sed -i -E "s/(\+luci-theme-)[^ \\]*/\1${Mandatory_theme}/g" "$HOME_PATH/feeds/luci/collections/luci-light/Makefile"
    echo "替换系统默认主题完成,您现在的系统默认主题为：luci-theme-${Mandatory_theme}"
  else
    [[ -f "$HOME_PATH/feeds/luci/collections/luci/Makefile" ]] && sed -i -E "s/(\+luci-theme-)[^ \\]*/\1bootstrap/g" "$HOME_PATH/feeds/luci/collections/luci/Makefile"
    [[ -f "$HOME_PATH/feeds/luci/collections/luci-light/Makefile" ]] && sed -i -E "s/(\+luci-theme-)[^ \\]*/\1bootstrap/g" "$HOME_PATH/feeds/luci/collections/luci-light/Makefile"
    echo "CONFIG_PACKAGE_luci-theme-bootstrap=y" >>.config
    TIME r "没有${Mandatory_theme}此主题存在，替换失败，继续使用原默认主题"
  fi
else
  echo "不进行,系统默认主题替换"
fi

if [[ "${Customized_Information}" == "0" ]] || [[ -z "${Customized_Information}" ]]; then
  echo "不进行,个性签名设置"
elif [[ -n "${Customized_Information}" ]]; then
  echo "[ -f '/usr/lib/os-release' ] && sed -i \"s?RELEASE=.*?RELEASE=\\\"${Customized_Information} @ OpenWrt\\\"?g\" '/usr/lib/os-release'" >> "${DEFAULT_PATH}"
  echo "sed -i '/DISTRIB_DESCRIPTION/d' /etc/openwrt_release" >> "${DEFAULT_PATH}"
  echo "echo \"DISTRIB_DESCRIPTION='${Customized_Information} @ OpenWrt '\" >> /etc/openwrt_release" >> "${DEFAULT_PATH}"
  echo "个性签名[${Customized_Information}]增加完成"
fi

if [[ -n "${Kernel_partition_size}" ]] && [[ "${Kernel_partition_size}" != "0" ]]; then
  Kernel_partition_size=$(echo "${Kernel_partition_size}" | tr -d '[:space:]' | grep -o -E '[0-9]+')
  echo "CONFIG_TARGET_KERNEL_PARTSIZE=${Kernel_partition_size}" >> ${HOME_PATH}/.config
  echo "内核分区设置完成，大小为：${Kernel_partition_size}MB"
else
  echo "不进行,内核分区大小设置"
fi

if [[ -n "${Rootfs_partition_size}" ]] && [[ "${Rootfs_partition_size}" != "0" ]]; then
  Rootfs_partition_size=$(echo "${Rootfs_partition_size}" | tr -d '[:space:]' | grep -o -E '[0-9]+')
  echo "CONFIG_TARGET_ROOTFS_PARTSIZE=${Rootfs_partition_size}" >> ${HOME_PATH}/.config
  echo "系统分区设置完成，大小为：${Rootfs_partition_size}MB"
else
  echo "不进行,系统分区大小设置"
fi

if [[ "${Op_name}" == "0" ]] || [[ -z "${Op_name}" ]]; then
  echo "不进行,修改主机名称"
elif [[ -n "${Op_name}" ]] && [[ -n "${opname}" ]]; then
  sed -i "s/${opname}/${Op_name}/g" "${GENE_PATH}"
  echo "主机名[${Op_name}]修改完成"
fi

if [[ "${Gateway_Settings}" == "0" ]] || [[ -z "${Gateway_Settings}" ]]; then
  echo "不进行,网关设置"
elif [[ -n "${Gateway_Settings}" ]]; then
  Router_gat="$(echo ${Gateway_Settings} |grep -Eo "[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+")"
  if [[ -n "${Router_gat}" ]]; then
    sed -i "$lan\set network.lan.gateway='${Gateway_Settings}'" "${GENE_PATH}"
    echo "网关[${Gateway_Settings}]修改完成"
  else
    TIME r "因子网关IP获取有错误，网关IP设置失败，请检查IP是否填写正确，如果填写正确，那就是获取不了源码内的IP了"
  fi
fi

if [[ "${DNS_Settings}" == "0" ]] || [[ -z "${DNS_Settings}" ]]; then
  echo "不进行,DNS设置"
elif [[ -n "${DNS_Settings}" ]]; then
  ipa_dns="$(echo ${DNS_Settings} |grep -Eo "[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+")"
  if [[ -n "${ipa_dns}" ]]; then
     sed -i "$lan\set network.lan.dns='${DNS_Settings}'" "${GENE_PATH}"
     echo "DNS[${DNS_Settings}]设置完成"
  else
    TIME r "因DNS获取有错误，DNS设置失败，请检查DNS是否填写正确"
  fi
fi

if [[ "${Broadcast_Ipv4}" == "0" ]] || [[ -z "${Broadcast_Ipv4}" ]]; then
  echo "不进行,广播IP设置"
elif [[ -n "${Broadcast_Ipv4}" ]]; then
  IPv4_Bro="$(echo ${Broadcast_Ipv4} |grep -Eo "[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+")"
  if [[ -n "${IPv4_Bro}" ]]; then
    sed -i "$lan\set network.lan.broadcast='${Broadcast_Ipv4}'" "${GENE_PATH}"
    echo "广播IP[${Broadcast_Ipv4}]设置完成"
  else
    TIME r "因IPv4 广播IP获取有错误，IPv4广播IP设置失败，请检查IPv4广播IP是否填写正确"
  fi
fi

if [[ "${Disable_DHCP}" == "1" ]]; then
   sed -i "$lan\set dhcp.lan.ignore='1'" "${GENE_PATH}"
   echo "关闭DHCP设置完成"
else
   echo "不进行,关闭DHCP设置"
fi

if [[ "${Disable_Bridge}" == "1" ]]; then
   sed -i "$lan\delete network.lan.type" "${GENE_PATH}"
   echo "去掉桥接设置完成"
else
   echo "不进行,去掉桥接设"
fi

if [[ "${Ttyd_account_free_login}" == "1" ]]; then
   sed -i "$lan\set ttyd.@ttyd[0].command='/bin/login -f root'" "${GENE_PATH}"
   echo "TTYD免账户登录完成"
else
   echo "不进行,TTYD免账户登录"
fi

if [[ "${Password_free_login}" == "1" ]]; then
   sed -i '/CYXluq4wUazHjmCDBCqXF/d' "${ZZZ_PATH}"
   echo "固件免密登录设置完成"
else
   echo "不进行,固件免密登录设置"
fi

if [[ "${Disable_53_redirection}" == "1" ]]; then
   sed -i '/to-ports 53/d' "${ZZZ_PATH}"
   echo "删除DNS重定向53端口完成"
else
   echo "不进行,删除DNS重定向53端"
fi

if [[ "${Cancel_running}" == "1" ]]; then
   echo "sed -i '/coremark/d' /etc/crontabs/root" >> "${DEFAULT_PATH}"
   echo "删除每天跑分任务完成"
else
   echo "不进行,删除每天跑分任务"
fi

if [[ "${OpenClash_branch}" =~ (1|2) ]]; then
  CLASH_BRANCH=$(grep -Po '^src-git(?:-full)?\s+OpenClash\s+[^;\s]+;\K[^\s]+' "${HOME_PATH}/feeds.conf.default" || echo "")
  echo -e "\nCONFIG_PACKAGE_luci-app-openclash=y" >> ${HOME_PATH}/.config
  echo "增加luci-app-openclash(${CLASH_BRANCH})完成"
else
  echo -e "\n# CONFIG_PACKAGE_luci-app-openclash is not set" >> ${HOME_PATH}/.config
  echo "去除luci-app-openclash完成"
fi


if [[ "${Disable_autosamba}" == "1" ]]; then
sed -i '/samba/d;/SAMBA/d' "${HOME_PATH}/.config"
echo '
# CONFIG_PACKAGE_autosamba is not set
# CONFIG_PACKAGE_luci-app-samba is not set
# CONFIG_PACKAGE_luci-app-samba4 is not set
# CONFIG_PACKAGE_samba36-server is not set
# CONFIG_PACKAGE_samba4-libs is not set
# CONFIG_PACKAGE_samba4-server is not set
' >> ${HOME_PATH}/.config
   echo "去掉samba完成"
else
   echo "不进行,去掉samba"
fi

if [[ "${Automatic_Mount_Settings}" == "1" ]]; then
echo '
CONFIG_PACKAGE_block-mount=y
CONFIG_PACKAGE_fdisk=y
CONFIG_PACKAGE_usbutils=y
CONFIG_PACKAGE_badblocks=y
CONFIG_PACKAGE_ntfs-3g=y
CONFIG_PACKAGE_kmod-scsi-core=y
CONFIG_PACKAGE_kmod-usb-core=y
CONFIG_PACKAGE_kmod-usb-ohci=y
CONFIG_PACKAGE_kmod-usb-uhci=y
CONFIG_PACKAGE_kmod-usb-storage=y
CONFIG_PACKAGE_kmod-usb-storage-extras=y
CONFIG_PACKAGE_kmod-usb2=y
CONFIG_PACKAGE_kmod-usb3=y
CONFIG_PACKAGE_kmod-fs-ext4=y
CONFIG_PACKAGE_kmod-fs-vfat=y
CONFIG_PACKAGE_kmod-fuse=y
# CONFIG_PACKAGE_kmod-fs-ntfs is not set
' >> ${HOME_PATH}/.config
[[ ! -d "${HOME_PATH}/files/etc/hotplug.d/block" ]] && mkdir -p "${HOME_PATH}/files/etc/hotplug.d/block"
cp -Rf "$LINSHI_COMMON/Share/block/10-mount" "${HOME_PATH}/files/etc/hotplug.d/block/10-mount"
fi

if [[ "${Enable_IPV6_function}" == "1" ]]; then
  echo "编译IPV6固件"
  echo "
    uci set network.lan.ip6assign='64'
    uci commit network
    uci set dhcp.lan.ra='server'
    uci set dhcp.lan.dhcpv6='server'
    uci set dhcp.lan.ra_management='1'
    uci set dhcp.lan.ra_default='1'
    uci set dhcp.@dnsmasq[0].localservice=0
    uci set dhcp.@dnsmasq[0].nonwildcard=0
    uci set dhcp.@dnsmasq[0].filter_aaaa='0'
    uci commit dhcp
  " >> "${DEFAULT_PATH}"
elif [[ "${Create_Ipv6_Lan}" == "1" ]]; then
  echo "爱快+OP双系统时,爱快接管IPV6,在OP创建IPV6的lan口接收IPV6信息"
  echo "
    uci delete network.lan.ip6assign
    uci set network.lan.delegate='0'
    uci commit network
    uci delete dhcp.lan.ra
    uci delete dhcp.lan.ra_management
    uci delete dhcp.lan.ra_default
    uci delete dhcp.lan.dhcpv6
    uci delete dhcp.lan.ndp
    uci set dhcp.@dnsmasq[0].filter_aaaa='0'
    uci commit dhcp
    uci set network.ipv6=interface
    uci set network.ipv6.proto='dhcpv6'
    ${devicee}
    ${ifnamee}
    uci set network.ipv6.reqaddress='try'
    uci set network.ipv6.reqprefix='auto'
    uci commit network
    ${set_add}
    uci commit firewall
  " >> "${DEFAULT_PATH}"
elif [[ "${Enable_IPV4_function}" == "1" ]]; then
  echo "编译IPV4固件"
  echo "
    uci delete network.globals.ula_prefix
    uci delete network.lan.ip6assign
    uci delete network.wan6
    uci set network.lan.delegate='0' 
    uci commit network
    uci delete dhcp.lan.ra
    uci delete dhcp.lan.ra_management
    uci delete dhcp.lan.ra_default
    uci delete dhcp.lan.dhcpv6
    uci delete dhcp.lan.ndp
    uci set dhcp.@dnsmasq[0].filter_aaaa='1'
    uci commit dhcp
  " >> "${DEFAULT_PATH}"
fi

if [[ "${Enable_IPV6_function}" == "1" ]]; then
echo '
CONFIG_PACKAGE_ipv6helper=y
CONFIG_PACKAGE_ip6tables=y
CONFIG_PACKAGE_dnsmasq_full_dhcpv6=y
CONFIG_PACKAGE_odhcp6c=y
CONFIG_PACKAGE_odhcpd-ipv6only=y
CONFIG_IPV6=y
CONFIG_PACKAGE_6rd=y
CONFIG_PACKAGE_6to4=y
' >> ${HOME_PATH}/.config
fi

if [[ "${Create_Ipv6_Lan}" == "1" ]]; then
echo '
CONFIG_PACKAGE_ipv6helper=y
CONFIG_PACKAGE_ip6tables=y
CONFIG_PACKAGE_dnsmasq_full_dhcpv6=y
CONFIG_PACKAGE_odhcp6c=y
CONFIG_PACKAGE_odhcpd-ipv6only=y
CONFIG_IPV6=y
CONFIG_PACKAGE_6rd=y
CONFIG_PACKAGE_6to4=y
' >> ${HOME_PATH}/.config
fi

if [[ "${Enable_IPV4_function}" == "1" ]] && \
[[ "${REPO_BRANCH}" =~ ^(main|master|2410|(openwrt-)?(19\.07|23\.05|24\.10))$ ]]; then
echo '
# CONFIG_PACKAGE_ipv6helper is not set
# CONFIG_PACKAGE_ip6tables is not set
# CONFIG_PACKAGE_dnsmasq_full_dhcpv6 is not set
# CONFIG_PACKAGE_odhcp6c is not set
# CONFIG_PACKAGE_odhcpd-ipv6only is not set
# CONFIG_IPV6 is not set
# CONFIG_PACKAGE_6rd is not set
# CONFIG_PACKAGE_6to4 is not set
' >> ${HOME_PATH}/.config
else
echo '
CONFIG_IPV6=y
CONFIG_PACKAGE_odhcp6c=y
CONFIG_PACKAGE_odhcpd-ipv6only=y
' >> ${HOME_PATH}/.config
fi


if [[ "${Delete_unnecessary_items}" == "1" ]]; then
  echo "删除其他机型的固件,只保留当前主机型固件完成"
  sed -i "s|^TARGET_|# TARGET_|g; s|# TARGET_DEVICES += ${TARGET_PROFILE}|TARGET_DEVICES += ${TARGET_PROFILE}|" ${HOME_PATH}/target/linux/${TARGET_BOARD}/image/Makefile
fi

variable patchverl="$(grep "KERNEL_PATCHVER" "${HOME_PATH}/target/linux/${TARGET_BOARD}/Makefile" |grep -Eo "[0-9]+\.[0-9]+")"
if [[ "${TARGET_BOARD}" == "armvirt" ]]; then
  variable KERNEL_patc="config-${Replace_Kernel}"
else
  variable KERNEL_patc="patches-${Replace_Kernel}"
fi
if [[ "${Replace_Kernel}" == "0" ]]; then
  echo "不进行,内核更换"
elif [[ -n "${Replace_Kernel}" ]] && [[ -n "${patchverl}" ]]; then
  if [[ `ls -1 "${HOME_PATH}/target/linux/${TARGET_BOARD}" |grep -c "${KERNEL_patc}"` -eq '1' ]]; then
    sed -i "s/${patchverl}/${Replace_Kernel}/g" ${HOME_PATH}/target/linux/${TARGET_BOARD}/Makefile
    echo "内核[${Replace_Kernel}]更换完成"
  else
    TIME r "${TARGET_PROFILE}机型源码没发现[ ${Replace_Kernel} ]内核存在，替换内核操作失败，保持默认内核[${patchverl}]继续编译"
  fi
fi

cat >> "${HOME_PATH}/.config" <<-EOF
CONFIG_PACKAGE_luci=y
CONFIG_PACKAGE_luci-base=y
CONFIG_PACKAGE_luci-compat=y
CONFIG_PACKAGE_luci-i18n-base-zh-cn=y
CONFIG_PACKAGE_luci-lib-ipkg=y
CONFIG_PACKAGE_default-settings=y
CONFIG_PACKAGE_default-settings-chn=y
EOF

# 晶晨CPU机型自定义机型,内核,分区
[[ -n "${amlogic_model}" ]] && echo "amlogic_model=${amlogic_model}" >> ${GITHUB_ENV}
[[ -n "${amlogic_kernel}" ]] && echo "amlogic_kernel=${amlogic_kernel}" >> ${GITHUB_ENV}
[[ -n "${auto_kernel}" ]] && echo "auto_kernel=${auto_kernel}" >> ${GITHUB_ENV}
[[ -n "${rootfs_size}" ]] && echo "openwrt_size=${rootfs_size}" >> ${GITHUB_ENV}
[[ -n "${amlogic_model}" ]] && echo "kernel_repo=ophub/kernel" >> ${GITHUB_ENV}
[[ -n "${kernel_usage}" ]] && echo "kernel_usage=${kernel_usage}" >> ${GITHUB_ENV}
[[ -n "${amlogic_model}" ]] && echo "builder_name=ophub" >> ${GITHUB_ENV}

# adguardhome增加核心
ARCH_TYPE=$(grep "CONFIG_ARCH=\"" "${HOME_PATH}/.config" | cut -d '"' -f 2)
# 层级式判断架构类型
case "$ARCH_TYPE" in
    "x86_64")
        Arch="linux_amd64"
        echo "CPU架构：amd64" ;;
    "i386")
        Arch="linux_386"
        echo "CPU架构：X86 32" ;;
    "aarch64")
        Arch="linux_arm64"
        echo "CPU架构：arm64" ;;
    "arm")
        if grep -q "CONFIG_ARM_V8=y" "${HOME_PATH}/.config"; then
            Arch="linux_arm64"
            echo "CPU架构：arm64"
        elif grep -q "CONFIG_arm_v7=y" "${HOME_PATH}/.config"; then
            Arch="linux_armv7"
            echo "CPU架构：armv7"
        elif grep -q "CONFIG_VFP=y" "${HOME_PATH}/.config"; then
            Arch="linux_armv6"
            echo "CPU架构：armv6"
        else
            Arch="linux_armv5"
            echo "CPU架构：armv5"
        fi ;;
    "mips" | "mipsel" | "mips64" | "mips64el")
        if grep -q "CONFIG_64BIT=y" "${HOME_PATH}/.config"; then
            if [[ "${ARCH_TYPE}" == "mips64el" ]]; then
                abi="64le"
            else
                abi="64"
            fi
        fi
        if grep -q "CONFIG_SOFT_FLOAT=y" "${HOME_PATH}/.config"; then
            suffix="_softfloat"
        else
            suffix=""
        fi
        Arch="linux_${ARCH_TYPE}${abi}${suffix}"
        echo "CPU架构：${ARCH_TYPE}${abi}${suffix}" ;;
    "riscv" | "riscv64")
        if grep -q "CONFIG_64BIT=y" "${HOME_PATH}/.config"; then
            Arch="linux_riscv64"
        else
            Arch="linux_riscv32"
        fi ;;
    *)
        echo "未知架构类型"
        Arch="" ;;
esac

if [[ -n "${Arch}" ]] && [[ "${AdGuardHome_Core}" == "1" ]]; then
  # 仅清理 AdGuardHome 相关文件，避免误删 files/usr/bin 下的其他自定义内容
  rm -rf "${HOME_PATH}/AdGuardHome" "${HOME_PATH}/files/usr/bin/AdGuardHome" "${HOME_PATH}/files/usr/bin/AdGuardHome_"* 2>/dev/null || true
  mkdir -p "${HOME_PATH}/files/usr/bin"

  # 获取 AdGuardHome 最新版本号（复用作者 GitHub API；失败则回退仓库内缓存）
  api_file="$LINSHI_COMMON/language/AdGuardHome.api"
  tmp_api="${api_file}.tmp"
  mkdir -p "$(dirname "${api_file}")"

  if command -v curl >/dev/null 2>&1; then
    curl -fsSL --retry 3 --connect-timeout 15       "https://api.github.com/repos/AdguardTeam/AdGuardHome/releases/latest"       -o "${tmp_api}" || true
  else
    wget -q -O "${tmp_api}"       "https://api.github.com/repos/AdguardTeam/AdGuardHome/releases/latest" || true
  fi

  if [[ -s "${tmp_api}" ]] && grep -q '"tag_name"' "${tmp_api}"; then
    mv -f "${tmp_api}" "${api_file}"
  else
    rm -f "${tmp_api}" 2>/dev/null || true
  fi

  if [[ -f "${api_file}" ]]; then
    latest_ver="$(grep -E 'tag_name' "${api_file}" | grep -E 'v[0-9.]+' -o 2>/dev/null)"
    if [[ -z "${latest_ver}" ]]; then
      TIME r "解析 AdGuardHome 最新版本号失败"
    else
      wget -q "https://github.com/AdguardTeam/AdGuardHome/releases/download/${latest_ver}/AdGuardHome_${Arch}.tar.gz"

    if [[ -f "AdGuardHome_${Arch}.tar.gz" ]]; then
      tar -zxf "AdGuardHome_${Arch}.tar.gz" -C "${HOME_PATH}"
    fi

    # 关键修复：把核心以“文件”形式预置到 /usr/bin/AdGuardHome，避免 LuCI 识别为目录导致“核心缺失”
    if [[ -f "${HOME_PATH}/AdGuardHome/AdGuardHome" ]]; then
      install -m 0755 "${HOME_PATH}/AdGuardHome/AdGuardHome" "${HOME_PATH}/files/usr/bin/AdGuardHome"
      echo -e "\nCONFIG_PACKAGE_luci-app-adguardhome=y" >> "${HOME_PATH}/.config"
      echo "增加luci-app-adguardhome并预置AdGuardHome核心完成（/usr/bin/AdGuardHome）"
    else
      echo -e "\nCONFIG_PACKAGE_luci-app-adguardhome=y" >> "${HOME_PATH}/.config"
      echo "下载AdGuardHome核心失败"
    fi

    rm -rf "${HOME_PATH}/AdGuardHome" "AdGuardHome_${Arch}.tar.gz" 2>/dev/null || true
    fi
  fi
else
  # 未启用则清理可能残留的核心文件
  if [[ -f "${HOME_PATH}/files/usr/bin/AdGuardHome" ]] && [[ ! "${AdGuardHome_Core}" == "1" ]]; then
    rm -rf "${HOME_PATH}/files/usr/bin/AdGuardHome"
  fi
fi

# 预置 GeoIP/GeoSite 数据（可选）
if [[ "${Preload_GeoData}" == "1" ]]; then
  echo "开始预置 GeoIP/GeoSite 数据到固件（/usr/share/v2ray）..."
  mkdir -p "${HOME_PATH}/files/usr/share/v2ray" "${HOME_PATH}/files/usr/share/xray"
  if command -v curl >/dev/null 2>&1; then
    curl -L --retry 3 --connect-timeout 15 -o "${HOME_PATH}/files/usr/share/v2ray/geoip.dat"   "https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geoip.dat"
    curl -L --retry 3 --connect-timeout 15 -o "${HOME_PATH}/files/usr/share/v2ray/geosite.dat" "https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geosite.dat"
  else
    wget -q -O "${HOME_PATH}/files/usr/share/v2ray/geoip.dat"   "https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geoip.dat"
    wget -q -O "${HOME_PATH}/files/usr/share/v2ray/geosite.dat" "https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geosite.dat"
  fi
  # 兼容 Xray 默认路径
  ln -sf ../v2ray/geoip.dat   "${HOME_PATH}/files/usr/share/xray/geoip.dat"
  ln -sf ../v2ray/geosite.dat "${HOME_PATH}/files/usr/share/xray/geosite.dat"
fi

# fw4(nftables) 开关（可选）
if [[ "${Enable_FW4}" == "1" ]]; then
  echo "启用 fw4(nftables) 防火墙..."
  # 如果源码不存在 firewall4，则从 LEDE 拉取（优先与当前源码一致）
  if [[ ! -d "${HOME_PATH}/package/network/config/firewall4" ]]; then
    mkdir -p "${HOME_PATH}/package/network/config"
    gitsvn https://github.com/coolsnowwolf/lede/tree/master/package/network/config/firewall4 "${HOME_PATH}/package/network/config/firewall4"
  fi

  # 选择 fw4 相关组件（强制 fw3/fw4 互斥）
  sed -i \
    -e '/^CONFIG_PACKAGE_firewall4=/d' \
    -e '/^# CONFIG_PACKAGE_firewall4 is not set/d' \
    -e '/^CONFIG_PACKAGE_firewall=/d' \
    -e '/^# CONFIG_PACKAGE_firewall is not set/d' \
    -e '/^CONFIG_PACKAGE_nftables=/d' \
    -e '/^CONFIG_PACKAGE_rpcd-mod-nft=/d' \
    -e '/^CONFIG_PACKAGE_luci-lib-nftables=/d' \
    -e '/^CONFIG_PACKAGE_kmod-nft-tproxy=/d' \
    -e '/^CONFIG_PACKAGE_kmod-nft-socket=/d' \
    "${HOME_PATH}/.config"

  cat >> "${HOME_PATH}/.config" <<'EOF'
CONFIG_PACKAGE_firewall4=y
# CONFIG_PACKAGE_firewall is not set
CONFIG_PACKAGE_nftables=y
CONFIG_PACKAGE_rpcd-mod-nft=y
CONFIG_PACKAGE_luci-lib-nftables=y
CONFIG_PACKAGE_kmod-nft-tproxy=y
CONFIG_PACKAGE_kmod-nft-socket=y
EOF
else
  echo "使用 fw3(iptables) 防火墙..."

  sed -i \
    -e '/^CONFIG_PACKAGE_firewall4=/d' \
    -e '/^# CONFIG_PACKAGE_firewall4 is not set/d' \
    -e '/^CONFIG_PACKAGE_nftables=/d' \
    -e '/^CONFIG_PACKAGE_rpcd-mod-nft=/d' \
    -e '/^CONFIG_PACKAGE_luci-lib-nftables=/d' \
    -e '/^CONFIG_PACKAGE_kmod-nft-tproxy=/d' \
    -e '/^CONFIG_PACKAGE_kmod-nft-socket=/d' \
    -e '/^CONFIG_PACKAGE_firewall=/d' \
    -e '/^# CONFIG_PACKAGE_firewall is not set/d' \
    "${HOME_PATH}/.config"

  cat >> "${HOME_PATH}/.config" <<'EOF'
CONFIG_PACKAGE_firewall=y
# CONFIG_PACKAGE_firewall4 is not set
EOF
fi

# 源码内核版本号
KERNEL_PATCH="$(awk -F'[:=]' '/KERNEL_PATCHVER/{print $NF; exit}' "${HOME_PATH}/target/linux/${TARGET_BOARD}/Makefile")"
KERNEL_VERSINO="kernel-${KERNEL_PATCH}"
if [[ -f "${HOME_PATH}/include/${KERNEL_VERSINO}" ]]; then
  variable LINUX_KERNEL="$(grep -oP "LINUX_KERNEL_HASH-\K${KERNEL_PATCH}\.[0-9]+" "${HOME_PATH}/include/${KERNEL_VERSINO}")"
  [[ -z ${LINUX_KERNEL} ]] && variable LINUX_KERNEL="$KERNEL_PATCH"
else
  variable LINUX_KERNEL="$(grep -oP "LINUX_KERNEL_HASH-\K${KERNEL_PATCH}\.[0-9]+" "${HOME_PATH}/include/kernel-version.mk")"
  [[ -z ${LINUX_KERNEL} ]] && variable LINUX_KERNEL="$KERNEL_PATCH"
fi
}


