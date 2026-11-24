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

# Replace only the fixture's sysfs path so these cases behave identically on
# BIOS and EFI GitHub runners. Production always checks /sys/firmware/efi.
sed -i \
  -e "s@/sys/firmware/efi@${WORK_DIR}/fake-efi@g" \
  -e "s@/sys/class/block/@${WORK_DIR}/fake-class-block/@g" \
  -e "s@/proc/cmdline@${WORK_DIR}/fake-cmdline@g" \
  "${autoupdate_fixture}"
bash -n "${autoupdate_fixture}"

# Fake a standard x86 image: partition 2 is the root, partition 1 is boot.
mkdir -p "${WORK_DIR}/fake-bus/sda/sda1" "${WORK_DIR}/fake-bus/sda/sda2" "${WORK_DIR}/fake-class-block"
printf 'root=PARTUUID=11111111-02\n' > "${WORK_DIR}/fake-cmdline"
printf 'PARTUUID=11111111-02\n' > "${WORK_DIR}/fake-bus/sda/sda2/uevent"
printf '1\n' > "${WORK_DIR}/fake-bus/sda/sda1/partition"
ln -s "${WORK_DIR}/fake-bus/sda/sda2" "${WORK_DIR}/fake-class-block/sda2"

# UEFI: stale LedeLegacy must be normalized to LedeUEFI.
mkdir -p "${WORK_DIR}/bin"
printf '#!/bin/sh\nexit 1\n' > "${WORK_DIR}/bin/dmesg"
chmod +x "${WORK_DIR}/bin/dmesg"
cat > "${WORK_DIR}/bin/blkid" <<'MOCK_BLKID'
#!/bin/sh
printf '%s\n' "${FAKE_BOOTFS:-ext4}"
MOCK_BLKID
chmod +x "${WORK_DIR}/bin/blkid"
mkdir -p "${WORK_DIR}/fake-efi"
PATH="${WORK_DIR}/bin:${PATH}" bash -c 'source "$1"; TARGET_FLAG=LedeLegacy; LOAD_VARIABLE; test "$TARGET_FLAG" = LedeUEFI' _ "${autoupdate_fixture}"
rmdir "${WORK_DIR}/fake-efi"

# UEFI: the EFI boot message is an alternative when sysfs is unavailable.
printf '#!/bin/sh\necho "[    0.000] efi: EFI v2.70"\n' > "${WORK_DIR}/bin/dmesg"
PATH="${WORK_DIR}/bin:${PATH}" bash -c 'source "$1"; TARGET_FLAG=ImmortalwrtLegacy; LOAD_VARIABLE; test "$TARGET_FLAG" = ImmortalwrtUEFI' _ "${autoupdate_fixture}"

# Legacy: require recognizable early boot messages, not just missing EFI sysfs.
printf '#!/bin/sh\necho "[    0.000] Linux version 6.6.1"\n' > "${WORK_DIR}/bin/dmesg"
PATH="${WORK_DIR}/bin:${PATH}" bash -c 'source "$1"; TARGET_FLAG=LedeUEFI; LOAD_VARIABLE; test "$TARGET_FLAG" = LedeLegacy' _ "${autoupdate_fixture}"
PATH="${WORK_DIR}/bin:${PATH}" bash -c 'source "$1"; TARGET_FLAG=ImmortalwrtUEFI; LOAD_VARIABLE; test "$TARGET_FLAG" = ImmortalwrtLegacy' _ "${autoupdate_fixture}"

# A UEFI-style FAT boot partition with missing EFI sysfs must NEVER be
# classified as Legacy merely because the log contains "Linux version".
set +e
FAKE_BOOTFS=vfat PATH="${WORK_DIR}/bin:${PATH}" bash -c 'source "$1"; TARGET_FLAG=LedeUEFI; LOAD_VARIABLE; echo WRONG_SUCCESS' _ "${autoupdate_fixture}" > "${WORK_DIR}/bad-layout.out" 2>&1
result=$?
set -e
[[ "${result}" == 2 ]] && ! grep -q 'WRONG_SUCCESS' "${WORK_DIR}/bad-layout.out" || {
  echo "UEFI-style boot partition wrongly accepted as Legacy (exit ${result})" >&2
  exit 1
}

# Missing or unusable partition evidence must stop the upgrade too.
printf 'root=PARTUUID=nonexistent-02\n' > "${WORK_DIR}/fake-cmdline"
set +e
PATH="${WORK_DIR}/bin:${PATH}" bash -c 'source "$1"; TARGET_FLAG=LedeLegacy; LOAD_VARIABLE; echo WRONG_SUCCESS' _ "${autoupdate_fixture}" > "${WORK_DIR}/missing-root.out" 2>&1
result=$?
set -e
[[ "${result}" == 2 ]] && ! grep -q 'WRONG_SUCCESS' "${WORK_DIR}/missing-root.out" || {
  echo "Missing root-partition evidence wrongly accepted as Legacy (exit ${result})" >&2
  exit 1
}
printf 'root=PARTUUID=11111111-02\n' > "${WORK_DIR}/fake-cmdline"

