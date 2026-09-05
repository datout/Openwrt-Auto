#!/bin/bash
# Feed/package post-processing helpers extracted from common.sh.
# This file is sourced; functions intentionally use the parent script environment.

function _remove_duplicate_package_dirs() {
  local package_name="$1"
  [[ -n "${package_name}" ]] || return 0

  find "${HOME_PATH}/feeds" "${HOME_PATH}/package" \
    -path "${HOME_PATH}/feeds/datout" -prune -o \
    -path "${HOME_PATH}/feeds/datouttheme" -prune -o \
    -path "${HOME_PATH}/feeds/OpenClash" -prune -o \
    -path "${HOME_PATH}/package/luci-theme-argon" -prune -o \
    -name "${package_name}" -type d -exec rm -rf {} +
}

function prefer_datout_feed_packages() {
  local package_name
  local -a datout_packages=()
  local legacy_conflicts
  local -a conflict_packages=()

  if [[ -d "${HOME_PATH}/feeds/datout" ]]; then
    mapfile -t datout_packages < <(
      find "${HOME_PATH}/feeds/datout" -maxdepth 2 -mindepth 2 -type f -name Makefile 2>/dev/null \
        | awk -F'/' '{print $(NF-1)}' \
        | sort -u
    )

    for package_name in "${datout_packages[@]}"; do
      _remove_duplicate_package_dirs "${package_name}"
    done
  fi

  # Historical compatibility list: preserve previous behaviour even when a
  # package is not present as a top-level datout Makefile for a given branch.
  legacy_conflicts="luci-theme-argon,luci-app-argon-config,luci-theme-Butterfly,luci-theme-netgear,luci-theme-atmaterial,\
luci-theme-rosy,luci-theme-darkmatter,luci-theme-infinityfreedom,luci-theme-design,luci-app-design-config,\
luci-theme-bootstrap-mod,luci-theme-freifunk-generic,luci-theme-opentomato,luci-theme-kucat,\
luci-app-eqos,adguardhome,luci-app-adguardhome,mosdns,luci-app-mosdns,luci-app-openclash,\
luci-app-gost,gost,luci-app-smartdns,smartdns,luci-app-wizard,luci-app-msd_lite,msd_lite,\
luci-app-ssr-plus,luci-app-passwall,luci-app-passwall2,shadowsocksr-libev,v2dat,v2ray-geodata,\
luci-app-wechatpush,v2ray-core,v2ray-plugin,v2raya,xray-core,xray-plugin,luci-app-alist,alist"
  IFS=',' read -r -a conflict_packages <<< "${legacy_conflicts}"
  for package_name in "${conflict_packages[@]}"; do
    package_name="${package_name//[[:space:]]/}"
    _remove_duplicate_package_dirs "${package_name}"
  done
}

function apply_datout_branch_filters() {
  if [[ ! "${REPO_BRANCH}" =~ ^(main|master|(openwrt-)?(24\.10))$ ]]; then
    rm -rf \
      "${HOME_PATH}/feeds/datout/luci-app-fancontrol" \
      "${HOME_PATH}/feeds/datout/luci-app-qmodem" \
      "${HOME_PATH}/feeds/datout/relevance/quectel_cm-5G"
  fi

  if [[ "${REPO_BRANCH}" =~ ^(2410|(openwrt-)?(24\.10))$ ]]; then
    rm -rf \
      "${HOME_PATH}/feeds/datout/luci-app-quickstart" \
      "${HOME_PATH}/feeds/datout/luci-app-linkease" \
      "${HOME_PATH}/feeds/datout/luci-app-istorex"
  fi

  if [[ ! -d "${HOME_PATH}/package/network/config/firewall4" ]]; then
    rm -rf \
      "${HOME_PATH}/feeds/datout/luci-app-nikki" \
      "${HOME_PATH}/feeds/datout/luci-app-homeproxy"
  fi
}

function ensure_common_feed_dependencies() {
  # Keep OpenWrt/LEDE's own golang; only replace the node-prebuilt feed.
  gitsvn \
    https://github.com/sbwml/feeds_packages_lang_node-prebuilt \
    "${HOME_PATH}/feeds/packages/lang/node"

  if [[ -d "${HOME_PATH}/feeds/datout/relevance/nas-packages/network/services" ]] \
    && [[ ! -d "${HOME_PATH}/package/network/services/ddnsto" ]]; then
    mv "${HOME_PATH}/feeds/datout/relevance/nas-packages/network/services/"* \
      "${HOME_PATH}/package/network/services"
  fi

  if [[ -d "${HOME_PATH}/feeds/datout/relevance/nas-packages/multimedia/ffmpeg-remux" ]] \
    && [[ ! -d "${HOME_PATH}/feeds/packages/multimedia/ffmpeg-remux" ]]; then
    mv "${HOME_PATH}/feeds/datout/relevance/nas-packages/multimedia/ffmpeg-remux" \
      "${HOME_PATH}/feeds/packages/multimedia/ffmpeg-remux"
  fi

  bash "${LINSHI_COMMON}/Share/tproxy/nft_tproxy.sh"

  if [[ ! -d "${HOME_PATH}/feeds/packages/lang/rust" ]]; then
    gitsvn \
      https://github.com/openwrt/packages/tree/openwrt-24.10/lang/rust \
      "${HOME_PATH}/feeds/packages/lang/rust"
  fi

  if [[ ! -d "${HOME_PATH}/feeds/packages/devel/packr" ]]; then
    mkdir -p "${HOME_PATH}/feeds/packages/devel"
    cp -Rf "${LINSHI_COMMON}/Share/packr" "${HOME_PATH}/feeds/packages/devel/packr"
  fi
}

function Diy_feed_postprocess() {
  prefer_datout_feed_packages
  apply_datout_branch_filters
  ensure_common_feed_dependencies
}
