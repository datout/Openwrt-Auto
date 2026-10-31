#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
FIRST_SH="${ROOT_DIR}/common/custom/first.sh"
BUILD_ENTRY="${ROOT_DIR}/.github/actions/build-entry/action.yml"
VALIDATE="${ROOT_DIR}/.github/workflows/validate.yml"

# Diy_four replaces diy-part.sh with a filtered temporary file. The replacement
# must restore the executable bit before Diy_partsh executes the script directly.
grep -q 'mv "${DIY_PT1_SH}.tmp" "${DIY_PT1_SH}"' "${FIRST_SH}"
grep -q 'chmod +x "${DIY_PT1_SH}"' "${FIRST_SH}"

# User DIY exports may use normal shell quoting styles; extraction must not be
# limited to double-quoted values.
grep -q 'sed -nE' "${FIRST_SH}"
grep -q 'A-Za-z_\]\[A-Za-z0-9_' "${FIRST_SH}"

# Composite-action input names containing a hyphen must use bracket notation in
# GitHub expressions so Actionlint does not parse the hyphen as subtraction.
grep -q "inputs\['repo-branch'\]" "${BUILD_ENTRY}"
if grep -q 'inputs\.repo-branch' "${BUILD_ENTRY}"; then
  echo 'Found invalid dotted repo-branch expression' >&2
  exit 1
fi

# The validation assertion block intentionally uses negated grep and literal
# shell syntax; keep the explicit ShellCheck suppression in place.
grep -q 'shellcheck disable=SC2251,SC2016' "${VALIDATE}"

# Actionlint locations are not stable when validate.yml itself moves. The gate
# must normalize source coordinates while still preserving the diagnostic text.
normalize_actionlint() {
  sed -E \
    -e 's#^([^:]+):[0-9]+:[0-9]+: #\1: #' \
    -e 's#(shellcheck reported issue in this script [^:]+:[^:]+:)[0-9]+:[0-9]+:#\1#' \
    | sort -u
}
base='validate.yml:379:9: shellcheck reported issue in this script SC2251:info:32:3: This ! is not a condition'
current='validate.yml:382:9: shellcheck reported issue in this script SC2251:info:35:7: This ! is not a condition'
printf '%s\n' "$base" | normalize_actionlint > "${ROOT_DIR}/.tmp-actionlint-base"
printf '%s\n' "$current" | normalize_actionlint > "${ROOT_DIR}/.tmp-actionlint-current"
if ! cmp -s "${ROOT_DIR}/.tmp-actionlint-base" "${ROOT_DIR}/.tmp-actionlint-current"; then
  echo 'Actionlint coordinate normalization regression' >&2
  rm -f "${ROOT_DIR}/.tmp-actionlint-base" "${ROOT_DIR}/.tmp-actionlint-current"
  exit 1
fi
rm -f "${ROOT_DIR}/.tmp-actionlint-base" "${ROOT_DIR}/.tmp-actionlint-current"

echo 'Runtime DIY script permission / Actionlint regression: OK'
