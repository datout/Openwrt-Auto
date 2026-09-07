#!/bin/bash
# AutoUpdate integration for datout/Openwrt-Auto
# Compatible with the current Hyy2001X/AutoBuild-Packages autoupdate interface.

AUTOUPDATE_VERSION=9.1
AUTOUPDATE_TAG=AutoUpdate

function Patch_Autoupdate() {
	local script="${HOME_PATH}/package/autoupdate/files/bin/autoupdate"
	local luci_root="${HOME_PATH}/package/luci-app-autoupdate"
	local custom_root="${LINSHI_COMMON}/autoupdate"

	if [[ ! -f "${script}" ]]; then
		echo "未找到 autoupdate 主程序: ${script}"
		return 1
	fi

	cp -f "${script}" "${script}.upstream"

	python3 - "${script}" <<'PY'
from pathlib import Path
import re
import sys

path = Path(sys.argv[1])
text = path.read_text(encoding="utf-8")

# GitHub API, release assets and script checks all use official GitHub URLs.
text = text.replace(
    '--url "${Github_API}@@1 $(Proxy_X ${Github_Release}/API G@@1 F@@1 E@@1)"',
    '--url "${Github_API}@@3"',
)
text = text.replace(
    '--url "$(Proxy_X ${Github_Release} G@@1 F@@1 E@@1)"',
    '--url "${Github_Release}@@3"',
)
text = text.replace('URL="$(Proxy_X ${CLOUD_FW_Url} ${Proxy_Type}@@5)"', 'URL="${CLOUD_FW_Url}"')
text = text.replace('URL="$(Proxy_X ${CLOUD_FW_Url} G@@2 X@@1 E@@1 F@@1)"', 'URL="${CLOUD_FW_Url}"')
text = text.replace('URL="$(Proxy_X ${CLOUD_FW_Url} X@@2 G@@1 E@@1 F@@1)"', 'URL="${CLOUD_FW_Url}"')
text = text.replace('URL="$(Proxy_X ${Script_Url} G@@1 X@@1)"', 'URL="${Script_Url}"')
text = text.replace('URL="$(Proxy_X ${Script_Url} X@@1 G@@1 F@@1)"', 'URL="${Script_Url}"')
text = text.replace('ECHO r "Google 连接错误,优先使用镜像加速下载!"', 'ECHO y "Google 连接失败,继续直连 GitHub ..."')
text = text.replace('Proxy_Type="All"', 'Proxy_Type="Direct"')

# Query the dedicated AutoUpdate release by tag instead of depending on GitHub's latest release.
text = text.replace(
    'Github_API="https://api.github.com/repos/${Firmware_Author}/releases/latest"',
    'Github_API="https://api.github.com/repos/${Firmware_Author}/releases/tags/AutoUpdate"',
)

# Missing variables must not deliberately stall commands for one second per item.
missing_delay = '\t\t\tECHO r "未检测到环境变量: [${i}]"\n\t\t\tsleep 1'
if missing_delay not in text:
    raise SystemExit('Unable to remove missing-environment delay: anchor not found')
text = text.replace(
    missing_delay,
    '\t\t\tECHO r "未检测到环境变量: [${i}]"\n\t\t\t:',
    1,
)

# x86 publishes both legacy and UEFI images. Select the matching release asset at runtime.
marker = '# DATOUT_RUNTIME_BOOT_FLAG'
if marker not in text:
    needle = 'TARGET_SUBTARGET="$(cut -d \'/\' -f2 <<< ${DISTRIB_TARGET})"\n'
    block = '''TARGET_SUBTARGET="$(cut -d '/' -f2 <<< ${DISTRIB_TARGET})"
\t# DATOUT_RUNTIME_BOOT_FLAG
\tif [[ "${TARGET_BOARD}" == "x86" ]]; then
\t\tcase "${TARGET_FLAG}" in
\t\t\t*UEFI|*Legacy) ;;
\t\t\t*)
\t\t\t\tif [[ -d /sys/firmware/efi ]]; then
\t\t\t\t\tTARGET_FLAG="${TARGET_FLAG}UEFI"
\t\t\t\telse
\t\t\t\t\tTARGET_FLAG="${TARGET_FLAG}Legacy"
\t\t\t\tfi
\t\t\t;;
\t\tesac
\tfi
'''
    if needle not in text:
        raise SystemExit('Unable to insert x86 runtime flag: anchor not found')
    text = text.replace(needle, block, 1)

# The bundled script carries project-specific patches, so do not replace it with an unpatched upstream copy.
if '# DATOUT_DISABLE_SELF_UPDATE' not in text:
    pattern = re.compile(r'(?m)^(\t\t-x\)\n\t\t\tshift\n)')
    replacement = (
        '\t\t-x)\n'
        '\t\t\t# DATOUT_DISABLE_SELF_UPDATE\n'
        '\t\t\tECHO y "autoupdate 脚本由固件编译项目维护,请通过固件更新获取新版脚本。"\n'
        '\t\t\texit 0\n'
    )
    text, count = pattern.subn(replacement, text, count=1)
    if count != 1:
        raise SystemExit('Unable to disable autoupdate self-update: anchor not found')

required = [
    '${Github_API}@@3',
    '/releases/tags/AutoUpdate',
    '# DATOUT_RUNTIME_BOOT_FLAG',
    '# DATOUT_DISABLE_SELF_UPDATE',
]
missing = [item for item in required if item not in text]
if missing:
    raise SystemExit('AutoUpdate patch verification failed: ' + ', '.join(missing))

path.write_text(text, encoding="utf-8")
PY

	if [[ $? -ne 0 ]]; then
		echo "autoupdate 主程序补丁失败"
		return 1
	fi

	# Replace the slow LuCI pages with local-file readers. Opening a page no longer launches
	# the full autoupdate shell program several times.
	install -m 0644 "${custom_root}/main.lua" \
		"${luci_root}/luasrc/model/cbi/autoupdate/main.lua"
	install -m 0644 "${custom_root}/manual.lua" \
		"${luci_root}/luasrc/model/cbi/autoupdate/manual.lua"
	install -m 0644 "${custom_root}/controller.lua" \
		"${luci_root}/luasrc/controller/autoupdate.lua"
	install -m 0755 "${custom_root}/autoupdate.init" \
		"${luci_root}/root/etc/init.d/autoupdate"

	chmod +x "${script}"
	echo "AutoUpdate 已适配新版配置、GitHub直连和x86启动模式"
}

