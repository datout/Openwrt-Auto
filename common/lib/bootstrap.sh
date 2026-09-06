#!/usr/bin/env bash
# shellcheck shell=bash
# source/bootstrap variable helpers; sourced by common.sh.

function Diy_variable() {
# 读取变量
case "${SOURCE_CODE}" in
COOLSNOWWOLF)
  variable REPO_URL="https://github.com/coolsnowwolf/lede"
  variable SOURCE="Lede"
  variable SOURCE_OWNER="Lean"
  # 初始值只做 clone 前兜底；clone 完成后会从上游 include/version.mk 自动覆盖。
  variable LUCI_EDITION="$(echo "${REPO_BRANCH}" | sed 's/openwrt-//g')"
  variable DISTRIB_SOURCECODE="lede"
  variable GENE_PATH="${HOME_PATH}/package/base-files/files/bin/config_generate"
;;
LIENOL)
  variable REPO_URL="https://github.com/Lienol/openwrt"
  variable SOURCE="Lienol"
  variable SOURCE_OWNER="Lienol"
  variable DISTRIB_SOURCECODE="lienol"
  variable LUCI_EDITION="$(echo "${REPO_BRANCH}" |sed 's/openwrt-//g')"
  variable GENE_PATH="${HOME_PATH}/package/base-files/files/bin/config_generate"
;;
IMMORTALWRT)
  variable REPO_URL="https://github.com/immortalwrt/immortalwrt"
  variable SOURCE="Immortalwrt"
  variable SOURCE_OWNER="ctcgfw"
  variable DISTRIB_SOURCECODE="immortalwrt"
  variable LUCI_EDITION="$(echo "${REPO_BRANCH}" |sed 's/openwrt-//g')"
  variable GENE_PATH="${HOME_PATH}/package/base-files/files/bin/config_generate"
;;
XWRT)
  variable REPO_URL="https://github.com/x-wrt/x-wrt"
  variable SOURCE="Xwrt"
  variable SOURCE_OWNER="ptpt52"
  variable DISTRIB_SOURCECODE="xwrt"
  variable LUCI_EDITION="$(echo "${REPO_BRANCH}" |sed 's/openwrt-//g')"
  variable GENE_PATH="${HOME_PATH}/package/base-files/files/bin/config_generate"
;;
OFFICIAL)
  variable REPO_URL="https://github.com/openwrt/openwrt"
  variable SOURCE="Official"
  variable SOURCE_OWNER="openwrt"
  variable DISTRIB_SOURCECODE="official"
  variable LUCI_EDITION="$(echo "${REPO_BRANCH}" |sed 's/openwrt-//g')"
  variable GENE_PATH="${HOME_PATH}/package/base-files/files/bin/config_generate"
;;
MT798X)
  if [[ "${REPO_BRANCH}" == "hanwckf-21.02" ]]; then
    echo "hanwckf-21.02"
    variable REPO_URL="https://github.com/hanwckf/immortalwrt-mt798x"
    variable SOURCE="Mt798x"
    variable SOURCE_OWNER="hanwckf"
    variable REPO_BRANCH="openwrt-21.02"
    variable DISTRIB_SOURCECODE="immortalwrt"
    variable LUCI_EDITION="$(echo "${REPO_BRANCH}" |sed 's/openwrt-//g')"
    variable GENE_PATH="${HOME_PATH}/package/base-files/files/bin/config_generate"
  else
    variable REPO_URL="https://github.com/padavanonly/immortalwrt-mt798x-6.6"
    variable SOURCE="Mt798x"
    variable SOURCE_OWNER="padavanonly"
    if [[ "${REPO_BRANCH}" == "openwrt-24.10-6.6" ]]; then
      variable LUCI_EDITION="24.10"
    elif [[ "${REPO_BRANCH}" == "2410" ]]; then
      variable REPO_BRANCH="openwrt-24.10-6.6"
      variable LUCI_EDITION="24.10"
    else
      variable LUCI_EDITION="$(echo "${REPO_BRANCH}" |sed 's/openwrt-//g')"
    fi
    variable DISTRIB_SOURCECODE="immortalwrt"
    variable GENE_PATH="${HOME_PATH}/package/base-files/files/bin/config_generate"
  fi
;;
*)
  TIME r "不支持${SOURCE_CODE}此源码，当前只支持COOLSNOWWOLF、LIENOL、IMMORTALWRT、XWRT、OFFICIALT、MT798X"
  exit 1
;;
esac

variable FILES_PATH="${HOME_PATH}/package/base-files/files/etc/shadow"
variable DELETE="${HOME_PATH}/package/base-files/files/etc/deletefile"
variable DEFAULT_PATH="${HOME_PATH}/package/auto-scripts/files/99-first-run"
variable KEEPD_PATH="${HOME_PATH}/package/base-files/files/lib/upgrade/keep.d/base-files-essential"
variable CLEAR_PATH="/tmp/Clear"
variable UPGRADE_DATE="`date -d "$(date +'%Y-%m-%d %H:%M:%S')" +%s`"
variable GUJIAN_DATE="$(date +%m.%d)"
variable LICENSES_DOC="${HOME_PATH}/LICENSES/doc"

# 启动编译时的变量文件
if [[ "${BENDI_VERSION}" == "2" ]]; then
  install -m 0755 /dev/null "${COMPILE_PATH}/relevance/settings.ini"
  VARIABLES=(
  "SOURCE_CODE" "REPO_BRANCH" "CONFIG_FILE"
  "INFORMATION_NOTICE" "UPLOAD_FIRMWARE" "UPLOAD_RELEASE"
  "CACHEWRTBUILD_SWITCH" "UPDATE_FIRMWARE_ONLINE"
  "COMPILATION_INFORMATION" "KEEP_WORKFLOWS" "KEEP_RELEASES"
  )
  for var in "${VARIABLES[@]}"; do
    echo "${var}=${!var}" >> "${COMPILE_PATH}/relevance/settings.ini"
  done

  if [[ "${REPO_URL}" == *"hanwckf"* ]]; then
    sed -i "/REPO_BRANCH/d" "${COMPILE_PATH}/relevance/settings.ini"
    echo "REPO_BRANCH=hanwckf-21.02" >> "${COMPILE_PATH}/relevance/settings.ini"
  fi
fi
}

function Diy_feedsconf() {
# 源码已 clone 到 openwrt 后，更新一次实际 LuCI/OpenWrt 版本。
# 仅 Lede master 这类不带版本号的分支需要这样做，避免再写死 23.05。
if [[ "${SOURCE_CODE}" == "COOLSNOWWOLF" ]]; then
  detect_upstream_luci_edition
fi

local LICENSES_DOC="${GITHUB_WORKSPACE}/openwrt/LICENSES/doc"
[[ ! -d "${LICENSES_DOC}" ]] && mkdir -p "${LICENSES_DOC}"
cp -Rf ${GITHUB_WORKSPACE}/openwrt/feeds.conf.default ${LICENSES_DOC}/feeds.conf.default
if [[ ! -f "${LICENSES_DOC}/feeds.conf.default" ]]; then
  TIME r "文件下载失败,请检查网络"
  exit 1
fi
}

