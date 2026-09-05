#!/usr/bin/env bash
# shellcheck shell=bash
# menuconfig/config preparation helpers; sourced by common.sh.

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