function Diy_Part1() {
	find "${HOME_PATH}" -type d -name 'luci-app-autoupdate' -prune -exec rm -rf {} + 2>/dev/null || true
	rm -rf "${HOME_PATH}/package/autoupdate"

	local tmpdir
	tmpdir="$(mktemp -d)"
	if git clone -q --depth=1 https://github.com/Hyy2001X/AutoBuild-Packages "${tmpdir}"; then
		[[ -d "${tmpdir}/autoupdate" ]] || {
			echo "上游仓库缺少 autoupdate 目录"
			rm -rf "${tmpdir}"
			return 1
		}
		[[ -d "${tmpdir}/luci-app-autoupdate" ]] || {
			echo "上游仓库缺少 luci-app-autoupdate 目录"
			rm -rf "${tmpdir}"
			return 1
		}

		cp -a "${tmpdir}/autoupdate" "${HOME_PATH}/package/autoupdate"
		cp -a "${tmpdir}/luci-app-autoupdate" "${HOME_PATH}/package/luci-app-autoupdate"
		rm -rf "${tmpdir}"

		Patch_Autoupdate || return 1

		if ! grep -qw "luci-app-autoupdate" "${HOME_PATH}/include/target.mk"; then
			sed -i 's?DEFAULT_PACKAGES:=?DEFAULT_PACKAGES:=luci-app-autoupdate autoupdate luci-app-ttyd ?g' \
				"${HOME_PATH}/include/target.mk"
		fi
		echo "增加定时更新固件的插件下载完成"
	else
		rm -rf "${tmpdir}"
		echo "增加定时更新固件的插件下载失败"
		return 1
	fi
}

