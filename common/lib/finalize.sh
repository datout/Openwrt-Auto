#!/usr/bin/env bash
# shellcheck shell=bash
# post-menu preparation helpers; sourced by common.sh.

function Diy_management() {
cd ${HOME_PATH}
# 机型为armsr_rootfs_tar_gz的时,修改cpufreq代码适配Armvirt
if [[ "${TARGET_BOARD}" =~ (armvirt|armsr) ]]; then
  for X in $(find "${HOME_PATH}" -type d -name "luci-app-cpufreq"); do \
    [[ -d "$X" ]] && \
    sed -i 's/LUCI_DEPENDS.*/LUCI_DEPENDS:=\@\(arm\|\|aarch64\)/g' "$X/Makefile"; \
  done
fi

if [[ ! -f "${HOME_PATH}/staging_dir/host/bin/upx" ]]; then
  cp -Rf /usr/bin/upx ${HOME_PATH}/staging_dir/host/bin/upx
  cp -Rf /usr/bin/upx-ucl ${HOME_PATH}/staging_dir/host/bin/upx-ucl
fi

# 正在执行插件语言修改
if [[ ! -d "${HOME_PATH}/feeds/luci/modules/luci-mod-system" ]]; then
  cd "${HOME_PATH}" && bash "$LINSHI_COMMON/language/zh-cn.sh"
fi
# files文件夹删除LICENSE,README
[[ -d "${HOME_PATH}/files" ]] && sudo chmod +x ${HOME_PATH}/files
rm -rf ${HOME_PATH}/files/{LICENSE,README}
}

