#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
UPGRADE_SH="${ROOT_DIR}/common/upgrade.sh"
WORK_DIR="$(mktemp -d)"
trap 'rm -rf "${WORK_DIR}"' EXIT

# The production patch is embedded in upgrade.sh as patch source, but this
# regression test intentionally uses only Bash/awk/sed. Extract the generated
# shell snippets directly and exercise their runtime behavior.
extract_block() {
  local marker="$1"
  awk -v marker="${marker}" -v end="'''" '
    index($0, marker) {
      in_block=1
      rest=substr($0, index($0, marker) + length(marker))
      if (rest != "") print rest
      next
    }
    in_block && $0 == end { exit }
    in_block { print }
  ' "${UPGRADE_SH}" | sed -E 's/^(\\t)+//'
}

grep -q '# DATOUT_RUNTIME_BOOT_FLAG' "${UPGRADE_SH}"
grep -q '# DATOUT_X86_ASSET_GUARD' "${UPGRADE_SH}"
grep -q 'AutoBuild-${OP_REPO}-${TARGET_PROFILE}-${TARGET_FLAG}-' "${UPGRADE_SH}"

autoupdate_fixture="${WORK_DIR}/autoupdate"
{
  cat <<'FIXTURE'
#!/bin/bash
Github_API="https://api.github.com/repos/${Firmware_Author}/releases/latest"
Proxy_Type="All"
function LOGGER() { :; }
function ECHO() { :; }
function NETWORK_FIXTURE() { :; }
function DELAY_FIXTURE() { :; }
function LOAD_VARIABLE() {
  DISTRIB_TARGET="x86/64"
  TARGET_BOARD="x86"
FIXTURE
  extract_block "block = '''"
  cat <<'FIXTURE'
}

function GET_FW_INFO() {
FIXTURE
  extract_block "x86_exact = '''"
  cat <<'FIXTURE'
  Result="$(awk '{print $1}' <<< "${Info}")"
  echo "${Result}"
}

function UPGRADE() {
  CLOUD_FW_Name=$(GET_FW_INFO 1)
  CLOUD_FW_Format=$(GET_FW_INFO 2)
  CLOUD_FW_Size=$(GET_FW_INFO 7)
FIXTURE
  extract_block "cloud_guard = '''"
  cat <<'FIXTURE'
  :
}
}
FIXTURE
} > "${autoupdate_fixture}"

bash -n "${autoupdate_fixture}"

# UEFI: stale LedeLegacy must be normalized to LedeUEFI.
mkdir -p "${WORK_DIR}/bin"
printf '#!/bin/sh\necho "efi: EFI v2.70"\n' > "${WORK_DIR}/bin/dmesg"
chmod +x "${WORK_DIR}/bin/dmesg"
PATH="${WORK_DIR}/bin:${PATH}" bash -c 'source "$1"; TARGET_FLAG=LedeLegacy; LOAD_VARIABLE; test "$TARGET_FLAG" = LedeUEFI' _ "${autoupdate_fixture}"

# Legacy: stale LedeUEFI must be normalized to LedeLegacy when the runtime has no EFI interface.
if [[ ! -d /sys/firmware/efi ]]; then
  printf '#!/bin/sh\nexit 0\n' > "${WORK_DIR}/bin/dmesg"
  PATH="${WORK_DIR}/bin:${PATH}" bash -c 'source "$1"; TARGET_FLAG=LedeUEFI; LOAD_VARIABLE; test "$TARGET_FLAG" = LedeLegacy' _ "${autoupdate_fixture}"
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
source "${autoupdate_fixture}"
selected="$(GET_FW_INFO 1)"
test "${selected}" = 'AutoBuild-Openwrt-Auto-x86_64-LedeUEFI-R24.10.5-1793186620-bbbbb.img.gz'

# Safety guard: if an x86 UEFI check somehow resolves a Legacy asset, flashing must stop.
cat > "${WORK_DIR}/legacy-only-api" <<'API'
AutoBuild-Openwrt-Auto-x86_64-LedeLegacy-R24.10.5-1793186620-aaaaa.img.gz img.gz 0 aaaaa R24.10.5-1793186620 202610281840 100 https://example.invalid/legacy
API
API_File="${WORK_DIR}/legacy-only-api"
if env TARGET_BOARD=x86 TARGET_FLAG=LedeUEFI OP_REPO=Openwrt-Auto TARGET_PROFILE=x86_64 API_File="${API_File}" \
    bash -c 'source "$1"; UPGRADE' _ "${autoupdate_fixture}" >/dev/null 2>&1; then
  echo 'x86 asset guard failed to reject Legacy asset on UEFI' >&2
  exit 1
fi

echo 'AutoUpdate x86 UEFI/Legacy regression: OK'
