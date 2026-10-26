#!/usr/bin/env bash
# shellcheck shell=bash
# menuconfig/config preparation helpers; sourced by common.sh.

function _validate_immortalwrt_x86_seed() {
  local config_path="$1"

  [[ "${SOURCE_CODE:-}" == "IMMORTALWRT" && "${CONFIG_FILE:-}" == "x86_64" ]] || return 0
  [[ -s "${config_path}" ]] || {
    TIME r "ImmortalWrt x86_64 seed不存在或为空：${config_path}"
    return 1
  }

  # Native Kconfig savedefconfig may omit x86_64/generic when they are
  # defaults beneath CONFIG_TARGET_x86.  The seed only needs to preserve
  # the non-default board selection; the effective subtarget/device is
  # verified after make defconfig expands the seed.
  if ! grep -qx 'CONFIG_TARGET_x86=y' "${config_path}"; then
    TIME r "ImmortalWrt x86_64 seed缺少必要目标锚点：CONFIG_TARGET_x86=y"
    TIME r "拒绝继续，避免 make defconfig 回落到其他默认 target（例如 mediatek/filogic）"
    return 1
  fi
}

function _validate_immortalwrt_x86_target() {
  local config_path="$1"
  local context="$2"
  local symbol
  local -a required_symbols=(
    CONFIG_TARGET_x86
    CONFIG_TARGET_x86_64
    CONFIG_TARGET_x86_64_DEVICE_generic
  )
  local -a missing_symbols=()

  [[ "${SOURCE_CODE:-}" == "IMMORTALWRT" && "${CONFIG_FILE:-}" == "x86_64" ]] || return 0
  [[ -s "${config_path}" ]] || {
    TIME r "ImmortalWrt x86_64 ${context}不存在或为空：${config_path}"
    return 1
  }

  for symbol in "${required_symbols[@]}"; do
    grep -qx "${symbol}=y" "${config_path}" || missing_symbols+=("${symbol}=y")
  done

  if (( ${#missing_symbols[@]} > 0 )); then
    TIME r "ImmortalWrt x86_64 ${context}缺少目标架构：${missing_symbols[*]}"
    TIME r "拒绝继续，避免 make defconfig 回落到其他默认 target（例如 mediatek/filogic）"
    return 1
  fi
}

function Diy_partsh() {
TIME y "正在执行：自定义文件"
cd ${HOME_PATH}
# 运行自定义文件
${DIY_PT1_SH}
./scripts/feeds update -a &>/dev/null
}


function Diy_scripts() {
TIME y "正在执行：更新和安装feeds"
# 运行自定义后,检测主题是否可用
cd ${HOME_PATH}
_validate_immortalwrt_x86_seed "${MYCONFIG_FILE}" || exit 1
# 主题设置
if [[ ! "${Mandatory_theme}" == "0" ]] && [[ -n "${Mandatory_theme}" ]]; then
  sed -i "/${Mandatory_theme}/d" $MYCONFIG_FILE
  echo "CONFIG_PACKAGE_luci-theme-$Mandatory_theme=y" >>$MYCONFIG_FILE
  SEARCH_DIRS=("${HOME_PATH}/package" "${HOME_PATH}/feeds")
  TARGET_DIR="luci-theme-${Mandatory_theme}"
  if find "${SEARCH_DIRS[@]}" -type d -name "$TARGET_DIR" -print -quit | grep -q .; then
    [[ -f "${HOME_PATH}/feeds/luci/collections/luci/Makefile" ]] && sed -i -E "s/(\+luci-theme-)[^ \\]*/\1${Mandatory_theme}/g" "${HOME_PATH}/feeds/luci/collections/luci/Makefile"
    [[ -f "${HOME_PATH}/feeds/luci/collections/luci-light/Makefile" ]] && sed -i -E "s/(\+luci-theme-)[^ \\]*/\1${Mandatory_theme}/g" "${HOME_PATH}/feeds/luci/collections/luci-light/Makefile"
  fi
fi
if [[ ! "${Default_theme}" == "0" ]] && [[ -n "${Default_theme}" ]]; then
  sed -i "/${Default_theme}/d" $MYCONFIG_FILE
  echo "CONFIG_PACKAGE_luci-theme-$Default_theme=y" >>$MYCONFIG_FILE
fi


# ----------------------------------------------------------
# ImmortalWrt stable branches: force Go 1.26 for packages that require go>=1.25
# - REPO_BRANCH: openwrt-23.05 / openwrt-24.10 (and variants)
# - openwrt-25.12: follow upstream Go; feeds.sh keeps upstream xray-core for toolchain compatibility
# - master: follow upstream (do not override)
# Source of golang overlay:
#   1) datout feed snapshot: feeds/datout/packages_lang_golang (preferred)
#   2) fallback: clone sbwml/packages_lang_golang (26.x)
# ----------------------------------------------------------
if [[ "${SOURCE_CODE}" == "IMMORTALWRT" ]] && [[ "${REPO_BRANCH}" != "master" ]] && [[ "${REPO_BRANCH}" =~ (23\.05|24\.10|2410) ]]; then
  TIME y "ImmortalWrt ${REPO_BRANCH}: 强制使用 Go 1.26（兼容 xray-core 等 go>=1.25）"
  if [[ -d "${HOME_PATH}/feeds/datout/packages_lang_golang/golang" ]]; then
    rm -rf "${HOME_PATH}/feeds/packages/lang/golang"
    mkdir -p "${HOME_PATH}/feeds/packages/lang/golang"
    cp -a "${HOME_PATH}/feeds/datout/packages_lang_golang/." "${HOME_PATH}/feeds/packages/lang/golang/"
  else
    rm -rf "${HOME_PATH}/feeds/packages/lang/golang"
    git clone --depth=1 https://github.com/sbwml/packages_lang_golang -b 26.x "${HOME_PATH}/feeds/packages/lang/golang"
  fi

  # Clear old host go artifacts/caches to avoid still using previous toolchain
  rm -rf "${HOME_PATH}/staging_dir/hostpkg/stamp/.golang"* \
         "${HOME_PATH}/build_dir/hostpkg/go-"* \
         "${HOME_PATH}/tmp/go-build" \
         "${HOME_PATH}/dl/go-mod-cache" || true

  # show version in logs
  grep -n "GO_VERSION_MAJOR_MINOR" "${HOME_PATH}/feeds/packages/lang/golang/golang/Makefile" | head -n 3 || true
fi

# 更新和安装feeds
./scripts/feeds install -a &>/dev/null
./scripts/feeds install -a

# 使用自定义配置文件
[[ -f "$MYCONFIG_FILE" ]] && cp -Rf $MYCONFIG_FILE .config
}


function Diy_profile() {
TIME y "正在执行：识别源码编译为何机型"
cd ${HOME_PATH}
make defconfig > /dev/null 2>&1
_validate_immortalwrt_x86_target "${HOME_PATH}/.config" "最终 .config" || exit 1
variable TARGET_BOARD="$(awk -F '[="]+' '/TARGET_BOARD/{print $2}' ${HOME_PATH}/.config)"
variable TARGET_SUBTARGET="$(awk -F '[="]+' '/TARGET_SUBTARGET/{print $2}' ${HOME_PATH}/.config)"
variable TARGET_PROFILE_DG="$(awk -F '[="]+' '/TARGET_PROFILE/{print $2}' ${HOME_PATH}/.config)"
if [[ -n "$(grep -Eo 'CONFIG_TARGET.*x86.*64.*=y' ${HOME_PATH}/.config)" ]]; then
  variable TARGET_PROFILE="x86-64"
elif [[ -n "$(grep -Eo 'CONFIG_TARGET.*x86.*=y' ${HOME_PATH}/.config)" ]]; then
  variable TARGET_PROFILE="x86-32"
elif [[ -n "$(grep -Eo 'CONFIG_TARGET.*DEVICE.*phicomm.*n1=y' ${HOME_PATH}/.config)" ]]; then
  variable TARGET_PROFILE="phicomm_n1"
elif grep -Eq "TARGET_armvirt=y|TARGET_armsr=y" "$HOME_PATH/.config"; then
  variable TARGET_PROFILE="armsr_rootfs_tar_gz"
elif [[ -n "$(grep -Eo 'CONFIG_TARGET.*DEVICE.*=y' ${HOME_PATH}/.config)" ]]; then
  variable TARGET_PROFILE="$(grep -Eo "CONFIG_TARGET.*DEVICE.*=y" ${HOME_PATH}/.config | sed -r 's/.*DEVICE_(.*)=y/\1/')"
else
  variable TARGET_PROFILE="${TARGET_PROFILE_DG}"
fi
variable FIRMWARE_PATH=${HOME_PATH}/bin/targets/${TARGET_BOARD}/${TARGET_SUBTARGET}
variable TARGET_OPENWRT=openwrt/bin/targets/${TARGET_BOARD}/${TARGET_SUBTARGET}
echo -e "正在编译：${TARGET_PROFILE}\n"
}


