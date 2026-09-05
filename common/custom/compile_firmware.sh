#!/usr/bin/env bash
set -uo pipefail

BUILD_LOG="${BUILD_LOG:-${RUNNER_TEMP:-/tmp}/openwrt-build.log}"
mkdir -p "$(dirname "$BUILD_LOG")"
: > "$BUILD_LOG"

log() {
  printf '[compile] %s\n' "$*"
}

run_make() {
  make "$@" 2>&1 | tee -a "$BUILD_LOG"
  return "${PIPESTATUS[0]}"
}

failed_packages() {
  sed -nE 's/.*ERROR:[[:space:]]+(package\/[^[:space:]]+)([[:space:]]+\[host\])?[[:space:]]+failed to build\..*/\1|\2/p' "$BUILD_LOG" \
    | awk '!seen[$0]++'
}

xray_failed() {
  failed_packages | grep -Eq '^package/(feeds/[^/]+/)?xray-core\|'
}

patch_gvisor_go126() {
  local patched=0
  local f

  shopt -s nullglob
  for f in dl/go-mod-cache/gvisor.dev/gvisor@*/pkg/sync/runtime_constants_go125.go; do
    [[ -f "$f" ]] || continue
    sed -i 's/\r$//' "$f"

    if grep -Eq '^//go:build[[:space:]]+go1\.25[[:space:]]*$' "$f"; then
      sed -i -E 's#^//go:build[[:space:]]+go1\.25[[:space:]]*$#//go:build go1.25 \&\& !go1.26#' "$f"
      sed -i -E 's#^//[[:space:]]+\+build[[:space:]]+go1\.25[[:space:]]*$#// +build go1.25,!go1.26#' "$f"
      patched=$((patched + 1))
      log "已修正 gVisor Go 1.26 build tag: $f"
    fi
  done
  shopt -u nullglob

  (( patched > 0 ))
}

retry_xray_if_needed() {
  if ! xray_failed; then
    return 1
  fi

  if ! grep -Eq 'gvisor\.dev/gvisor|runtime_constants_go125\.go|pkg/sync' "$BUILD_LOG"; then
    log 'xray-core 失败，但日志没有匹配到 gVisor/Go 1.26 特征，不应用专用补丁。'
    return 1
  fi

  if ! patch_gvisor_go126; then
    log '检测到 xray-core/gVisor，但没有可修正的 go1.25 build tag。'
    return 1
  fi

  local xray_target=''
  local item pkg
  while IFS= read -r item; do
    pkg="${item%%|*}"
    if [[ "$pkg" == */xray-core ]]; then
      xray_target="$pkg"
      break
    fi
  done < <(failed_packages)

  [[ -n "$xray_target" ]] || return 1

  log "仅重建真实失败的 xray-core: ${xray_target}"
  make "${xray_target}/clean" V=s 2>&1 | tee -a "$BUILD_LOG" || true
  if ! run_make "${xray_target}/compile" -j1 V=s; then
    log 'xray-core 专用重建仍失败。'
    return 1
  fi

  log 'xray-core 专用修复成功，继续并行完成剩余构建。'
  run_make -j"$(nproc)"
}

log "开始并行编译：$(nproc) threads"
if run_make -j"$(nproc)"; then
  log '并行编译成功。'
  exit 0
fi

log '并行编译失败，先使用单线程 V=s 获取真实失败包。'
if run_make -j1 V=s; then
  log '单线程重试成功。'
  exit 0
fi

mapfile -t failures < <(failed_packages)
if (( ${#failures[@]} > 0 )); then
  log '识别到失败目标：'
  printf '  - %s\n' "${failures[@]}"
else
  log '单线程日志仍未识别到具体 package 失败目标。'
fi

if retry_xray_if_needed; then
  exit 0
fi

log '没有匹配到可安全自动修复的已知错误，保留原始失败并进入诊断阶段。'
exit 1
