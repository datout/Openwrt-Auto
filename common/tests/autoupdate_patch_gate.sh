#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
WORK_DIR="$(mktemp -d)"
trap 'rm -rf "${WORK_DIR}"' EXIT

fail() { echo "AutoUpdate build gate test failed: $*" >&2; exit 1; }
TIME() { :; }

# A failed download/patch must be visible to the package checkout caller.
source "${ROOT_DIR}/common/lib/checkout.sh"
HOME_PATH="${WORK_DIR}/openwrt"
MYCONFIG_FILE="${WORK_DIR}/seed"
UPGRADE_SH="${WORK_DIR}/mock-upgrade.sh"
UPDATE_FIRMWARE_ONLINE=true
mkdir -p "${HOME_PATH}/include"
printf 'CONFIG_TARGET_x86=y\n' > "${MYCONFIG_FILE}"
printf 'DEFAULT_PACKAGES:=base-files\n' > "${HOME_PATH}/include/target.mk"
printf 'Diy_Part1() { return 74; }\n' > "${UPGRADE_SH}"
if Diy_checkout_autoupdate; then fail 'Diy_Part1 error was ignored'; fi

# An unreadable/missing integration script must also stop the checkout.
UPGRADE_SH="${WORK_DIR}/missing-upgrade.sh"
if Diy_checkout_autoupdate >/dev/null 2>&1; then fail 'missing upgrade.sh was ignored'; fi

# A successful online-update installation must be accepted.
UPGRADE_SH="${WORK_DIR}/mock-upgrade.sh"
printf 'Diy_Part1() { return 0; }\n' > "${UPGRADE_SH}"
Diy_checkout_autoupdate || fail 'successful Diy_Part1 was rejected'

# Disabled and ARM images must not call the x86 AutoUpdate downloader.
UPDATE_FIRMWARE_ONLINE=false
Diy_checkout_autoupdate || fail 'disabled online update was rejected'
UPDATE_FIRMWARE_ONLINE=true
printf 'CONFIG_TARGET_armvirt=y\n' > "${MYCONFIG_FILE}"
printf 'Diy_Part1() { return 74; }\n' > "${UPGRADE_SH}"
Diy_checkout_autoupdate || fail 'ARM exception was rejected'

# Check that Diy_menu propagates Diy_checkout failures up to GitHub Actions.
source "${ROOT_DIR}/common/common.sh"
SOURCE_CODE=TEST
Diy_checkout() { return 74; }
Diy_TEST() { touch "${WORK_DIR}/unexpected-next-stage"; }
if Diy_menu; then fail 'Diy_menu ignored checkout error'; fi
[[ ! -e "${WORK_DIR}/unexpected-next-stage" ]] || fail 'Diy_menu ran the next stage after checkout failure'

# Exercise the production Python patch, rather than only grep its source.
source "${ROOT_DIR}/common/upgrade.sh"
HOME_PATH="${WORK_DIR}/patch-tree"
LINSHI_COMMON="${ROOT_DIR}/common"
script="${HOME_PATH}/package/autoupdate/files/bin/autoupdate"
luci_root="${HOME_PATH}/package/luci-app-autoupdate"
mkdir -p "$(dirname "${script}")" \
  "${luci_root}/luasrc/model/cbi/autoupdate" \
  "${luci_root}/luasrc/controller" \
  "${luci_root}/root/etc/init.d"
cat > "${script}" <<'UPSTREAM'
#!/bin/bash
Github_API="https://api.github.com/repos/${Firmware_Author}/releases/latest"
Proxy_Type="All"
function DUMMY_API() {
	curl --url "${Github_API}@@1 $(Proxy_X ${Github_Release}/API G@@1 F@@1 E@@1)"
}
function LOAD_VARIABLE() {
	TARGET_SUBTARGET="$(cut -d '/' -f2 <<< ${DISTRIB_TARGET})"
			ECHO r "未检测到环境变量: [${i}]"
			sleep 1
}
function GET_FW_INFO() {
	Info=$(grep "AutoBuild-${OP_REPO}-${TARGET_PROFILE}" ${API_File} | grep "${TARGET_FLAG}" | awk 'BEGIN {MAX = 0} {if ($6+0 > MAX+0) {MAX=$6 ;content=$0} } END {print content}')
}
function CLOUD_INFO() {
	CLOUD_FW_Size=$(GET_FW_INFO 7)
	CLOUD_FW_Url=$(GET_FW_INFO 8)
	[[ ! ${CLOUD_FW_Name} || -z ${CLOUD_FW_Url} ]] && {
		return 1
	}
}
function PARSE_ARGS() {
	case "$1" in
		-x)
			shift
			;;
	esac
}
UPSTREAM
cp "${script}" "${WORK_DIR}/upstream-original"
Patch_Autoupdate || fail 'valid upstream fixture could not be patched'
bash -n "${script}" || fail 'patched upstream syntax is invalid'
for marker in DATOUT_RUNTIME_BOOT_FLAG DATOUT_X86_ASSET_GUARD DATOUT_DISABLE_SELF_UPDATE; do
  grep -q "${marker}" "${script}" || fail "patched upstream missing ${marker}"
done
[[ -s "${script}.upstream" ]] || fail 'upstream backup was not created'

# An unexpected upstream change MUST fail the patch and hence the build.
cp "${WORK_DIR}/upstream-original" "${script}"
sed -i '/CLOUD_FW_Url=$(GET_FW_INFO 8)/d' "${script}"
if Patch_Autoupdate >/dev/null 2>&1; then fail 'missing upstream anchor was accepted'; fi

# LuCI replacement must be mandatory: missing destination is not success.
cp "${WORK_DIR}/upstream-original" "${script}"
rm -rf "${luci_root}/luasrc/controller"
if Patch_Autoupdate >/dev/null 2>&1; then fail 'failed LuCI install was accepted'; fi

# Any shell syntax error in the resulting package must be rejected.
mkdir -p "${luci_root}/luasrc/controller"
cp "${WORK_DIR}/upstream-original" "${script}"
printf '\nif\n' >> "${script}"
if Patch_Autoupdate >/dev/null 2>&1; then fail 'invalid patched shell syntax was accepted'; fi

echo 'AutoUpdate patch/install/build-failure gate: OK'
