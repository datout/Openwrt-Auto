#!/usr/bin/env bash
set -euo pipefail

: "${HOME_PATH:?HOME_PATH is required}"
: "${GITHUB_WORKSPACE:?GITHUB_WORKSPACE is required}"

OUT="${RUNNER_TEMP:-/tmp}/build-manifest.json"
CFG="${HOME_PATH}/.config"
SEED="${MYCONFIG_FILE:-}"

[[ -f "$CFG" ]] || { echo "::error::缺少 OpenWrt .config: $CFG"; exit 1; }

source_commit="$(git -C "$HOME_PATH" rev-parse HEAD 2>/dev/null || true)"
automation_commit="$(git -C "$GITHUB_WORKSPACE" rev-parse HEAD 2>/dev/null || true)"
source_remote="$(git -C "$HOME_PATH" config --get remote.origin.url 2>/dev/null || true)"
seed_sha256=''
config_sha256=''

[[ -f "$SEED" ]] && seed_sha256="$(sha256sum "$SEED" | awk '{print $1}')"
config_sha256="$(sha256sum "$CFG" | awk '{print $1}')"

target_board="$(sed -n 's/^CONFIG_TARGET_BOARD="\([^"]*\)"/\1/p' "$CFG" 2>/dev/null | head -n1)"
target_subtarget="$(sed -n 's/^CONFIG_TARGET_SUBTARGET="\([^"]*\)"/\1/p' "$CFG" 2>/dev/null | head -n1)"
kernel_patchver="$(sed -n 's/^CONFIG_KERNEL_PATCHVER="\([^"]*\)"/\1/p' "$CFG" 2>/dev/null | head -n1)"

# Most OpenWrt configs do not persist CONFIG_KERNEL_PATCHVER. Resolve it from
# the selected target Makefile instead of leaving the manifest empty.
if [[ -z "$kernel_patchver" && -n "$target_board" ]]; then
  target_makefile="${HOME_PATH}/target/linux/${target_board}/Makefile"
  if [[ -f "$target_makefile" ]]; then
    kernel_patchver="$(sed -n -E 's/^[[:space:]]*KERNEL_PATCHVER[[:space:]]*:?=[[:space:]]*([^[:space:]#]+).*/\1/p' "$target_makefile" | head -n1)"
  fi
fi
if [[ -z "$kernel_patchver" && -n "${LINUX_KERNEL:-}" ]]; then
  kernel_patchver="$(printf '%s' "$LINUX_KERNEL" | awk -F. 'NF >= 2 {print $1 "." $2}')"
fi

go_runtime=''
if command -v go >/dev/null 2>&1; then
  go_runtime="$(go version 2>/dev/null || true)"
else
  for go_bin in \
    "${HOME_PATH}/staging_dir/hostpkg/bin/go" \
    "${HOME_PATH}/staging_dir/host/bin/go"; do
    if [[ -x "$go_bin" ]]; then
      go_runtime="$($go_bin version 2>/dev/null || true)"
      [[ -n "$go_runtime" ]] && break
    fi
  done
fi

go_declared=''
go_makefile="${HOME_PATH}/feeds/packages/lang/golang/golang/Makefile"
if [[ -f "$go_makefile" ]]; then
  go_major_minor="$(sed -n -E 's/^[[:space:]]*GO_VERSION_MAJOR_MINOR[[:space:]]*:?=[[:space:]]*([^[:space:]#]+).*/\1/p' "$go_makefile" | head -n1)"
  go_patch="$(sed -n -E 's/^[[:space:]]*GO_VERSION_PATCH[[:space:]]*:?=[[:space:]]*([^[:space:]#]+).*/\1/p' "$go_makefile" | head -n1)"
  if [[ -n "$go_major_minor" && -n "$go_patch" ]]; then
    go_declared="${go_major_minor}.${go_patch}"
  elif [[ -n "$go_major_minor" ]]; then
    go_declared="$go_major_minor"
  else
    go_declared="$(sed -n -E 's/^[[:space:]]*PKG_VERSION[[:space:]]*:?=[[:space:]]*([0-9]+\.[0-9]+(\.[0-9]+)?).*/\1/p' "$go_makefile" | head -n1)"
  fi
fi

go_display="$go_runtime"
if [[ -z "$go_display" && -n "$go_declared" ]]; then
  go_display="OpenWrt golang ${go_declared} (declared)"
fi

cache_target="${target_board:-${TARGET_PROFILE:-${CONFIG_FILE:-unknown}}}"
cache_subtarget="${target_subtarget:-generic}"
CACHE_MIXKEY="${SOURCE_CODE:-source}-${REPO_BRANCH:-branch}-${cache_target}-${cache_subtarget}"
CACHE_MIXKEY="$(printf '%s' "$CACHE_MIXKEY" | tr '/ :@' '----' | tr -cd 'A-Za-z0-9._+-')"

export MANIFEST_OUT="$OUT"
export MANIFEST_SEED="$SEED"
export MANIFEST_SOURCE_COMMIT="$source_commit"
export MANIFEST_AUTOMATION_COMMIT="$automation_commit"
export MANIFEST_SOURCE_REMOTE="$source_remote"
export MANIFEST_SEED_SHA256="$seed_sha256"
export MANIFEST_CONFIG_SHA256="$config_sha256"
export MANIFEST_TARGET_BOARD="$target_board"
export MANIFEST_TARGET_SUBTARGET="$target_subtarget"
export MANIFEST_KERNEL_PATCHVER="$kernel_patchver"
export MANIFEST_GO_RUNTIME="$go_runtime"
export MANIFEST_GO_DECLARED="$go_declared"
export MANIFEST_GO_DISPLAY="$go_display"

python3 - <<'PY'
import datetime
import glob
import json
import os
import pathlib
import platform
import subprocess


def cmd(args, cwd=None):
    try:
        return subprocess.check_output(args, cwd=cwd, text=True, stderr=subprocess.DEVNULL).strip()
    except Exception:
        return ""


workspace = os.environ["GITHUB_WORKSPACE"]
home = os.environ["HOME_PATH"]
feeds = {}
for path in sorted(glob.glob(os.path.join(home, "feeds", "*"))):
    if not os.path.isdir(path):
        continue
    name = os.path.basename(path)
    if name.endswith(".tmp"):
        continue

    # rev-parse walks up to a parent repository. Ensure the feed itself is the
    # Git worktree, otherwise temporary directories incorrectly inherit the
    # OpenWrt source commit.
    top = cmd(["git", "rev-parse", "--show-toplevel"], cwd=path)
    if not top or os.path.realpath(top) != os.path.realpath(path):
        continue
    sha = cmd(["git", "rev-parse", "HEAD"], cwd=path)
    if sha:
        feeds[name] = sha

manifest = {
    "schema": 2,
    "generated_at_utc": datetime.datetime.now(datetime.timezone.utc).isoformat(),
    "automation": {
        "repository": os.environ.get("GITHUB_REPOSITORY", ""),
        "branch": os.environ.get("GIT_REFNAME", os.environ.get("GITHUB_REF_NAME", "")),
        "commit": os.environ.get("MANIFEST_AUTOMATION_COMMIT", ""),
        "version": pathlib.Path(os.path.join(workspace, "UPSTREAM_VERSION")).read_text(encoding="utf-8").strip() if pathlib.Path(os.path.join(workspace, "UPSTREAM_VERSION")).is_file() else "",
        "safe_branch_mode": os.environ.get("SAFE_BRANCH_MODE", ""),
        "run_id": os.environ.get("GITHUB_RUN_ID", ""),
        "run_number": os.environ.get("GITHUB_RUN_NUMBER", ""),
        "workflow": os.environ.get("GITHUB_WORKFLOW", ""),
    },
    "source": {
        "name": os.environ.get("FOLDER_NAME", ""),
        "source_code": os.environ.get("SOURCE_CODE", ""),
        "repository": os.environ.get("MANIFEST_SOURCE_REMOTE", ""),
        "branch": os.environ.get("REPO_BRANCH", ""),
        "commit": os.environ.get("MANIFEST_SOURCE_COMMIT", ""),
    },
    "target": {
        "config_file": os.environ.get("CONFIG_FILE", ""),
        "profile": os.environ.get("TARGET_PROFILE", ""),
        "board": os.environ.get("MANIFEST_TARGET_BOARD", ""),
        "subtarget": os.environ.get("MANIFEST_TARGET_SUBTARGET", ""),
        "kernel_patchver": os.environ.get("MANIFEST_KERNEL_PATCHVER", ""),
    },
    "configuration": {
        "seed_path": os.environ.get("MANIFEST_SEED", ""),
        "seed_sha256": os.environ.get("MANIFEST_SEED_SHA256", ""),
        "config_sha256": os.environ.get("MANIFEST_CONFIG_SHA256", ""),
    },
    "feeds": feeds,
    "toolchain": {
        "openwrt_go_declared": os.environ.get("MANIFEST_GO_DECLARED", ""),
        "go_runtime": os.environ.get("MANIFEST_GO_RUNTIME", ""),
    },
    "host": {
        "platform": platform.platform(),
        "python": platform.python_version(),
        "make": (lambda v: v.splitlines()[0] if v else "")(cmd(["make", "--version"])),
        "cmake": (lambda v: v.splitlines()[0] if v else "")(cmd(["cmake", "--version"])),
        "go": os.environ.get("MANIFEST_GO_DISPLAY", ""),
    },
}
out = pathlib.Path(os.environ["MANIFEST_OUT"])
out.write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
PY

manifest_sha256="$(sha256sum "$OUT" | awk '{print $1}')"

{
  echo "BUILD_MANIFEST=${OUT}"
  echo "BUILD_MANIFEST_SHA256=${manifest_sha256}"
  echo "SOURCE_COMMIT=${source_commit}"
  echo "SEED_SHA256=${seed_sha256}"
  echo "CACHE_MIXKEY=${CACHE_MIXKEY}"
} >> "${GITHUB_ENV}"
if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
  {
    echo "manifest=${OUT}"
    echo "manifest_sha256=${manifest_sha256}"
    echo "source_commit=${source_commit}"
    echo "seed_sha256=${seed_sha256}"
    echo "cache_mixkey=${CACHE_MIXKEY}"
  } >> "${GITHUB_OUTPUT}"
fi

echo "构建清单: ${OUT}"
echo "源码提交: ${source_commit:-unknown}"
echo "配置 SHA256: ${config_sha256:-unknown}"
echo "seed SHA256: ${seed_sha256:-unknown}"
echo "内核系列: ${kernel_patchver:-unknown}"
echo "Go: ${go_display:-unknown}"
echo "缓存标识: ${CACHE_MIXKEY}"
