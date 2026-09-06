#!/usr/bin/env bash
# shellcheck shell=bash
# package conflict/prevention helper; sourced by common.sh.

function Diy_prevent() {
TIME y "正在执行：判断插件有否冲突减少编译错误"
cd ${HOME_PATH}
make defconfig > /dev/null 2>&1
# --- 强制 fw3/fw4 互斥（防止 make defconfig 回填） ---
if [[ "${Enable_FW4}" == "1" ]]; then
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


if [[ `grep -c "CONFIG_PACKAGE_luci-app-ipsec-server=y" ${HOME_PATH}/.config` -eq '1' ]]; then
  if [[ `grep -c "CONFIG_PACKAGE_luci-app-ipsec-vpnd=y" ${HOME_PATH}/.config` -eq '1' ]]; then
    sed -i 's/CONFIG_PACKAGE_luci-app-ipsec-vpnd=y/# CONFIG_PACKAGE_luci-app-ipsec-vpnd is not set/g' ${HOME_PATH}/.config
    TIME r "您同时选择luci-app-ipsec-vpnd和luci-app-ipsec-server，插件有冲突，相同功能插件只能二选一，已删除luci-app-ipsec-vpnd"
  fi
fi

if [[ `grep -c "CONFIG_PACKAGE_luci-app-docker=y" ${HOME_PATH}/.config` -eq '1' ]]; then
  if [[ `grep -c "CONFIG_PACKAGE_luci-app-dockerman=y" ${HOME_PATH}/.config` -eq '1' ]]; then
    sed -i 's/CONFIG_PACKAGE_luci-app-docker=y/# CONFIG_PACKAGE_luci-app-docker is not set/g' ${HOME_PATH}/.config
    sed -i 's/CONFIG_PACKAGE_luci-i18n-docker-zh-cn=y/# CONFIG_PACKAGE_luci-i18n-docker-zh-cn is not set/g' ${HOME_PATH}/.config
    TIME r "您同时选择luci-app-docker和luci-app-dockerman，插件有冲突，相同功能插件只能二选一，已删除luci-app-docker"
  fi
fi

if [[ `grep -c "CONFIG_PACKAGE_luci-app-qbittorrent=y" ${HOME_PATH}/.config` -eq '1' ]]; then
  if [[ `grep -c "CONFIG_PACKAGE_luci-app-qbittorrent-simple=y" ${HOME_PATH}/.config` -eq '1' ]]; then
    sed -i 's/CONFIG_PACKAGE_luci-app-qbittorrent-simple=y/# CONFIG_PACKAGE_luci-app-qbittorrent-simple is not set/g' ${HOME_PATH}/.config
    sed -i 's/CONFIG_PACKAGE_luci-i18n-qbittorrent-simple-zh-cn=y/# CONFIG_PACKAGE_luci-i18n-qbittorrent-simple-zh-cn is not set/g' ${HOME_PATH}/.config
    sed -i 's/CONFIG_PACKAGE_qbittorrent=y/# CONFIG_PACKAGE_qbittorrent is not set/g' ${HOME_PATH}/.config
    TIME r "您同时选择luci-app-qbittorrent和luci-app-qbittorrent-simple，插件有冲突，相同功能插件只能二选一，已删除luci-app-qbittorrent-simple"
  fi
fi

if [[ `grep -c "CONFIG_PACKAGE_luci-app-advanced=y" ${HOME_PATH}/.config` -eq '1' ]]; then
  if [[ `grep -c "CONFIG_PACKAGE_luci-app-fileassistant=y" ${HOME_PATH}/.config` -eq '1' ]]; then
    sed -i 's/CONFIG_PACKAGE_luci-app-fileassistant=y/# CONFIG_PACKAGE_luci-app-fileassistant is not set/g' ${HOME_PATH}/.config
    TIME r "您同时选择luci-app-advanced和luci-app-fileassistant，luci-app-advanced已附带luci-app-fileassistant，所以删除了luci-app-fileassistant"
   fi
fi

if [[ `grep -c "CONFIG_PACKAGE_luci-app-adblock-plus=y" ${HOME_PATH}/.config` -eq '1' ]]; then
  if [[ `grep -c "CONFIG_PACKAGE_luci-app-adblock=y" ${HOME_PATH}/.config` -eq '1' ]]; then
    sed -i 's/CONFIG_PACKAGE_luci-app-adblock=y/# CONFIG_PACKAGE_luci-app-adblock is not set/g' ${HOME_PATH}/.config
    sed -i 's/CONFIG_PACKAGE_adblock=y/# CONFIG_PACKAGE_adblock is not set/g' ${HOME_PATH}/.config
    sed -i '/luci-i18n-adblock/d' ${HOME_PATH}/.config
    TIME r "您同时选择luci-app-adblock-plus和luci-app-adblock，插件有依赖冲突，只能二选一，已删除luci-app-adblock"
  fi
fi

if [[ `grep -c "CONFIG_PACKAGE_luci-app-kodexplorer=y" ${HOME_PATH}/.config` -eq '1' ]]; then
  if [[ `grep -c "CONFIG_PACKAGE_luci-app-vnstat=y" ${HOME_PATH}/.config` -eq '1' ]]; then
    sed -i 's/CONFIG_PACKAGE_luci-app-vnstat=y/# CONFIG_PACKAGE_luci-app-vnstat is not set/g' ${HOME_PATH}/.config
    sed -i 's/CONFIG_PACKAGE_vnstat=y/# CONFIG_PACKAGE_vnstat is not set/g' ${HOME_PATH}/.config
    sed -i 's/CONFIG_PACKAGE_vnstati=y/# CONFIG_PACKAGE_vnstati is not set/g' ${HOME_PATH}/.config
    sed -i 's/CONFIG_PACKAGE_libgd=y/# CONFIG_PACKAGE_libgd is not set/g' ${HOME_PATH}/.config
    sed -i '/luci-i18n-vnstat/d' ${HOME_PATH}/.config
    TIME r "您同时选择luci-app-kodexplorer和luci-app-vnstat，插件有依赖冲突，只能二选一，已删除luci-app-vnstat"
  fi
fi

if [[ `grep -c "CONFIG_PACKAGE_luci-app-ssr-plus=y" ${HOME_PATH}/.config` -ge '1' ]]; then
  if [[ `grep -c "CONFIG_PACKAGE_luci-app-cshark=y" ${HOME_PATH}/.config` -eq '1' ]]; then
    sed -i 's/CONFIG_PACKAGE_luci-app-cshark=y/# CONFIG_PACKAGE_luci-app-cshark is not set/g' ${HOME_PATH}/.config
    sed -i 's/CONFIG_PACKAGE_cshark=y/# CONFIG_PACKAGE_cshark is not set/g' ${HOME_PATH}/.config
    sed -i 's/CONFIG_PACKAGE_libustream-mbedtls=y/# CONFIG_PACKAGE_libustream-mbedtls is not set/g' ${HOME_PATH}/.config
    TIME r "您同时选择luci-app-ssr-plus和luci-app-cshark，插件有依赖冲突，只能二选一，已删除luci-app-cshark"
  fi
fi

if grep -q "ssr-plus=y" "${HOME_PATH}/.config" && [[ "${SOURCE}" == "Lienol" ]] && [[ "${REPO_BRANCH}" == "19.07" ]]; then
  sed -i '/plus_INCLUDE_PACKAGE_libustream-wolfssl/d' ${HOME_PATH}/.config
  sed -i '/plus_INCLUDE_libustream-openssl/d' ${HOME_PATH}/.config
  sed -i '/CONFIG_PACKAGE_libustream-openssl=y/d' ${HOME_PATH}/.config
  echo "CONFIG_PACKAGE_luci-app-ssr-plus_INCLUDE_PACKAGE_libustream-wolfssl=y" >> ${HOME_PATH}/.config
  echo "# CONFIG_PACKAGE_luci-app-ssr-plus_INCLUDE_libustream-openssl is not set" >> ${HOME_PATH}/.config
fi

if [[ `grep -c "CONFIG_PACKAGE_luci-app-turboacc_INCLUDE_SHORTCUT_FE_CM=y" ${HOME_PATH}/.config` -ge '1' ]]; then
  if [[ `grep -c "CONFIG_PACKAGE_luci-app-turboacc_INCLUDE_SHORTCUT_FE=y" ${HOME_PATH}/.config` -eq '1' ]]; then
    sed -i 's/CONFIG_PACKAGE_luci-app-turboacc_INCLUDE_SHORTCUT_FE=y/# CONFIG_PACKAGE_luci-app-turboacc_INCLUDE_SHORTCUT_FE is not set/g' ${HOME_PATH}/.config
    sed -i 's/CONFIG_PACKAGE_kmod-fast-classifier=y/# CONFIG_PACKAGE_kmod-fast-classifier is not set/g' ${HOME_PATH}/.config
    TIME r "luci-app-turboacc同时选择Include Shortcut-FE CM和Include Shortcut-FE，有冲突，只能二选一，已删除Include Shortcut-FE"
  fi
fi

if [[ `grep -c "CONFIG_PACKAGE_wpad-openssl=y" ${HOME_PATH}/.config` -eq '1' ]]; then
  if [[ `grep -c "CONFIG_PACKAGE_wpad=y" ${HOME_PATH}/.config` -eq '1' ]]; then
    sed -i 's/CONFIG_PACKAGE_wpad=y/# CONFIG_PACKAGE_wpad is not set/g' ${HOME_PATH}/.config
  fi
fi

if [[ `grep -c "CONFIG_PACKAGE_ntfs3-mount=y" ${HOME_PATH}/.config` -eq '1' ]]; then
  if [[ `grep -c "CONFIG_PACKAGE_ntfs-3g=y" ${HOME_PATH}/.config` -eq '1' ]] || [[ `grep -c "CONFIG_PACKAGE_antfs-mount=y" ${HOME_PATH}/.config` -eq '1' ]]; then
    sed -i 's/CONFIG_PACKAGE_antfs-mount=y/# CONFIG_PACKAGE_antfs-mount is not set/g' ${HOME_PATH}/.config
    sed -i 's/CONFIG_PACKAGE_ntfs-3g=y/# CONFIG_PACKAGE_ntfs-3g is not set/g' ${HOME_PATH}/.config
    sed -i 's/CONFIG_PACKAGE_NTFS-3G_HAS_PROBE=y/# CONFIG_PACKAGE_NTFS-3G_HAS_PROBE is not set/g' ${HOME_PATH}/.config
  fi
fi

if [[ `grep -c "CONFIG_PACKAGE_antfs-mount=y" ${HOME_PATH}/.config` -eq '1' ]]; then
  if [[ `grep -c "CONFIG_PACKAGE_ntfs-3g=y" ${HOME_PATH}/.config` -eq '1' ]] || [[ `grep -c "CONFIG_PACKAGE_ntfs3-mount=y" ${HOME_PATH}/.config` -eq '1' ]]; then
    sed -i 's/CONFIG_PACKAGE_ntfs3-mount=y/# CONFIG_PACKAGE_ntfs3-mount is not set/g' ${HOME_PATH}/.config
    sed -i 's/CONFIG_PACKAGE_ntfs-3g=y/# CONFIG_PACKAGE_ntfs-3g is not set/g' ${HOME_PATH}/.config
    sed -i 's/CONFIG_PACKAGE_NTFS-3G_HAS_PROBE=y/# CONFIG_PACKAGE_NTFS-3G_HAS_PROBE is not set/g' ${HOME_PATH}/.config
  fi
fi

if [[ `grep -c "CONFIG_PACKAGE_dnsmasq-full=y" ${HOME_PATH}/.config` -eq '1' ]]; then
  if [[ `grep -c "CONFIG_PACKAGE_dnsmasq=y" ${HOME_PATH}/.config` -eq '1' ]] || [[ `grep -c "CONFIG_PACKAGE_dnsmasq-dhcpv6=y" ${HOME_PATH}/.config` -eq '1' ]]; then
    sed -i 's/CONFIG_PACKAGE_dnsmasq=y/# CONFIG_PACKAGE_dnsmasq is not set/g' ${HOME_PATH}/.config
    sed -i 's/CONFIG_PACKAGE_dnsmasq-dhcpv6=y/# CONFIG_PACKAGE_dnsmasq-dhcpv6 is not set/g' ${HOME_PATH}/.config
  fi
fi

if [[ `grep -c "CONFIG_PACKAGE_luci-app-samba4=y" ${HOME_PATH}/.config` -eq '1' ]]; then
  if [[ `grep -c "CONFIG_PACKAGE_luci-app-samba=y" ${HOME_PATH}/.config` -eq '1' ]]; then
    sed -i 's/CONFIG_PACKAGE_autosamba=y/# CONFIG_PACKAGE_autosamba is not set/g' ${HOME_PATH}/.config
    sed -i 's/CONFIG_PACKAGE_luci-app-samba=y/# CONFIG_PACKAGE_luci-app-samba is not set/g' ${HOME_PATH}/.config
    sed -i 's/CONFIG_PACKAGE_luci-i18n-samba-zh-cn=y/# CONFIG_PACKAGE_luci-i18n-samba-zh-cn is not set/g' ${HOME_PATH}/.config
    sed -i 's/CONFIG_PACKAGE_samba36-server=y/# CONFIG_PACKAGE_samba36-server is not set/g' ${HOME_PATH}/.config
    TIME r "您同时选择luci-app-samba和luci-app-samba4，插件有冲突，相同功能插件只能二选一，已删除luci-app-samba"
  fi
elif [[ `grep -c "CONFIG_PACKAGE_samba4-server=y" ${HOME_PATH}/.config` -eq '1' ]]; then
  echo "# CONFIG_PACKAGE_samba4-admin is not set" >> ${HOME_PATH}/.config
  echo "# CONFIG_PACKAGE_samba4-client is not set" >> ${HOME_PATH}/.config
  echo "# CONFIG_PACKAGE_samba4-libs is not set" >> ${HOME_PATH}/.config
  echo "# CONFIG_PACKAGE_samba4-server is not set" >> ${HOME_PATH}/.config
  echo "# CONFIG_PACKAGE_samba4-utils is not set" >> ${HOME_PATH}/.config
fi

if [[ `grep -c "CONFIG_PACKAGE_luci-app-dockerman=y" ${HOME_PATH}/.config` -eq '0' ]] || [[ `grep -c "CONFIG_PACKAGE_luci-app-docker=y" ${HOME_PATH}/.config` -eq '0' ]]; then
  echo "# CONFIG_PACKAGE_luci-lib-docker is not set" >> ${HOME_PATH}/.config
  echo "# CONFIG_PACKAGE_luci-i18n-dockerman-zh-cn is not set" >> ${HOME_PATH}/.config
  echo "# CONFIG_PACKAGE_docker is not set" >> ${HOME_PATH}/.config
  echo "# CONFIG_PACKAGE_dockerd is not set" >> ${HOME_PATH}/.config
  echo "# CONFIG_PACKAGE_runc is not set" >> ${HOME_PATH}/.config
fi

if [[ `grep -c "CONFIG_PACKAGE_luci-theme-argon=y" ${HOME_PATH}/.config` -eq '1' ]]; then
  pmg="$(date +%M | grep -o '.$').jpg"
  [[ ! -d "${HOME_PATH}/files/www/luci-static/argon/background" ]] && mkdir -p "${HOME_PATH}/files/www/luci-static/argon/background"
  cp -Rf "$LINSHI_COMMON/Share/argon/jpg/${pmg}" "${HOME_PATH}/files/www/luci-static/argon/background/argon.jpg"
  if [[ $? -ne 0 ]]; then
    echo "拉取文件错误,请检测网络"
    exit 1
  fi
  if [[ `grep -c "CONFIG_PACKAGE_luci-theme-argon_new=y" ${HOME_PATH}/.config` -eq '1' ]]; then
    sed -i 's/CONFIG_PACKAGE_luci-theme-argon_new=y/# CONFIG_PACKAGE_luci-theme-argon_new is not set/g' ${HOME_PATH}/.config
    TIME r "您同时选择luci-theme-argon和luci-theme-argon_new，插件有冲突，相同功能插件只能二选一，已删除luci-theme-argon_new"
  fi
  if [[ `grep -c "CONFIG_PACKAGE_luci-theme-argonne=y" ${HOME_PATH}/.config` -eq '1' ]]; then
    sed -i 's/CONFIG_PACKAGE_luci-theme-argonne=y/# CONFIG_PACKAGE_luci-theme-argonne is not set/g' ${HOME_PATH}/.config
    TIME r "您同时选择luci-theme-argon和luci-theme-argonne，插件有冲突，相同功能插件只能二选一，已删除luci-theme-argonne"
  fi
fi

if [[ `grep -c "CONFIG_PACKAGE_luci-app-sfe=y" ${HOME_PATH}/.config` -eq '1' ]]; then
  if [[ `grep -c "CONFIG_PACKAGE_luci-app-flowoffload=y" ${HOME_PATH}/.config` -eq '1' ]]; then
    sed -i 's/CONFIG_DEFAULT_luci-app-flowoffload=y/# CONFIG_DEFAULT_luci-app-flowoffload is not set/g' ${HOME_PATH}/.config
    sed -i 's/CONFIG_PACKAGE_luci-app-flowoffload=y/# CONFIG_PACKAGE_luci-app-flowoffload is not set/g' ${HOME_PATH}/.config
    sed -i 's/CONFIG_PACKAGE_luci-i18n-flowoffload-zh-cn=y/# CONFIG_PACKAGE_luci-i18n-flowoffload-zh-cn is not set/g' ${HOME_PATH}/.config
    TIME r "提示：您同时选择了luci-app-sfe和luci-app-flowoffload，两个ACC网络加速，已删除luci-app-flowoffload"
  fi
fi

if [[ `grep -c "CONFIG_PACKAGE_libustream-wolfssl=y" ${HOME_PATH}/.config` -eq '1' ]]; then
  if [[ `grep -c "CONFIG_PACKAGE_libustream-openssl=y" ${HOME_PATH}/.config` -eq '1' ]]; then
    sed -i 's/CONFIG_PACKAGE_libustream-wolfssl=y/# CONFIG_PACKAGE_libustream-wolfssl is not set/g' ${HOME_PATH}/.config
  fi
fi

if [[ `grep -c "CONFIG_PACKAGE_luci-app-unblockneteasemusic=y" ${HOME_PATH}/.config` -eq '1' ]]; then
  if [[ `grep -c "CONFIG_PACKAGE_luci-app-unblockneteasemusic-go=y" ${HOME_PATH}/.config` -eq '1' ]]; then
    sed -i 's/CONFIG_PACKAGE_luci-app-unblockneteasemusic-go=y/# CONFIG_PACKAGE_luci-app-unblockneteasemusic-go is not set/g' ${HOME_PATH}/.config
    TIME r "您选择了luci-app-unblockneteasemusic-go，会和luci-app-unblockneteasemusic冲突导致编译错误，已删除luci-app-unblockneteasemusic-go"
  fi
  if [[ `grep -c "CONFIG_PACKAGE_luci-app-unblockmusic=y" ${HOME_PATH}/.config` -eq '1' ]]; then
    sed -i 's/CONFIG_PACKAGE_luci-app-unblockmusic=y/# CONFIG_PACKAGE_luci-app-unblockmusic is not set/g' ${HOME_PATH}/.config
    TIME r "您选择了luci-app-unblockmusic，会和luci-app-unblockneteasemusic冲突导致编译错误，已删除luci-app-unblockmusic"
  fi
fi

if [[ `grep -c "CONFIG_TARGET_armvirt=y" ${HOME_PATH}/.config` -eq '1' ]] || [[ `grep -c "CONFIG_TARGET_armsr=y" ${HOME_PATH}/.config` -eq '1' ]]; then
  echo -e "\nCONFIG_TARGET_ROOTFS_TARGZ=y" >> "${HOME_PATH}/.config"
  sed -i 's/CONFIG_PACKAGE_luci-app-autoupdate=y/# CONFIG_PACKAGE_luci-app-autoupdate is not set/g' ${HOME_PATH}/.config
fi

if [[ `grep -c "CONFIG_TARGET_x86=y" ${HOME_PATH}/.config` -eq '1' ]] || [[ `grep -c "CONFIG_TARGET_rockchip=y" ${HOME_PATH}/.config` -eq '1' ]] || [[ `grep -c "CONFIG_TARGET_bcm27xx=y" ${HOME_PATH}/.config` -eq '1' ]]; then
  echo -e "\nCONFIG_PACKAGE_snmpd=y" >> "${HOME_PATH}/.config"
  echo -e "\nCONFIG_TARGET_IMAGES_GZIP=y" >> "${HOME_PATH}/.config"
  echo -e "\nCONFIG_PACKAGE_openssh-sftp-server=y" >> "${HOME_PATH}/.config"
  echo -e "\nCONFIG_GRUB_IMAGES=y" >> "${HOME_PATH}/.config"
  if [[ `grep -c "CONFIG_TARGET_ROOTFS_PARTSIZE=" ${HOME_PATH}/.config` -eq '1' ]]; then
    PARTSIZE="$(grep -Eo "CONFIG_TARGET_ROOTFS_PARTSIZE=[0-9]+" ${HOME_PATH}/.config |cut -f2 -d=)"
    if [[ "${PARTSIZE}" -lt "400" ]];then
      sed -i '/CONFIG_TARGET_ROOTFS_PARTSIZE/d' ${HOME_PATH}/.config
      echo -e "\nCONFIG_TARGET_ROOTFS_PARTSIZE=400" >> ${HOME_PATH}/.config
    fi
  fi
fi
if [[ `grep -c "CONFIG_TARGET_mxs=y" ${HOME_PATH}/.config` -eq '1' ]] || [[ `grep -c "CONFIG_TARGET_sunxi=y" ${HOME_PATH}/.config` -eq '1' ]] || [[ `grep -c "CONFIG_TARGET_zynq=y" ${HOME_PATH}/.config` -eq '1' ]]; then
  echo -e "\nCONFIG_TARGET_IMAGES_GZIP=y" >> "${HOME_PATH}/.config"
  echo -e "\nCONFIG_PACKAGE_openssh-sftp-server=y" >> "${HOME_PATH}/.config"
  echo -e "\nCONFIG_GRUB_IMAGES=y" >> "${HOME_PATH}/.config"
  if [[ `grep -c "CONFIG_TARGET_ROOTFS_PARTSIZE=" ${HOME_PATH}/.config` -eq '1' ]]; then
    PARTSIZE="$(grep -Eo "CONFIG_TARGET_ROOTFS_PARTSIZE=[0-9]+" ${HOME_PATH}/.config |cut -f2 -d=)"
    if [[ "${PARTSIZE}" -lt "400" ]];then
      sed -i '/CONFIG_TARGET_ROOTFS_PARTSIZE/d' ${HOME_PATH}/.config
      echo -e "\nCONFIG_TARGET_ROOTFS_PARTSIZE=400" >> ${HOME_PATH}/.config
    fi
  fi
fi

if [[ `grep -c "CONFIG_PACKAGE_libopenssl-devcrypto=y" ${HOME_PATH}/.config` -eq '1' ]]; then
  if [[ `grep -c "CONFIG_PACKAGE_libopenssl-afalg_sync=y" ${HOME_PATH}/.config` -eq '1' ]]; then
    sed -i 's/CONFIG_PACKAGE_libopenssl-afalg_sync=y/# CONFIG_PACKAGE_libopenssl-afalg_sync is not set/g' ${HOME_PATH}/.config
  fi
fi

if [[ `grep -c "CONFIG_PACKAGE_luci-app-mtwifi-cfg=y" ${HOME_PATH}/.config` -eq '1' ]]; then
  if [[ `grep -c "CONFIG_PACKAGE_luci-app-mtk=y" ${HOME_PATH}/.config` -eq '1' ]]; then
    sed -i 's/CONFIG_PACKAGE_luci-app-mtk=y/# CONFIG_PACKAGE_luci-app-mtk is not set/g' ${HOME_PATH}/.config
    sed -i 's/CONFIG_PACKAGE_luci-i18n-mtk-zh-cn=y/# CONFIG_PACKAGE_luci-i18n-mtk-zh-cn is not set/g' ${HOME_PATH}/.config
  fi
fi

if [[ `grep -c "CONFIG_PACKAGE_dnsmasq_full_nftset=y" ${HOME_PATH}/.config` -eq '1' ]]; then
  if [[ `grep -c "CONFIG_PACKAGE_luci-app-passwall2_Nftables_Transparent_Proxy=y" ${HOME_PATH}/.config` -eq '1' ]]; then
    sed -i 's/CONFIG_PACKAGE_dnsmasq_full_nftset=y/# CONFIG_PACKAGE_dnsmasq_full_nftset is not set/g' ${HOME_PATH}/.config
    sed -i 's/CONFIG_PACKAGE_luci-app-passwall2_Nftables_Transparent_Proxy=y/# CONFIG_PACKAGE_luci-app-passwall2_Nftables_Transparent_Proxy is not set/g' ${HOME_PATH}/.config
    sed -i 's/CONFIG_PACKAGE_nftables-json=y/# CONFIG_PACKAGE_nftables-json is not set/g' ${HOME_PATH}/.config
  fi
fi

if [[ "${REPO_BRANCH}" == *"18.06"* ]] || [[ "${REPO_BRANCH}" == *"19.07"* ]] || [[ "${REPO_BRANCH}" == *"21.02"* ]] || [[ "${REPO_BRANCH}" == *"22.03"* ]] || [[ "${REPO_BRANCH}" == *"23.05"* ]]; then
  if [[ "${REPO_BRANCH}" == *"22.03"* ]]; then
    sed -i '/CONFIG_PACKAGE_kmod-fs-nfsd=y/d' ${HOME_PATH}/.config
    sed -i '/CONFIG_PACKAGE_kmod-fs-nfs-common-rpcsec=y/d' ${HOME_PATH}/.config
    sed -i '/CONFIG_PACKAGE_kmod-fs-nfs-common=y/d' ${HOME_PATH}/.config
  fi
  if [[ `grep -c "CONFIG_PACKAGE_luci-app-ssr-plus_INCLUDE_Shadowsocks_Rust_Client=y" ${HOME_PATH}/.config` -eq '1' ]]; then
    sed -i '/CONFIG_PACKAGE_luci-app-ssr-plus_INCLUDE_Shadowsocks_Libev_Client/d' ${HOME_PATH}/.config
    sed -i '/CONFIG_PACKAGE_luci-app-ssr-plus_INCLUDE_Shadowsocks_Rust_Client/d' ${HOME_PATH}/.config
    sed -i '/CONFIG_PACKAGE_shadowsocks-libev-ss-local/d' ${HOME_PATH}/.config
    sed -i '/CONFIG_PACKAGE_shadowsocks-libev-ss-redir/d' ${HOME_PATH}/.config
    echo -e "\nCONFIG_PACKAGE_luci-app-ssr-plus_INCLUDE_Shadowsocks_Libev_Client=y" >> ${HOME_PATH}/.config
    echo -e "\n# CONFIG_PACKAGE_luci-app-ssr-plus_INCLUDE_Shadowsocks_Rust_Client is not set" >> ${HOME_PATH}/.config
    echo -e "\nCONFIG_PACKAGE_shadowsocks-libev-ss-local=y" >> ${HOME_PATH}/.config
    echo -e "\nCONFIG_PACKAGE_shadowsocks-libev-ss-redir=y" >> ${HOME_PATH}/.config
  fi
  if [[ `grep -c "CONFIG_PACKAGE_luci-app-ssr-plus_INCLUDE_Shadowsocks_Rust_Server=y" ${HOME_PATH}/.config` -eq '1' ]]; then
    sed -i '/CONFIG_PACKAGE_luci-app-ssr-plus_INCLUDE_Shadowsocks_Libev_Server/d' ${HOME_PATH}/.config
    sed -i '/CONFIG_PACKAGE_luci-app-ssr-plus_INCLUDE_Shadowsocks_Rust_Server/d' ${HOME_PATH}/.config
    sed -i '/CONFIG_PACKAGE_shadowsocks-rust-ssserver/d' ${HOME_PATH}/.config
    echo -e "\nCONFIG_PACKAGE_luci-app-ssr-plus_INCLUDE_Shadowsocks_Libev_Server=y" >> ${HOME_PATH}/.config
    echo -e "\n# CONFIG_PACKAGE_luci-app-ssr-plus_INCLUDE_Shadowsocks_Rust_Server is not set" >> ${HOME_PATH}/.config
    echo -e "\n# CONFIG_PACKAGE_shadowsocks-rust-ssserver is not set" >> ${HOME_PATH}/.config
  fi
  if [[ `grep -c "CONFIG_PACKAGE_dns2socks-rust=y" ${HOME_PATH}/.config` -eq '1' ]]; then
    sed -i 's/CONFIG_PACKAGE_dns2socks-rust=y/# CONFIG_PACKAGE_dns2socks-rust is not set/g' ${HOME_PATH}/.config
    sed -i 's/CONFIG_PACKAGE_luci-app-ssr-plus_INCLUDE_DNS2SOCKS_RUST=y/# CONFIG_PACKAGE_luci-app-ssr-plus_INCLUDE_DNS2SOCKS_RUST is not set/g' ${HOME_PATH}/.config
    echo -e "\nCONFIG_PACKAGE_dns2socks=y" >> ${HOME_PATH}/.config
  fi
  if [[ `grep -c "CONFIG_PACKAGE_shadowsocks-rust-sslocal=y" ${HOME_PATH}/.config` -eq '1' ]]; then
    sed -i '/CONFIG_PACKAGE_shadowsocks-rust-sslocal=y/d' ${HOME_PATH}/.config
    echo -e "\n# CONFIG_PACKAGE_shadowsocks-rust-sslocal is not set" >> ${HOME_PATH}/.config
  fi
  if [[ `grep -c "CONFIG_PACKAGE_shadowsocks-rust-ssserver=y" ${HOME_PATH}/.config` -eq '1' ]]; then
    sed -i '/CONFIG_PACKAGE_shadowsocks-rust-ssserver=y/d' ${HOME_PATH}/.config
    echo -e "\n# CONFIG_PACKAGE_shadowsocks-rust-ssserver is not set" >> ${HOME_PATH}/.config
  fi
  if [[ `grep -c "CONFIG_PACKAGE_shadowsocks-rust-ssmanager=y" ${HOME_PATH}/.config` -eq '1' ]]; then
    sed -i '/CONFIG_PACKAGE_shadowsocks-rust-ssmanager=y/d' ${HOME_PATH}/.config
    echo -e "\n# CONFIG_PACKAGE_shadowsocks-rust-ssmanager is not set" >> ${HOME_PATH}/.config
  fi
  if [[ `grep -c "CONFIG_PACKAGE_shadowsocks-rust-ssurl=y" ${HOME_PATH}/.config` -eq '1' ]]; then
    sed -i '/CONFIG_PACKAGE_shadowsocks-rust-ssurl=y/d' ${HOME_PATH}/.config
    echo -e "\n# CONFIG_PACKAGE_shadowsocks-rust-ssurl is not set" >> ${HOME_PATH}/.config
  fi
  if [[ -n "$(grep -E "CONFIG_PACKAGE_luci-app-passwall2_INCLUDE_Shadowsocks_Rust_Client=y" ${HOME_PATH}/.config)" ]]; then
    sed -i 's/CONFIG_PACKAGE_luci-app-passwall2_INCLUDE_Shadowsocks_Rust_Client=y/# CONFIG_PACKAGE_luci-app-passwall2_INCLUDE_Shadowsocks_Rust_Client is not set/g' ${HOME_PATH}/.config
  fi
  if [[ -n "$(grep -E "CONFIG_PACKAGE_luci-app-passwall2_INCLUDE_Shadowsocks_Rust_Server=y" ${HOME_PATH}/.config)" ]]; then
    sed -i 's/CONFIG_PACKAGE_luci-app-passwall2_INCLUDE_Shadowsocks_Rust_Server=y/# CONFIG_PACKAGE_luci-app-passwall2_INCLUDE_Shadowsocks_Rust_Server is not set/g' ${HOME_PATH}/.config
  fi
  if [[ -n "$(grep -E "CONFIG_PACKAGE_luci-app-passwall_INCLUDE_Shadowsocks_Rust_Client=y" ${HOME_PATH}/.config)" ]]; then
    sed -i 's/CONFIG_PACKAGE_luci-app-passwall_INCLUDE_Shadowsocks_Rust_Client=y/# CONFIG_PACKAGE_luci-app-passwall_INCLUDE_Shadowsocks_Rust_Client is not set/g' ${HOME_PATH}/.config
  fi
  if [[ -n "$(grep -E "CONFIG_PACKAGE_luci-app-passwall_INCLUDE_Shadowsocks_Rust_Server=y" ${HOME_PATH}/.config)" ]]; then
    sed -i 's/CONFIG_PACKAGE_luci-app-passwall_INCLUDE_Shadowsocks_Rust_Server=y/# CONFIG_PACKAGE_luci-app-passwall_INCLUDE_Shadowsocks_Rust_Server is not set/g' ${HOME_PATH}/.config
  fi 
fi

! grep -q "CONFIG_PACKAGE_auto-scripts=y" "${HOME_PATH}/.config" && echo "CONFIG_PACKAGE_auto-scripts=y" >> "${HOME_PATH}/.config"

if [[ `grep -c "CONFIG_TARGET_ROOTFS_EXT4FS=y" ${HOME_PATH}/.config` -eq '1' ]]; then
  PARTSIZE=$(awk -F= '/^CONFIG_TARGET_ROOTFS_PARTSIZE=/{print $2}' ${HOME_PATH}/.config | tr -d '[:space:]')
  PARTSIZE=$(echo "${PARTSIZE}" | grep -o -E '[0-9]+')
  CONSIZE="950"
  if [[ "${PARTSIZE}" -lt "${CONSIZE}" ]]; then
    sed -i '/CONFIG_TARGET_ROOTFS_PARTSIZE/d' ${HOME_PATH}/.config
    echo -e "\nCONFIG_TARGET_ROOTFS_PARTSIZE=950" >> ${HOME_PATH}/.config
    TIME r "EXT4提示：分区大小${PARTSIZE}M小于推荐值950M"
    TIME r "已自动调整为950M"
  fi
fi

cd ${HOME_PATH}
make defconfig > /dev/null 2>&1
./scripts/diffconfig.sh > ${CONFIG_TXT}

d="CONFIG_CGROUPFS_MOUNT_KERNEL_CGROUPS=y,CONFIG_DOCKER_CGROUP_OPTIONS=y,CONFIG_DOCKER_NET_MACVLAN=y,CONFIG_DOCKER_STO_EXT4=y, \
CONFIG_KERNEL_CGROUP_DEVICE=y,CONFIG_KERNEL_CGROUP_FREEZER=y,CONFIG_KERNEL_CGROUP_NET_PRIO=y,CONFIG_KERNEL_EXT4_FS_POSIX_ACL=y,CONFIG_KERNEL_EXT4_FS_SECURITY=y, \
CONFIG_KERNEL_FS_POSIX_ACL=y,CONFIG_KERNEL_NET_CLS_CGROUP=y,CONFIG_PACKAGE_btrfs-progs=y,CONFIG_PACKAGE_cgroupfs-mount=y, \
CONFIG_PACKAGE_containerd=y,CONFIG_PACKAGE_docker=y,CONFIG_PACKAGE_dockerd=y,CONFIG_PACKAGE_fdisk=y,CONFIG_PACKAGE_kmod-asn1-encoder=y,CONFIG_PACKAGE_kmod-br-netfilter=y, \
CONFIG_PACKAGE_kmod-crypto-rng=y,CONFIG_PACKAGE_kmod-crypto-sha256=y,CONFIG_PACKAGE_kmod-dax=y,CONFIG_PACKAGE_kmod-dm=y,CONFIG_PACKAGE_kmod-dummy=y,CONFIG_PACKAGE_kmod-fs-btrfs=y, \
CONFIG_PACKAGE_kmod-ikconfig=y,CONFIG_PACKAGE_kmod-keys-encrypted=y,CONFIG_PACKAGE_kmod-keys-trusted=y,CONFIG_PACKAGE_kmod-lib-raid6=y,CONFIG_PACKAGE_kmod-lib-xor=y, \
CONFIG_PACKAGE_kmod-lib-zstd=y,CONFIG_PACKAGE_kmod-nf-ipvs=y,CONFIG_PACKAGE_kmod-oid-registry=y,CONFIG_PACKAGE_kmod-random-core=y,CONFIG_PACKAGE_kmod-tpm=y, \
CONFIG_PACKAGE_kmod-veth=y,CONFIG_PACKAGE_libdevmapper=y,CONFIG_PACKAGE_liblzo=y,CONFIG_PACKAGE_libnetwork=y,CONFIG_PACKAGE_libseccomp=y,CONFIG_PACKAGE_luci-i18n-docker-zh-cn=y, \
CONFIG_PACKAGE_luci-i18n-dockerman-zh-cn=y,CONFIG_PACKAGE_luci-lib-docker=y,CONFIG_PACKAGE_mount-utils=y,CONFIG_PACKAGE_runc=y,CONFIG_PACKAGE_tini=y,CONFIG_PACKAGE_naiveproxy=y, \
CONFIG_PACKAGE_samba36-server=y,CONFIG_PACKAGE_samba4-libs=y,CONFIG_PACKAGE_samba4-server=y"
k=(${d//,/ })
for x in "${k[@]}"; do \
  sed -i "/${x}/d" "${CONFIG_TXT}"; \
done
sed -i '/^$/d' "${CONFIG_TXT}"

# 前面修改的文件改回去
sed -i -E '/^\t/! s/^ +//' "${DEFAULT_PATH}"
! grep -q "exit 0" "$DEFAULT_PATH" && sed -i '$a\exit 0' "${DEFAULT_PATH}"
}



