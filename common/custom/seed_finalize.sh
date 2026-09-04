#!/bin/bash
# Persist the latest menuconfig state as a native Kconfig minimal defconfig.
# This prevents automatically selected package dependencies from becoming
# explicit selections in the next build's seed.

set -euo pipefail

HOME_PATH="${HOME_PATH:-$(pwd)}"
OUTPUT="${1:-${CONFIG_TXT:-}}"
RUNNER_TMP="${RUNNER_TEMP:-/tmp}"
SUMMARY="${RUNNER_TMP}/openwrt-seed-finalize-summary.txt"
FULL_CONFIG="${RUNNER_TMP}/openwrt-menuconfig-final.full.config"
VERIFY_CONFIG="${RUNNER_TMP}/openwrt-menuconfig-verify.full.config"
MINIMAL_SEED="${RUNNER_TMP}/openwrt-menuconfig-minimal.seed"
NORMAL_FINAL="${RUNNER_TMP}/openwrt-menuconfig-final.normalized"
NORMAL_VERIFY="${RUNNER_TMP}/openwrt-menuconfig-verify.normalized"

log() {
  printf '[seed-finalize] %s\n' "$*"
}

normalize_config() {
  grep -E '^(CONFIG_[A-Za-z0-9_.+/-]+=|# CONFIG_[A-Za-z0-9_.+/-]+ is not set$)' "$1" \
    | LC_ALL=C sort -u
}

[[ -n "${OUTPUT}" ]] || {
  log "错误：CONFIG_TXT/输出路径为空"
  exit 1
}

cd "${HOME_PATH}"

[[ -x ./scripts/config/conf ]] || {
  log "错误：未找到可执行的 scripts/config/conf"
  exit 1
}
[[ -f Config.in ]] || {
  log "错误：未找到 Config.in"
  exit 1
}
[[ -s .config ]] || {
  log "错误：当前 .config 不存在或为空"
  exit 1
}

# Ensure all Kconfig selections are resolved before making the persistent seed.
make defconfig >/dev/null 2>&1
cp -f .config "${FULL_CONFIG}"

# Kconfig's savedefconfig writes only values that must be explicitly persisted.
# Symbols forced by select/default dependencies are intentionally omitted.
./scripts/config/conf --savedefconfig="${MINIMAL_SEED}" Config.in >/dev/null
[[ -s "${MINIMAL_SEED}" ]] || {
  log "错误：savedefconfig 未生成有效 seed"
  cp -f "${FULL_CONFIG}" .config
  exit 1
}

# Safety check: expand the minimal seed again and require the effective config
# to be exactly the same as the user's final menuconfig state.
cp -f "${MINIMAL_SEED}" .config
make defconfig >/dev/null 2>&1
cp -f .config "${VERIFY_CONFIG}"

normalize_config "${FULL_CONFIG}" > "${NORMAL_FINAL}"
normalize_config "${VERIFY_CONFIG}" > "${NORMAL_VERIFY}"

if ! cmp -s "${NORMAL_FINAL}" "${NORMAL_VERIFY}"; then
  log "错误：minimal seed 重新展开后与本次 menuconfig 最终配置不一致，拒绝覆盖 seed"
  diff -u "${NORMAL_FINAL}" "${NORMAL_VERIFY}" | head -120 || true
  cp -f "${FULL_CONFIG}" .config
  exit 1
fi

# Restore the already validated full config for the subsequent build.
cp -f "${FULL_CONFIG}" .config
mkdir -p "$(dirname "${OUTPUT}")"
cp -f "${MINIMAL_SEED}" "${OUTPUT}"
sed -i '/^[[:space:]]*$/d' "${OUTPUT}"

# Keep a complete config artifact for troubleshooting.
if [[ -n "${COMPILE_PATH:-}" && -n "${CONFIG_FILE:-}" ]]; then
  mkdir -p "${COMPILE_PATH}/relevance"
  cp -f "${FULL_CONFIG}" "${COMPILE_PATH}/relevance/${CONFIG_FILE}.full.config"
fi

full_count=$(grep -cE '^CONFIG_PACKAGE_.+=[ym]$' "${FULL_CONFIG}" || true)
seed_count=$(grep -cE '^CONFIG_PACKAGE_.+=[ym]$' "${OUTPUT}" || true)
{
  echo "  Kconfig 原生 minimal seed：已生成并通过完整配置回放校验"
  echo "  完整配置中的 y/m 软件包：${full_count}"
  echo "  seed 中需要显式持久化的软件包：${seed_count}"
  echo "  自动依赖不会再作为独立选择写回下一次 seed"
} > "${SUMMARY}"

log "minimal seed 已生成并验证：${OUTPUT}"
log "自动依赖将由下一次 make defconfig 根据当前显式选择重新计算"
