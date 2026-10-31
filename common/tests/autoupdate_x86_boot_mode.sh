#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
UPGRADE_SH="${ROOT_DIR}/common/upgrade.sh"
WORK_DIR="$(mktemp -d)"
trap 'rm -rf "${WORK_DIR}"' EXIT

# Extract the exact shell fragments embedded in upgrade.sh without requiring Python.
extract_triple_block() {
	local marker="$1"
	awk -v marker="${marker}" '
		!found && index($0, marker " = " "\047\047\047") {
			found=1
			sub("^.*" marker " = " "\047\047\047", "")
			if (length($0)) print
			next
		}
		found && $0 == "\047\047\047" { exit }
		found { print }
	' "${UPGRADE_SH}" | sed 's/\\t/\t/g'
}

for block in block x86_exact cloud_guard; do
	extract_triple_block "${block}" > "${WORK_DIR}/${block}.sh"
	[[ -s "${WORK_DIR}/${block}.sh" ]] || {
		echo "无法从 common/upgrade.sh 提取 ${block} 补丁块" >&2
		exit 1
	}
done

grep -qF '# DATOUT_RUNTIME_BOOT_FLAG' "${WORK_DIR}/block.sh"
grep -qF '# DATOUT_X86_ASSET_GUARD' "${WORK_DIR}/cloud_guard.sh"

# UEFI: stale LedeLegacy must be normalized to LedeUEFI.
TARGET_BOARD=x86
TARGET_FLAG=LedeLegacy
DISTRIB_TARGET=x86/64
LOGGER() { :; }
mkdir -p "${WORK_DIR}/bin"
printf '#!/bin/sh\necho "efi: EFI v2.70"\n' > "${WORK_DIR}/bin/dmesg"
chmod +x "${WORK_DIR}/bin/dmesg"
PATH="${WORK_DIR}/bin:${PATH}"
source "${WORK_DIR}/block.sh"
test "${TARGET_FLAG}" = LedeUEFI

# Legacy: stale LedeUEFI must be normalized to LedeLegacy when the runtime has no EFI interface.
if [[ ! -d /sys/firmware/efi ]]; then
	TARGET_BOARD=x86
	TARGET_FLAG=LedeUEFI
	DISTRIB_TARGET=x86/64
	printf '#!/bin/sh\nexit 0\n' > "${WORK_DIR}/bin/dmesg"
	PATH="${WORK_DIR}/bin:${PATH}"
	source "${WORK_DIR}/block.sh"
	test "${TARGET_FLAG}" = LedeLegacy
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
source "${WORK_DIR}/x86_exact.sh"
selected="$(awk '{print $1}' <<< "${Info}")"
test "${selected}" = 'AutoBuild-Openwrt-Auto-x86_64-LedeUEFI-R24.10.5-1793186620-bbbbb.img.gz'

# Safety guard: if an x86 UEFI check somehow resolves a Legacy asset, flashing must stop.
cat > "${WORK_DIR}/legacy-only-api" <<'API'
AutoBuild-Openwrt-Auto-x86_64-LedeLegacy-R24.10.5-1793186620-aaaaa.img.gz img.gz 0 aaaaa R24.10.5-1793186620 202610281840 100 https://example.invalid/legacy
API
API_File="${WORK_DIR}/legacy-only-api"
TARGET_BOARD=x86
TARGET_FLAG=LedeUEFI
OP_REPO=Openwrt-Auto
TARGET_PROFILE=x86_64
Info="AutoBuild-Openwrt-Auto-x86_64-LedeLegacy-R24.10.5-1793186620-aaaaa.img.gz img.gz 0 aaaaa R24.10.5-1793186620 202610281840 100 https://example.invalid/legacy"
GET_FW_INFO() {
	awk -v n="$1" '{print $n}' <<< "${Info}"
}
CLOUD_FW_Name="$(GET_FW_INFO 1)"
CLOUD_FW_Size="$(GET_FW_INFO 7)"
CLOUD_FW_Url="$(GET_FW_INFO 9)"
ECHO() { :; }
LOGGER() { :; }
if ( source "${WORK_DIR}/cloud_guard.sh" ) >/dev/null 2>&1; then
	echo 'x86 asset guard failed to reject Legacy asset on UEFI' >&2
	exit 1
fi

echo 'AutoUpdate x86 UEFI/Legacy regression: OK'