# Unknown mode: failed/restricted dmesg, empty logs, or truncated boot logs
# must stop the process, even when a stale Legacy flag is present.
for dmesg_fixture in 'exit 1' 'exit 0' 'echo "[1234.00] ordinary driver message"'; do
  printf '#!/bin/sh\n%s\n' "${dmesg_fixture}" > "${WORK_DIR}/bin/dmesg"
  set +e
  PATH="${WORK_DIR}/bin:${PATH}" bash -c 'source "$1"; TARGET_FLAG=LedeLegacy; LOAD_VARIABLE; echo WRONG_SUCCESS' _ "${autoupdate_fixture}" > "${WORK_DIR}/unknown-mode.out" 2>&1
  result=$?
  set -e
  if [[ "${result}" != 2 ]] || grep -q 'WRONG_SUCCESS' "${WORK_DIR}/unknown-mode.out"; then
    echo "Unrecognized boot mode did not abort safely: ${dmesg_fixture}, exit ${result}" >&2
    exit 1
  fi
done

# Asset matching: x86 must select the complete boot-mode-specific label.
cat > "${WORK_DIR}/api" <<'API'
AutoBuild-Openwrt-Auto-x86_64-LedeLegacy-R24.10.5-1793186620-aaaaa.img.gz img.gz 0 aaaaa R24.10.5-1793186620 202610281840 100 https://example.invalid/legacy
AutoBuild-Openwrt-Auto-x86_64-LedeUEFI-R24.10.5-1793186620-bbbbb.img.gz img.gz 0 bbbbb R24.10.5-1793186620 202610281850 100 https://example.invalid/uefi
AutoBuild-Openwrt-Auto-x86_64-ImmortalwrtLegacy-R24.10.5-1793186620-ccccc.img.gz img.gz 0 ccccc R24.10.5-1793186620 202610281855 100 https://example.invalid/legacy
AutoBuild-Openwrt-Auto-x86_64-ImmortalwrtUEFI-R24.10.5-1793186620-ddddd.img.gz img.gz 0 ddddd R24.10.5-1793186620 202610281840 100 https://example.invalid/uefi
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
for tag in LedeLegacy LedeUEFI ImmortalwrtLegacy ImmortalwrtUEFI; do
  TARGET_FLAG="${tag}"
  selected="$(GET_FW_INFO 1)"
  [[ "${selected}" == "AutoBuild-Openwrt-Auto-x86_64-${tag}-"* ]] || {
    echo "Incorrect asset selected for ${tag}: ${selected}" >&2
    exit 1
  }
done

# Safety guard: if an x86 UEFI check somehow resolves a Legacy asset, flashing must stop.
cat > "${WORK_DIR}/legacy-only-api" <<'API'
AutoBuild-Openwrt-Auto-x86_64-LedeLegacy-R24.10.5-1793186620-aaaaa.img.gz img.gz 0 aaaaa R24.10.5-1793186620 202610281840 100 https://example.invalid/legacy
API
API_File="${WORK_DIR}/legacy-only-api"
if env TARGET_BOARD=x86 TARGET_FLAG=LedeUEFI OP_REPO=Openwrt-Auto TARGET_PROFILE=x86_64 API_File="${API_File}" \
    bash -c 'source "$1"; UPGRADE' _ "${autoupdate_fixture}" >/dev/null 2>&1; then
  echo 'x86 selection failed to reject missing UEFI asset' >&2
  exit 1
fi

# Independently exercise the final guard with deliberately wrong metadata.
if env TARGET_BOARD=x86 TARGET_FLAG=LedeUEFI OP_REPO=Openwrt-Auto TARGET_PROFILE=x86_64 API_File="${API_File}" \
    bash -c 'source "$1"; GET_FW_INFO() { if [[ "$1" == 1 ]]; then echo "AutoBuild-Openwrt-Auto-x86_64-LedeLegacy-R24.10.5-1793186620-aaaaa.img.gz"; else echo "https://example.invalid/fw"; fi; }; UPGRADE' _ "${autoupdate_fixture}" >/dev/null 2>&1; then
  echo 'x86 final asset guard accepted a Legacy image on UEFI' >&2
  exit 1
fi

echo 'AutoUpdate x86 UEFI/Legacy regression: OK'
