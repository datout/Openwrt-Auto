#!/bin/bash
# Source-specific adjustments extracted from common.sh.
# This file is sourced; gitsvn is resolved when these functions execute.

function Diy_COOLSNOWWOLF() {
  cd "${HOME_PATH}" || return 1
  rm -rf "${HOME_PATH}/package/wwan/driver"
}

function Diy_LIENOL() {
  cd "${HOME_PATH}" || return 1
  rm -rf "${HOME_PATH}/feeds/packages/net/miniupnpd"
  gitsvn https://github.com/openwrt/packages/tree/master/net/tailscale "${HOME_PATH}/feeds/packages/net/tailscale"

  if [[ -d "${HOME_PATH}/feeds/other/lean" ]]; then
    rm -rf \
      "${HOME_PATH}/feeds/other/lean/mt" \
      "${HOME_PATH}/feeds/other/lean/luci-app-vlmcsd" \
      "${HOME_PATH}/feeds/other/lean/vlmcsd"
  fi

  if [[ "${REPO_BRANCH}" == *"24.10"* ]]; then
    gitsvn https://github.com/coolsnowwolf/lede/tree/master/package/libs/mbedtls "${HOME_PATH}/package/libs/mbedtls"
    gitsvn https://github.com/coolsnowwolf/lede/tree/master/package/libs/ustream-ssl "${HOME_PATH}/package/libs/ustream-ssl"
    gitsvn https://github.com/coolsnowwolf/lede/tree/master/package/libs/uclient "${HOME_PATH}/package/libs/uclient"
    rm -rf "${HOME_PATH}/feeds/packages/utils/owut"
    gitsvn https://github.com/openwrt/packages/tree/master/lang/rust "${HOME_PATH}/feeds/packages/lang/rust"
  fi

  if [[ "${REPO_BRANCH}" == *"21.02"* ]]; then
    gitsvn https://github.com/coolsnowwolf/packages/tree/152022403f0ab2a85063ae1cd9687bd5240fe9b7/net/dnsproxy "${HOME_PATH}/feeds/packages/net/dnsproxy"
    gitsvn https://github.com/coolsnowwolf/lede/tree/326599e3d08d7fe1dc084e1c87581cdf5a8e41a6/package/libs/libjson-c "${HOME_PATH}/package/libs/libjson-c"
  fi
}

function Diy_IMMORTALWRT() {
  cd "${HOME_PATH}" || return 1

  if [[ "${REPO_BRANCH}" =~ (openwrt-18.06|openwrt-18.06-k5.4) ]]; then
    gitsvn https://github.com/openwrt/routing/tree/openwrt-21.02/bmx6 "${HOME_PATH}/feeds/routing/bmx6"
    rm -rf \
      "${HOME_PATH}/feeds/packages/net/shadowsocksr-libev" \
      "${HOME_PATH}/feeds/datout/luci-app-nikki" \
      "${HOME_PATH}/feeds/datout/luci-app-homeproxy"
  fi

  if [[ "${REPO_BRANCH}" == *"21.02"* ]] \
    || [[ "${REPO_BRANCH}" == *"18.06"* ]] \
    || [[ "${REPO_BRANCH}" == *"23.05"* ]]; then
    gitsvn https://github.com/coolsnowwolf/packages/tree/152022403f0ab2a85063ae1cd9687bd5240fe9b7/net/dnsproxy "${HOME_PATH}/feeds/packages/net/dnsproxy"
    gitsvn https://github.com/coolsnowwolf/lede/tree/326599e3d08d7fe1dc084e1c87581cdf5a8e41a6/package/libs/libjson-c "${HOME_PATH}/package/libs/libjson-c"
  fi
}

function Diy_XWRT() {
  cd "${HOME_PATH}" || return 1
}

function Diy_OFFICIAL() {
  cd "${HOME_PATH}" || return 1

  if [[ "${REPO_BRANCH}" == "openwrt-19.07" ]]; then
    gitsvn https://github.com/openwrt/openwrt/tree/openwrt-22.03/package/utils/bcm27xx-userland "${HOME_PATH}/package/utils/bcm27xx-userland"
    rm -rf "${HOME_PATH}/feeds/datout/luci-app-kodexplorer"
  fi

  if [[ "${REPO_BRANCH}" =~ (main|master|openwrt-24.10) ]]; then
    cp -f \
      "${LINSHI_COMMON}/Share/luci-app-nginx-pingos/Makefile" \
      "${HOME_PATH}/feeds/datout/luci-app-nginx-pingos/Makefile"
  fi

  if [[ "${REPO_BRANCH}" == *"23.05"* ]]; then
    gitsvn https://github.com/coolsnowwolf/packages/tree/152022403f0ab2a85063ae1cd9687bd5240fe9b7/net/dnsproxy "${HOME_PATH}/feeds/packages/net/dnsproxy"
    gitsvn https://github.com/coolsnowwolf/lede/tree/326599e3d08d7fe1dc084e1c87581cdf5a8e41a6/package/libs/libjson-c "${HOME_PATH}/package/libs/libjson-c"
  fi

  if [[ "${REPO_BRANCH}" =~ (main|master) ]]; then
    gitsvn https://github.com/openwrt/packages/tree/openwrt-24.10/lang/rust "${HOME_PATH}/feeds/packages/lang/rust"
  fi
}

function Diy_MT798X() {
  cd "${HOME_PATH}" || return 1
}
