#!/usr/bin/env bash
# shellcheck shell=bash
# source/feed checkout preparation; sourced by common.sh.

function Diy_checkout() {
# 下载源码后，进行源码微调和增加插件源
TIME y "正在执行：下载和整理应用,请耐心等候..."
cd ${HOME_PATH}
# 增加一些应用
echo '#!/bin/sh' > "${DELETE}" && chmod +x "${DELETE}"
if [[ -d "${LINSHI_COMMON}/auto-scripts" ]]; then
  cp -Rf "$LINSHI_COMMON/auto-scripts" "${HOME_PATH}/package/auto-scripts"
else
  TIME r "缺少auto-scripts文件"
  exit 1
fi

sed -i "s/ZHUJI_MING/${SOURCE}/g" "${DEFAULT_PATH}"
sed -i "s/LUCI_EDITION/${LUCI_EDITION}/g" "${DEFAULT_PATH}"
sed -i "s/OPHUBOPENWRT/${DISTRIB_SOURCECODE}/g" "${DEFAULT_PATH}"
sed -i 's/root:.*/root::0:0:99999:7:::/g' "${FILES_PATH}"
grep -q "admin:" ${FILES_PATH} && sed -i 's/admin:.*/admin::0:0:99999:7:::/g' "${FILES_PATH}"

# 添加自定义插件源
srcdir="$(mktemp -d)"
SRC_LIANJIE=$(grep -Po '^src-git(?:-full)?\s+luci\s+\Khttps?://[^;\s]+' "${LICENSES_DOC}/feeds.conf.default")
SRC_FENZHIHAO=$(grep -Po '^src-git(?:-full)?\s+luci\s+[^;\s]+;\K[^\s]+' "${LICENSES_DOC}/feeds.conf.default" || echo "")
if [[ -n "${SRC_FENZHIHAO}" ]]; then
  git clone --single-branch --depth=1 --branch="${SRC_FENZHIHAO}" "${SRC_LIANJIE}" "${srcdir}"
else
  git clone --depth=1 "${SRC_LIANJIE}" "${srcdir}"
fi
if [[ $? -ne 0 ]];then
  TIME r "文件下载失败,请检查网络"
  exit 1
fi
if [[ -d "${srcdir}/modules/luci-mod-system" ]]; then
  THEME_BRANCH="Theme2"
  rm -rf "${srcdir}"
  gitsvn https://github.com/jerrykuku/luci-theme-argon/tree/master "${HOME_PATH}/package/luci-theme-argon"
  gitsvn https://github.com/jerrykuku/luci-app-argon-config/tree/master "${HOME_PATH}/package/luci-app-argon-config"
else
  THEME_BRANCH="Theme1"
  rm -rf "${srcdir}"
  gitsvn https://github.com/jerrykuku/luci-theme-argon/tree/18.06 "${HOME_PATH}/package/luci-theme-argon"
  gitsvn https://github.com/jerrykuku/luci-app-argon-config/tree/18.06 "${HOME_PATH}/package/luci-app-argon-config"
fi


echo "src-git datout https://github.com/datout/openwrt-package.git;$SOURCE" >> "${HOME_PATH}/feeds.conf.default"
echo "src-git datouttheme https://github.com/datout/openwrt-package.git;$THEME_BRANCH" >> "${HOME_PATH}/feeds.conf.default"
[[ "${OpenClash_branch}" == "1" ]] && echo "src-git OpenClash https://github.com/vernesong/OpenClash.git;master" >> "${HOME_PATH}/feeds.conf.default"
[[ "${OpenClash_branch}" == "2" ]] && echo "src-git OpenClash https://github.com/vernesong/OpenClash.git;dev" >> "${HOME_PATH}/feeds.conf.default"

# 增加中文语言包
if [[ -z "$(find "$HOME_PATH/package" -type d -name "default-settings" -print)" ]] && [[ "${THEME_BRANCH}" == "Theme2" ]]; then
  rm -rf "${HOME_PATH}/package/default-settings"
  cp -Rf "${LINSHI_COMMON}/Share/default-settings" "${HOME_PATH}/package/default-settings"
  grep -qw "libustream-wolfssl" "${HOME_PATH}/include/target.mk" && sed -i 's?\<libustream-wolfssl\>?libustream-openssl?g' "${HOME_PATH}/include/target.mk"
  ! grep -qw "dnsmasq-full" "${HOME_PATH}/include/target.mk" && sed -i 's?\<dnsmasq\>?dnsmasq-full?g' "${HOME_PATH}/include/target.mk"
  ! grep -qw "default-settings" "${HOME_PATH}/include/target.mk" && sed -i 's?DEFAULT_PACKAGES:=?DEFAULT_PACKAGES:=default-settings?g' "${HOME_PATH}/include/target.mk"
elif [[ -z "$(find "$HOME_PATH/package" -type d -name "default-settings" -print)" ]] && [[ "${THEME_BRANCH}" == "Theme1" ]]; then
  rm -rf "${HOME_PATH}/package/default-settings"
  cp -Rf "${LINSHI_COMMON}/Share/default-setting" "${HOME_PATH}/package/default-settings"
  grep -qw "libustream-wolfssl" "${HOME_PATH}/include/target.mk" && sed -i 's?\<libustream-wolfssl\>?libustream-openssl?g' "${HOME_PATH}/include/target.mk"
  ! grep -qw "dnsmasq-full" "${HOME_PATH}/include/target.mk" && sed -i 's?\<dnsmasq\>?dnsmasq-full?g' "${HOME_PATH}/include/target.mk"
  ! grep -qw "default-settings" "${HOME_PATH}/include/target.mk" && sed -i 's?DEFAULT_PACKAGES:=?DEFAULT_PACKAGES:=default-settings?g' "${HOME_PATH}/include/target.mk"
fi

# zzz-default-settings文件
variable ZZZ_PATH="$(find "$HOME_PATH/package" -name "*-default-settings" -not -path "A/exclude_dir/*" -print)"
[[ -n "${ZZZ_PATH}" ]] && grep -q "openwrt_banner" "${ZZZ_PATH}" && sed -i '/openwrt_banner/d' "${ZZZ_PATH}"

# 更新feeds
cd ${HOME_PATH}
./scripts/feeds clean
if [[ "${BENDI_VERSION}" == "2" ]]; then
  ./scripts/feeds update -a &>/dev/null
else
  ./scripts/feeds update -a
fi

# 更新feeds后再次修改补充
cd ${HOME_PATH}
# ----------------------------------------------------------
# datout feed conflict resolution / compatibility dependencies moved to lib/feeds.sh
Diy_feed_postprocess

# files大法，设置固件无烦恼
if [ -d "${BUILD_PATCHES}" ]; then
  find "${BUILD_PATCHES}" -type f -name '*.patch' -print0 | sort -z | xargs -I % -t -0 -n 1 sh -c "cat '%'  | patch -d './' -p1 --forward --no-backup-if-mismatch"
fi
if [ -d "${BUILD_DIY}" ]; then
  cp -Rf ${BUILD_DIY}/* ${HOME_PATH}
fi
if [ -d "${BUILD_FILES}" ]; then
  cp -Rf ${BUILD_FILES} ${HOME_PATH}
fi

# 定时更新固件的插件包
if grep -q "armvirt=y" $MYCONFIG_FILE || grep -q "armsr=y" $MYCONFIG_FILE; then
  find "${HOME_PATH}" -type d -name "luci-app-autoupdate" |xargs -i rm -rf {}
  if grep -q "luci-app-autoupdate" "${HOME_PATH}/include/target.mk"; then
    sed -i 's?luci-app-autoupdate ??g' ${HOME_PATH}/include/target.mk
  fi
elif [[ "${UPDATE_FIRMWARE_ONLINE}" == "true" ]]; then
    source ${UPGRADE_SH} && Diy_Part1
else
  find "${HOME_PATH}" -type d -name "luci-app-autoupdate" |xargs -i rm -rf {}
  if grep -q "luci-app-autoupdate" "${HOME_PATH}/include/target.mk"; then
    sed -i 's?luci-app-autoupdate ??g' ${HOME_PATH}/include/target.mk
  fi
fi

# N1类型固件修改
if [[ -f "${HOME_PATH}/target/linux/armsr/Makefile" ]]; then
  sed -i "s?FEATURES+=.*?FEATURES+=targz?g" ${HOME_PATH}/target/linux/armsr/Makefile
elif [[ -f "${HOME_PATH}/target/linux/armvirt/Makefile" ]]; then
  sed -i "s?FEATURES+=.*?FEATURES+=targz?g" ${HOME_PATH}/target/linux/armvirt/Makefile
fi

# 给固件保留配置更新固件的保留项目
cat >> "${KEEPD_PATH}" <<-EOF
/etc/config/AdGuardHome.yaml
/www/luci-static/argon/background
/etc/smartdns/custom.conf
EOF
}


