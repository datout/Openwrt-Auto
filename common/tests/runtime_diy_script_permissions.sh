#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
FIRST_SH="${ROOT_DIR}/common/custom/first.sh"
BUILD_ENTRY="${ROOT_DIR}/.github/actions/build-entry/action.yml"
MISHI="${ROOT_DIR}/.github/actions/mishi/action.yml"
CHECKOUT="${ROOT_DIR}/common/lib/checkout.sh"
SYNC_UPSTREAM="${ROOT_DIR}/.github/workflows/sync-upstream.yml"

# Diy_four replaces diy-part.sh with a filtered tmp file. The replacement must
# restore the executable bit before Diy_partsh executes the script directly.
grep -q 'chmod +x "${DIY_PT1_SH}"' "${FIRST_SH}"
grep -q 'mv "${DIY_PT1_SH}.tmp" "${DIY_PT1_SH}"' "${FIRST_SH}"

# diy-part.sh export extraction must accept normal Bash assignment styles without
# relying on grep's exit status or requiring double quotes.
grep -q 'awk.*export.*A-Za-z_.*A-Za-z0-9' "${FIRST_SH}"
! grep -q 'grep -E.*export.*=.*"' "${FIRST_SH}"
grep -q 'bash -n "${DIY_PT2_SH}"' "${FIRST_SH}"

# Early rewrite-rule extraction must also be independent of grep returning 1.
grep -q 'rewrite_rules="${DIY_PT2_SH}.rewrite"' "${FIRST_SH}"
grep -q 'awk.*xargs.*sed.*-i' "${FIRST_SH}"

# Composite-action input names containing a hyphen must use bracket notation in
# GitHub expressions so Actionlint does not parse the hyphen as subtraction.
grep -q "inputs\['repo-branch'\]" "${BUILD_ENTRY}"
if grep -q 'inputs\.repo-branch' "${BUILD_ENTRY}"; then
  echo 'Found invalid dotted repo-branch expression' >&2
  exit 1
fi

# settings.ini must use one syntax-checked loader, not grep/awk field slicing.
grep -q 'load_settings_file()' "${MISHI}"
grep -q 'bash -n "${settings_file}"' "${MISHI}"
! grep -q "awk -F'\"'" "${MISHI}"

# Upstream sync preserves the actual user customization layer and does not
# restore generated relevance state.
for path in 'build/*/diy-part.sh' 'build/*/settings.ini' 'build/*/seed' 'build/*/diy' 'build/*/files' 'build/*/patches'; do
  grep -Fq "${path}" "${SYNC_UPSTREAM}"
done
if grep -Fq 'build/*/relevance' "${SYNC_UPSTREAM}"; then
  echo 'Sync upstream must not restore generated relevance files' >&2
  exit 1
fi

grep -q 'cp -Rf "${BUILD_DIY}/." "${HOME_PATH}/"' "${CHECKOUT}"

# Actionlint locations are not stable when validate.yml itself moves. The gate
# must normalize source coordinates while preserving the diagnostic text.
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

# Representative settings.ini forms: single quotes, double quotes, and bare values.
tmp_settings="$(mktemp)"
tmp_diy="$(mktemp)"
trap 'rm -f "${tmp_settings}" "${tmp_diy}" "${tmp_diy}.exports"' EXIT
cat > "${tmp_settings}" <<'SETTINGS'
SOURCE_CODE='COOLSNOWWOLF'
COMPILATION_INFORMATION=true
INFORMATION_NOTICE="false"
SETTINGS
bash -n "${tmp_settings}"
# shellcheck disable=SC1090
source "${tmp_settings}"
[[ "${SOURCE_CODE}" == 'COOLSNOWWOLF' ]]
[[ "${COMPILATION_INFORMATION}" == 'true' ]]

cat > "${tmp_diy}" <<'DIY'
export DOUBLE_QUOTED="one"
export SINGLE_QUOTED='two words'
export UNQUOTED=three
DIY
awk '/^[[:space:]]*export[[:space:]]+[A-Za-z_][A-Za-z0-9_]*([[:space:]]|=)/ { print }' "${tmp_diy}" > "${tmp_diy}.exports"
bash -n "${tmp_diy}.exports"
grep -q "export SINGLE_QUOTED='two words'" "${tmp_diy}.exports"

echo 'Runtime user customization / Actionlint regression: OK'
