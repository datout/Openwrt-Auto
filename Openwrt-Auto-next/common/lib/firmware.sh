#!/usr/bin/env bash
# shellcheck shell=bash
# firmware post-build helpers; sourced by common.sh.

function Diy_firmware() {
# 远程更新处理固件
if [ "${UPDATE_FIRMWARE_ONLINE}" == "true" ]; then
  cd ${HOME_PATH}
  source $UPGRADE_SH && Diy_Part3
fi
# 编译完毕后,整理固件
cd ${FIRMWARE_PATH}
# 打包所有ipk或者apk插件
if find "${HOME_PATH}/bin/packages/" -type f -name "*.ipk" | grep -q .; then
    mkdir -p ipk
    find "${HOME_PATH}/bin/packages/" -type f -name "*.ipk" -exec mv {} ipk/ \;
elif find "${HOME_PATH}/bin/packages/" -type f -name "*.apk" | grep -q .; then
    mkdir -p apk
    find "${HOME_PATH}/bin/packages/" -type f -name "*.apk" -exec mv {} apk/ \;
fi
if [ -d "ipk" ]; then
    sync
    tar -czf ipk.tar.gz ipk
    sync
    rm -rf ipk
elif [ -d "apk" ]; then
    sync
    tar -czf apk.tar.gz apk
    sync
    rm -rf apk
fi

if [[ -n "$(ls -1 |grep -E 'immortalwrt')" ]]; then
  rename "s/^immortalwrt/openwrt/" *
  sed -i 's/immortalwrt/openwrt/g' `egrep "immortalwrt" -rl ./`
fi
TIME g "整理前的全部文件"
ls -1
for X in $(cat ${CLEAR_PATH} |sed "s/.*${TARGET_BOARD}//g"); do
  rm -rf *"$X"*
done
TIME g "整理后的文件"
ls -1
if ! echo "$TARGET_BOARD" | grep -Eq 'armvirt|armsr'; then
  rename "s/^openwrt/${GUJIAN_DATE}-${SOURCE}-${LUCI_EDITION}-${LINUX_KERNEL}/" *
  TIME g "更改名称后的固件，也是最终上传使用的"
  ls -1
fi

echo "DATE=$(date "+%Y%m%d%H%M%S")" >> ${GITHUB_ENV}
echo "TONGZHI_DATE=$(date +%Y年%m月%d日)" >> ${GITHUB_ENV}
echo "FIRMWARE_DATE=$(date +%Y-%m%d-%H%M)" >> ${GITHUB_ENV}
}


