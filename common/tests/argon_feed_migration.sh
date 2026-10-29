#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
CHECKOUT="${ROOT_DIR}/common/lib/checkout.sh"
CONFIG="${ROOT_DIR}/common/lib/config.sh"
PRIORITY="${ROOT_DIR}/common/config/datout-priority-packages.txt"

# Argon must come from the datout package library, not direct upstream clones.
if grep -q 'github.com/jerrykuku/luci-theme-argon' "${CHECKOUT}"; then
  echo 'checkout.sh still contains a direct Argon upstream clone' >&2
  exit 1
fi
if grep -q 'github.com/jerrykuku/luci-app-argon-config' "${CHECKOUT}"; then
  echo 'checkout.sh still contains the obsolete standalone Argon config clone' >&2
  exit 1
fi
grep -q 'luci-theme-argon' "${CHECKOUT}"
grep -q 'Mandatory_theme="argon"' "${CONFIG}"
grep -q 'Default_theme="argon"' "${CONFIG}"

FEEDS="${ROOT_DIR}/common/lib/feeds.sh"
grep -q 'remove_obsolete_argon_config_package' "${FEEDS}"
grep -q 'feeds/luci/applications/luci-app-argon-config' "${FEEDS}"

# Argon is no longer hard-coded in per-source DIY files.
if grep -RqsE '^export (Mandatory_theme|Default_theme)="argon"' "${ROOT_DIR}/build"/*/diy-part.sh; then
  echo 'Argon theme settings remain in a source-specific diy-part.sh' >&2
  exit 1
fi

# The obsolete standalone config package must not be selected anymore.
if grep -Rqs 'CONFIG_PACKAGE_luci-app-argon-config=y' "${ROOT_DIR}/build"; then
  echo 'obsolete luci-app-argon-config selection remains in build seeds/configs' >&2
  exit 1
fi
if grep -q '^luci-app-argon-config$' "${PRIORITY}"; then
  echo 'obsolete luci-app-argon-config remains in datout priority list' >&2
  exit 1
fi

# Verify the post-processing helper removes the obsolete upstream package only
# when the maintained datout Argon theme is present.
TEST_ROOT="$(mktemp -d)"
trap 'rm -rf "${TEST_ROOT}"' EXIT
mkdir -p \
  "${TEST_ROOT}/feeds/datout/luci-theme-argon" \
  "${TEST_ROOT}/feeds/luci/applications/luci-app-argon-config"
HOME_PATH="${TEST_ROOT}"
source "${FEEDS}"
remove_obsolete_argon_config_package
test ! -e "${TEST_ROOT}/feeds/luci/applications/luci-app-argon-config"

rm -rf "${TEST_ROOT}/feeds/datout/luci-theme-argon"
mkdir -p "${TEST_ROOT}/feeds/luci/applications/luci-app-argon-config"
remove_obsolete_argon_config_package
test -d "${TEST_ROOT}/feeds/luci/applications/luci-app-argon-config"

echo 'Argon feed migration: OK'