function Diy_Part2() {
	local repo_path version_base config_default author_name

	repo_path="${REPO_URL#https://github.com/}"
	repo_path="${repo_path%.git}"
	export OP_AUTHOR="${repo_path%%/*}"
	export OP_REPO="${repo_path##*/}"
	export OP_BRANCH="${REPO_BRANCH}"

	version_base="$(printf '%s' "${LUCI_EDITION}" | grep -Eo '[0-9]+([.][0-9]+)*' | head -n1)"
	[[ -n "${version_base}" ]] || version_base="0"

	export OP_VERSION="R${version_base}-${UPGRADE_DATE}"
	export TARGET_FLAG="$(printf '%s' "${SOURCE}" | tr -cd '[:alnum:]')"
	[[ -n "${TARGET_FLAG}" ]] || TARGET_FLAG="OpenWrt"

	export UPDATE_TAG="${AUTOUPDATE_TAG}"
	export GITHUB_RELEASE="${GITHUB_LINK}/releases/tag/${UPDATE_TAG}"
	export FIRMWARE_VERSION="${OP_VERSION}"
	author_name="${GIT_REPOSITORY%%/*}"
	[[ -n "${author_name}" ]] || author_name="${GIT_ACTOR}"

	case "${TARGET_BOARD}" in
		ramips|realtek|reltek|ath*|ipq*|bmips|kirkwood|mediatek|bcm4908|gemini|lantiq|layerscape|qualcommax|qualcommbe|siflower|silicon)
			export FIRMWARE_SUFFIX=".bin"
		;;
		bcm47xx)
			if echo "${TARGET_PROFILE}" | grep -Eq 'asus'; then
				export FIRMWARE_SUFFIX=".trx"
			elif echo "${TARGET_PROFILE}" | grep -Eq 'netgear'; then
				export FIRMWARE_SUFFIX=".chk"
			else
				export FIRMWARE_SUFFIX=".bin"
			fi
		;;
		x86|rockchip|bcm27xx|mxs|sunxi|zynq|loongarch64|omap|sifiveu|tegra|amlogic|mvebu)
			export FIRMWARE_SUFFIX=".img.gz"
		;;
		bcm53xx)
			if echo "${TARGET_PROFILE}" | grep -Eq 'mr32|tplink|dlink'; then
				export FIRMWARE_SUFFIX=".bin"
			elif echo "${TARGET_PROFILE}" | grep -Eq 'luxul'; then
				export FIRMWARE_SUFFIX=".lxl"
			elif echo "${TARGET_PROFILE}" | grep -Eq 'netgear'; then
				export FIRMWARE_SUFFIX=".chk"
			else
				export FIRMWARE_SUFFIX=".trx"
			fi
		;;
		octeon|oxnas|pistachio)
			export FIRMWARE_SUFFIX=".tar"
		;;
		*)
			export FIRMWARE_SUFFIX=".bin"
		;;
	esac

	config_default="${HOME_PATH}/package/autoupdate/files/etc/autoupdate/default"
	install -d -m 0755 "$(dirname "${config_default}")"
	cat > "${config_default}" <<EOF_CONFIG
# Generated by datout/Openwrt-Auto. User overrides are stored in /etc/autoupdate/custom.
Author=${author_name}
Github=${GITHUB_LINK}
TARGET_PROFILE=${TARGET_PROFILE}
TARGET_FLAG=${TARGET_FLAG}
OP_VERSION=${OP_VERSION}
OP_AUTHOR=${OP_AUTHOR}
OP_BRANCH=${OP_BRANCH}
OP_REPO=${OP_REPO}
Log_Path=/tmp
EOF_CONFIG

	# Remove the obsolete configuration consumed by old AutoUpdate releases.
	rm -f "${HOME_PATH}/package/base-files/files/etc/openwrt_update"

	{
		echo "UPDATE_TAG=${UPDATE_TAG}"
		echo "FIRMWARE_SUFFIX=${FIRMWARE_SUFFIX}"
		echo "AUTOUPDATE_VERSION=${AUTOUPDATE_VERSION}"
		echo "FIRMWARE_VERSION=${FIRMWARE_VERSION}"
		echo "GITHUB_RELEASE=${GITHUB_RELEASE}"
		echo "OP_AUTHOR=${OP_AUTHOR}"
		echo "OP_REPO=${OP_REPO}"
		echo "OP_BRANCH=${OP_BRANCH}"
		echo "OP_VERSION=${OP_VERSION}"
		echo "TARGET_FLAG=${TARGET_FLAG}"
	} >> "${GITHUB_ENV}"

	# Variables for deleting only the previous online-update assets of this source/device.
	install -m 0755 /dev/null "${GITHUB_WORKSPACE}/del_assets"
	{
		echo "UPDATE_TAG=\"${UPDATE_TAG}\""
		if [[ "${TARGET_BOARD}" == "x86" ]]; then
			echo "DELETE_PREFIX_1=\"AutoBuild-${OP_REPO}-${TARGET_PROFILE}-${TARGET_FLAG}Legacy-\""
			echo "DELETE_PREFIX_2=\"AutoBuild-${OP_REPO}-${TARGET_PROFILE}-${TARGET_FLAG}UEFI-\""
		else
			echo "DELETE_PREFIX_1=\"AutoBuild-${OP_REPO}-${TARGET_PROFILE}-${TARGET_FLAG}-\""
		fi
	} >> "${GITHUB_WORKSPACE}/del_assets"

	echo "AutoUpdate环境文件: ${config_default}"
	cat "${config_default}"
}

