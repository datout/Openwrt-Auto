#!/bin/bash
# Core runtime helpers shared by common.sh.
# This file is sourced; do not enable set -e/set -u here.

function TIME() {
  case "$1" in
    r) local Color="\033[0;31m" ;;
    g) local Color="\033[0;32m" ;;
    y) local Color="\033[0;33m" ;;
    b) local Color="\033[0;34m" ;;
    z) local Color="\033[0;35m" ;;
    l) local Color="\033[0;36m" ;;
    *) local Color="\033[0;0m" ;;
  esac
  echo -e "\n${Color}${2}\033[0m"
}

function variable() {
  local overall="$1"
  export "${overall}"
  echo "${overall}" >> "${GITHUB_ENV}"
}

function detect_upstream_luci_edition() {
  # Clone 完源码后，从上游 include/version.mk 读取实际版本号。
  local version_file=""
  local version_number=""
  local file

  for file in \
    "${HOME_PATH}/include/version.mk" \
    "${GITHUB_WORKSPACE}/openwrt/include/version.mk" \
    "openwrt/include/version.mk"; do
    if [[ -f "${file}" ]]; then
      version_file="${file}"
      break
    fi
  done

  if [[ -n "${version_file}" ]]; then
    version_number=$(awk -F ':=' '
      /^[[:space:]]*VERSION_NUMBER[[:space:]]*:=/ {
        v=$2
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", v)
        if (match(v, /[0-9]+(\.[0-9]+)+/)) { last=substr(v, RSTART, RLENGTH) }
        else if (v ~ /SNAPSHOT/) { last="SNAPSHOT" }
      }
      END { print last }
    ' "${version_file}")

    if [[ -n "${version_number}" ]]; then
      variable LUCI_EDITION="${version_number}"
      TIME g "已根据上游源码 ${version_file} 设置 LUCI_EDITION=${LUCI_EDITION}"
    else
      TIME y "未能从 ${version_file} 读取 VERSION_NUMBER，继续使用 LUCI_EDITION=${LUCI_EDITION}"
    fi
  else
    TIME y "未找到 include/version.mk，继续使用 LUCI_EDITION=${LUCI_EDITION}"
  fi
}
