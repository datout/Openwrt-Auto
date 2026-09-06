#!/bin/bash
# Feed/package post-processing helpers extracted from common.sh.
# This file is sourced; functions intentionally use the parent script environment.

function _remove_duplicate_package_dirs() {
  local package_name="$1"
  [[ -n "${package_name}" ]] || return 0
  if [[ ! "${package_name}" =~ ^[A-Za-z0-9_.+-]+$ ]]; then
    echo "Skip unsafe package name: ${package_name}" >&2
    return 0
  fi
  find "${HOME_PATH}/feeds" "${HOME_PATH}/package" \
    -path "${HOME_PATH}/feeds/datout" -prune -o \
    -path "${HOME_PATH}/feeds/datouttheme" -prune -o \
    -path "${HOME_PATH}/feeds/OpenClash" -prune -o \
    -path "${HOME_PATH}/package/luci-theme-argon" -prune -o \
    -name "${package_name}" -type d -exec rm -rf {} +
}

function _load_datout_priority_packages() {
  local priority_file
  priority_file="${DATOUT_PRIORITY_FILE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/config/datout-priority-packages.txt}"
  [[ -f "${priority_file}" ]] || return 0

  awk '
    {
      sub(/#.*/, "")
      gsub(/[[:space:]]/, "")
      if (length($0)) print $0
    }
  ' "${priority_file}"
}

function prefer_datout_feed_packages() {
  local package_name
  local -a datout_packages=()
  local -a configured_packages=()
  local -a priority_packages=()

  if [[ -d "${HOME_PATH}/feeds/datout" ]]; then
    mapfile -t datout_packages < <(
      find "${HOME_PATH}/feeds/datout" -maxdepth 2 -mindepth 2 -type f -name Makefile 2>/dev/null \
        | awk -F'/' '{print $(NF-1)}' \
        | sort -u
    )
  fi

  mapfile -t configured_packages < <(_load_datout_priority_packages)
  mapfile -t priority_packages < <(
    printf '%s\n' "${datout_packages[@]}" "${configured_packages[@]}" \
      | awk 'NF' \
      | sort -u
  )

  for package_name in "${priority_packages[@]}"; do
    _remove_duplicate_package_dirs "${package_name}"
  done

  echo "datout 优先包冲突处理：${#priority_packages[@]} 个包已检查"
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