function _copy_autoupdate_firmware() {
	local source_file="$1"
	local target_flag="$2"
	local sha5 target_name

	[[ -f "${source_file}" ]] || return 1
	sha5="$(sha256sum "${source_file}" | awk '{print substr($1,1,5)}')"
	target_name="AutoBuild-${OP_REPO}-${TARGET_PROFILE}-${target_flag}-${OP_VERSION}-${sha5}${FIRMWARE_SUFFIX}"
	cp -f "${source_file}" "${BIN_PATH}/${target_name}"
	echo "在线更新固件: ${target_name}"
}

function Diy_Part3() {
	local up_file efi_file

	BIN_PATH="${HOME_PATH}/bin/Firmware"
	echo "BIN_PATH=${BIN_PATH}" >> "${GITHUB_ENV}"
	rm -rf "${BIN_PATH}"
	mkdir -p "${BIN_PATH}"

	cd "${FIRMWARE_PATH}" || return 1
	if compgen -G '*.img' >/dev/null && ! compgen -G '*.img.gz' >/dev/null; then
		gzip -f9n ./*.img
	fi

	case "${TARGET_BOARD}" in
		x86)
			efi_file="$(find . -maxdepth 1 -type f -name '*squashfs*efi*img.gz' \
				! -name '*.vmdk*' ! -name '*.vdi*' ! -name '*.vhd*' ! -name '*ext4*' \
				! -name '*rootfs*' ! -name '*factory*' ! -name '*kernel*' \
				| sort | head -n1)"
			up_file="$(find . -maxdepth 1 -type f -name '*squashfs*img.gz' ! -name '*efi*' \
				! -name '*.vmdk*' ! -name '*.vdi*' ! -name '*.vhd*' ! -name '*ext4*' \
				! -name '*rootfs*' ! -name '*factory*' ! -name '*kernel*' \
				| sort | head -n1)"

			if [[ -n "${up_file}" ]]; then
				_copy_autoupdate_firmware "${up_file}" "${TARGET_FLAG}Legacy"
			else
				echo "未找到x86 legacy squashfs img.gz固件"
			fi
			if [[ -n "${efi_file}" ]]; then
				_copy_autoupdate_firmware "${efi_file}" "${TARGET_FLAG}UEFI"
			else
				echo "未找到x86 UEFI squashfs img.gz固件"
			fi
		;;
		*)
			up_file="$(find . -maxdepth 1 -type f \
				\( -name "*${TARGET_PROFILE}*sysupgrade*${FIRMWARE_SUFFIX}" \
				-o -name "*${TARGET_PROFILE}*squashfs*${FIRMWARE_SUFFIX}" \
				-o -name "*${TARGET_PROFILE}*combined*${FIRMWARE_SUFFIX}" \
				-o -name "*${TARGET_PROFILE}*sdcard*${FIRMWARE_SUFFIX}" \) \
				! -name '*.vmdk*' ! -name '*.vdi*' ! -name '*.vhd*' ! -name '*factory*' ! -name '*kernel*' \
				| sort | head -n1)"
			if [[ -n "${up_file}" ]]; then
				_copy_autoupdate_firmware "${up_file}" "${TARGET_FLAG}"
			else
				echo "没找到在线升级可用的${FIRMWARE_SUFFIX}格式固件，或者没适配该机型"
			fi
		;;
	esac

	echo -e "\n\033[0;32m远程更新固件\033[0m"
	find "${BIN_PATH}" -maxdepth 1 -type f -printf '%f\n' | sort
	cd "${HOME_PATH}" || return 1
}
