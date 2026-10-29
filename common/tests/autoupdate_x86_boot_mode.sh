#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
UPGRADE_SH="${ROOT_DIR}/common/upgrade.sh"
WORK_DIR="$(mktemp -d)"
trap 'rm -rf "${WORK_DIR}"' EXIT

python3 - "${UPGRADE_SH}" "${WORK_DIR}/patch.py" <<'PY'
from pathlib import Path
import sys

source = Path(sys.argv[1]).read_text(encoding="utf-8")
start_marker = 'python3 - "${script}" <<\'PY\'\n'
end_marker = '\nPY\n'
start = source.index(start_marker) + len(start_marker)
end = source.index(end_marker, start)
Path(sys.argv[2]).write_text(source[start:end], encoding="utf-8")
PY

cat > "${WORK_DIR}/autoupdate" <<'FIXTURE'
#!/bin/bash
Github_API="https://api.github.com/repos/${Firmware_Author}/releases/latest"
A='--url "${Github_API}@@1 $(Proxy_X ${Github_Release}/API G@@1 F@@1 E@@1)"'
B='--url "$(Proxy_X ${Github_Release} G@@1 F@@1 E@@1)"'
URL="$(Proxy_X ${CLOUD_FW_Url} ${Proxy_Type}@@5)"
URL="$(Proxy_X ${CLOUD_FW_Url} G@@2 X@@1 E@@1 F@@1)"
URL="$(Proxy_X ${CLOUD_FW_Url} X@@2 G@@1 E@@1 F@@1)"
URL="$(Proxy_X ${Script_Url} G@@1 X@@1)"
URL="$(Proxy_X ${Script_Url} X@@1 G@@1 F@@1)"
Proxy_Type="All"

function LOGGER() { :; }
function ECHO() { :; }
function NETWORK_FIXTURE() {
	ECHO r "Google 连接错误,优先使用镜像加速下载!"
}

function DELAY_FIXTURE() {
	for i in x; do
		if [[ ! ${ENV} ]]
		then
			ECHO r "未检测到环境变量: [${i}]"
			sleep 1
		fi
	done
}

function LOAD_VARIABLE() {
	DISTRIB_TARGET="x86/64"
	TARGET_BOARD="x86"
	TARGET_SUBTARGET="$(cut -d '/' -f2 <<< ${DISTRIB_TARGET})"
	# TARGET_FLAG is intentionally supplied by the test case.
}

function GET_FW_INFO() {
	Info=$(grep "AutoBuild-${OP_REPO}-${TARGET_PROFILE}" ${API_File} | grep "${TARGET_FLAG}" | awk 'BEGIN {MAX = 0} {if ($6+0 > MAX+0) {MAX=$6 ;content=$0} } END {print content}')
	Result="$(awk '{print $1}' <<< "${Info}")"
	echo "${Result}"
}

function UPGRADE() {
	CLOUD_FW_Name=$(GET_FW_INFO 1)
	CLOUD_FW_Format=$(GET_FW_INFO 2)
	CLOUD_FW_Size=$(GET_FW_INFO 7)
	CLOUD_FW_Url=$(GET_FW_INFO 8)
	[[ ! ${CLOUD_FW_Name} || -z ${CLOUD_FW_Url} ]] && {
		exit 2
	}
}

case "$1" in
		-x)
			shift
			true
		;;
esac
FIXTURE

python3 "${WORK_DIR}/patch.py" "${WORK_DIR}/autoupdate"
bash -n "${WORK_DIR}/autoupdate"

# UEFI: stale LedeLegacy must be normalized to LedeUEFI.
mkdir -p "${WORK_DIR}/bin"
printf '#!/bin/sh\necho "efi: EFI v2.70"\n' > "${WORK_DIR}/bin/dmesg"
chmod +x "${WORK_DIR}/bin/dmesg"
PATH="${WORK_DIR}/bin:${PATH}" bash -c 'source "$1"; TARGET_FLAG=LedeLegacy; LOAD_VARIABLE; test "$TARGET_FLAG" = LedeUEFI' _ "${WORK_DIR}/autoupdate"

# Legacy: stale LedeUEFI must be normalized to LedeLegacy when the runtime has no EFI interface.
if [[ ! -d /sys/firmware/efi ]]; then
	printf '#!/bin/sh\nexit 0\n' > "${WORK_DIR}/bin/dmesg"
	PATH="${WORK_DIR}/bin:${PATH}" bash -c 'source "$1"; TARGET_FLAG=LedeUEFI; LOAD_VARIABLE; test "$TARGET_FLAG" = LedeLegacy' _ "${WORK_DIR}/autoupdate"
fi

# Asset matching: x86 must select the complete boot-mode-specific label.
cat > "${WORK_DIR}/api" <<'API'
AutoBuild-Openwrt-Auto-x86_64-LedeLegacy-R24.10.5-1793186620-aaaaa.img.gz img.gz 0 aaaaa R24.10.5-1793186620 202610281840 100 https://example.invalid/legacy
AutoBuild-Openwrt-Auto-x86_64-LedeUEFI-R24.10.5-1793186620-bbbbb.img.gz img.gz 0 bbbbb R24.10.5-1793186620 202610281850 100 https://example.invalid/uefi
API
TARGET_BOARD=x86
TARGET_FLAG=LedeUEFI
OP_REPO=Openwrt-Auto
TARGET_PROFILE=x86_64
API_File="${WORK_DIR}/api"
Firmware_Author=example/Repo
Github_Release=https://example.invalid/releases/download/AutoUpdate
CLOUD_FW_Url=https://example.invalid/fw
Proxy_Type=Direct
Script_Url=https://example.invalid/script
set -- ""
source "${WORK_DIR}/autoupdate"
grep -q 'flag="${flag%UEFI}"' "${ROOT_DIR}/common/autoupdate/autoupdate.init"
grep -q 'flag="${flag%Legacy}"' "${ROOT_DIR}/common/autoupdate/autoupdate.init"
selected="$(GET_FW_INFO 1)"
test "${selected}" = 'AutoBuild-Openwrt-Auto-x86_64-LedeUEFI-R24.10.5-1793186620-bbbbb.img.gz'

# Safety guard: if an x86 UEFI check somehow resolves a Legacy asset, flashing must stop.
cat > "${WORK_DIR}/legacy-only-api" <<'API'
AutoBuild-Openwrt-Auto-x86_64-LedeLegacy-R24.10.5-1793186620-aaaaa.img.gz img.gz 0 aaaaa R24.10.5-1793186620 202610281840 100 https://example.invalid/legacy
API
API_File="${WORK_DIR}/legacy-only-api"
export API_File TARGET_BOARD TARGET_FLAG OP_REPO TARGET_PROFILE Firmware_Author Github_Release CLOUD_FW_Url Proxy_Type Script_Url
if env TARGET_BOARD=x86 TARGET_FLAG=LedeUEFI OP_REPO=Openwrt-Auto TARGET_PROFILE=x86_64 API_File="${API_File}" \
    bash -c 'source "$1"; UPGRADE' _ "${WORK_DIR}/autoupdate" >/dev/null 2>&1; then
	echo 'x86 asset guard failed to reject Legacy asset on UEFI' >&2
	exit 1
fi

echo 'AutoUpdate x86 UEFI/Legacy regression: OK'
