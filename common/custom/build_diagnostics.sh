#!/usr/bin/env bash
set -uo pipefail

: "${HOME_PATH:?HOME_PATH is required}"
: "${GITHUB_WORKSPACE:?GITHUB_WORKSPACE is required}"

BUILD_LOG="${BUILD_LOG:-${RUNNER_TEMP:-/tmp}/openwrt-build.log}"
OUT="${RUNNER_TEMP:-/tmp}/openwrt-diagnostics"
rm -rf "$OUT"
mkdir -p "$OUT/failed-targets"

copy_if_file() {
  local src="$1"
  local dst="$2"
  [[ -f "$src" ]] && cp -f "$src" "$dst"
}

copy_if_file "$BUILD_LOG" "$OUT/openwrt-build.log"
copy_if_file "$HOME_PATH/.config" "$OUT/.config"
copy_if_file "${MYCONFIG_FILE:-}" "$OUT/seed"
copy_if_file "${COMPILE_PATH:-}/relevance/${CONFIG_FILE:-}.full.config" "$OUT/full.config"
copy_if_file "$HOME_PATH/feeds.conf.default" "$OUT/feeds.conf.default"
copy_if_file "$HOME_PATH/tmp/.packageinfo" "$OUT/packageinfo.txt"
copy_if_file "${BUILD_MANIFEST:-}" "$OUT/build-manifest.json"

{
  echo "repository=${GITHUB_REPOSITORY:-}"
  echo "branch=${GIT_REFNAME:-${GITHUB_REF_NAME:-}}"
  echo "automation_commit=$(git -C "$GITHUB_WORKSPACE" rev-parse HEAD 2>/dev/null || true)"
  echo "source=${FOLDER_NAME:-}/${SOURCE_CODE:-}"
  echo "source_branch=${REPO_BRANCH:-}"
  echo "source_commit=$(git -C "$HOME_PATH" rev-parse HEAD 2>/dev/null || true)"
  echo "config_file=${CONFIG_FILE:-}"
  echo "target_profile=${TARGET_PROFILE:-}"
  echo "cache_mixkey=${CACHE_MIXKEY:-}"
  echo "run_id=${GITHUB_RUN_ID:-}"
  echo "run_number=${GITHUB_RUN_NUMBER:-}"
} > "$OUT/build-context.txt"

{
  uname -a || true
  echo
  df -h || true
  echo
  make --version | head -n1 || true
  cmake --version | head -n1 || true
  go version || true
  gcc --version | head -n1 || true
  python3 --version || true
} > "$OUT/environment.txt" 2>&1

mapfile -t failed < <(
  if [[ -s "$BUILD_LOG" ]]; then
    sed -nE 's/.*ERROR:[[:space:]]+(package\/[^[:space:]]+)([[:space:]]+\[host\])?[[:space:]]+failed to build\..*/\1|\2/p' "$BUILD_LOG" \
      | awk '!seen[$0]++'
  fi
)

cd "$HOME_PATH" || exit 0
if (( ${#failed[@]} == 0 )); then
  echo '未能从主日志识别具体 package，执行一次 world -j1 V=sc。'
  make -j1 V=sc 2>&1 | tee "$OUT/failed-targets/world-j1-Vsc.log" || true
else
  for item in "${failed[@]}"; do
    pkg="${item%%|*}"
    kind="${item#*|}"
    if [[ "$kind" == *'[host]'* ]]; then
      target="${pkg}/host/compile"
    else
      target="${pkg}/compile"
    fi
    safe="$(printf '%s' "$target" | tr '/ :' '---' | tr -cd 'A-Za-z0-9._+-')"
    echo "真实失败目标: ${target}"
    make "$target" -j1 V=sc 2>&1 | tee "$OUT/failed-targets/${safe}.log" || true
  done
fi

DIAGNOSTICS_NAME="build-diagnostics-${FOLDER_NAME:-OpenWrt}-${CONFIG_FILE:-target}-${GITHUB_RUN_NUMBER:-0}"
{
  echo "DIAGNOSTICS_DIR=${OUT}"
  echo "DIAGNOSTICS_NAME=${DIAGNOSTICS_NAME}"
} >> "${GITHUB_ENV}"

if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
  {
    echo "dir=${OUT}"
    echo "name=${DIAGNOSTICS_NAME}"
  } >> "${GITHUB_OUTPUT}"
fi

echo "诊断目录已生成: ${OUT}"
find "$OUT" -maxdepth 2 -type f -printf '  %P\n' | sort
exit 0
