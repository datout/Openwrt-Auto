#!/bin/bash
# Keep the persistent seed aligned with the user's latest SSH menuconfig choices.
# Usage:
#   seed_refresh.sh snapshot  - expand the current seed and save pre-menuconfig .config
#   seed_refresh.sh cleanup   - remove dependency leftovers of packages disabled in this session

set -euo pipefail

MODE="${1:-}"
HOME_PATH="${HOME_PATH:-$(pwd)}"
RUNNER_TMP="${RUNNER_TEMP:-/tmp}"
BEFORE_CONFIG="${MENUCONFIG_BEFORE_CONFIG:-${RUNNER_TMP}/openwrt-menuconfig-before.config}"
DISABLED_LIST="${RUNNER_TMP}/openwrt-menuconfig-disabled-packages.txt"
ENABLED_LIST="${RUNNER_TMP}/openwrt-menuconfig-enabled-packages.txt"
CLEANED_LIST="${RUNNER_TMP}/openwrt-seed-cleaned-packages.txt"
PACKAGEINFO="${HOME_PATH}/tmp/.packageinfo"

cd "${HOME_PATH}"

log() {
  printf '[seed-refresh] %s\n' "$*"
}

selected_packages() {
  local cfg="$1"
  sed -nE 's/^CONFIG_PACKAGE_(.+)=[ym]$/\1/p' "${cfg}" | sort -u
}

disable_symbol() {
  local symbol="$1"
  local key="CONFIG_${symbol}"
  local tmp
  tmp="$(mktemp)"
  awk -v key="${key}" '
    $0 == "# " key " is not set" { next }
    index($0, key "=") == 1 { next }
    { print }
    END { print "# " key " is not set" }
  ' "${HOME_PATH}/.config" > "${tmp}"
  mv -f "${tmp}" "${HOME_PATH}/.config"
}
disable_package_suboptions() {
  local pkg="$1"
  local prefix="CONFIG_PACKAGE_${pkg}_"
  mapfile -t symbols < <(
    awk -v prefix="${prefix}" '
      index($0, prefix) == 1 {
        line=$0
        sub(/=.*/, "", line)
        sub(/^CONFIG_/, "", line)
        print line
      }
    ' "${HOME_PATH}/.config" | sort -u
  )
  local symbol
  for symbol in "${symbols[@]}"; do
    if [[ -n "${symbol}" ]]; then
      disable_symbol "${symbol}"
    fi
  done
}

package_dependency_closure() {
  local root="$1"
  local info="$2"
  perl - "${root}" "${info}" <<'PERL'
use strict;
use warnings;

my ($root, $file) = @ARGV;
open my $fh, '<', $file or exit 0;

my %deps;
my $pkg = '';
while (my $line = <$fh>) {
    chomp $line;
    if ($line =~ /^Package:\s*(\S+)/) {
        $pkg = $1;
        next;
    }
    next unless $pkg ne '' && $line =~ /^Depends:\s*(.*)$/;
    my $raw = $1;
    for my $dep (split /\s+/, $raw) {
        next if $dep eq '' || $dep =~ /^\@/;
        $dep =~ s/^\+//;
        $dep =~ s/^.*://;       # +COND:package -> package
        $dep =~ s/^!+//;
        $dep =~ s/\(.*$//;      # tolerate version suffixes
        $dep =~ s/[<>=].*$//;
        next unless $dep =~ /^[A-Za-z0-9_.+-]+$/;
        push @{ $deps{$pkg} }, $dep;
    }
}
close $fh;

my %seen = ($root => 1);
my @queue = ($root);
while (@queue) {
    my $cur = shift @queue;
    for my $dep (@{ $deps{$cur} || [] }) {
        next if $seen{$dep}++;
        print "$dep\n";
        push @queue, $dep;
    }
}
PERL
}

ensure_packageinfo() {
  if [[ ! -s "${PACKAGEINFO}" ]]; then
    make -s prepare-tmpinfo OPENWRT_BUILD= >/dev/null 2>&1 || true
  fi
}

snapshot() {
  [[ -f "${HOME_PATH}/.config" ]] || {
    log "未找到 .config，无法记录 menuconfig 初始状态"
    exit 1
  }

  # Expand the current seed before taking the snapshot. The repository seed is
  # migrated once with this release; future removals are handled generically by
  # comparing this snapshot with the final menuconfig state.
  make defconfig >/dev/null 2>&1
  cp -f "${HOME_PATH}/.config" "${BEFORE_CONFIG}"
  : > "${CLEANED_LIST}"
  log "已记录 menuconfig 前配置：${BEFORE_CONFIG}"
}

cleanup() {
  [[ -s "${BEFORE_CONFIG}" ]] || {
    log "未找到 menuconfig 前配置快照，跳过自动清理"
    exit 0
  }
  [[ -s "${HOME_PATH}/.config" ]] || {
    log "当前 .config 不存在或为空，跳过自动清理"
    exit 0
  }

  local before_pkgs after_pkgs
  before_pkgs="$(mktemp)"
  after_pkgs="$(mktemp)"
  trap 'rm -f "${before_pkgs:-}" "${after_pkgs:-}"' EXIT

  selected_packages "${BEFORE_CONFIG}" > "${before_pkgs}"
  selected_packages "${HOME_PATH}/.config" > "${after_pkgs}"
  comm -23 "${before_pkgs}" "${after_pkgs}" > "${DISABLED_LIST}"
  comm -13 "${before_pkgs}" "${after_pkgs}" > "${ENABLED_LIST}"

  if [[ ! -s "${DISABLED_LIST}" ]]; then
    log "本次 menuconfig 没有取消软件包，无需清理历史依赖"
    exit 0
  fi

  log "本次取消的软件包："
  sed 's/^/  - /' "${DISABLED_LIST}"

  ensure_packageinfo
  if [[ ! -s "${PACKAGEINFO}" ]]; then
    log "警告：tmp/.packageinfo 不存在，仅清理已取消包自身及其子选项"
  fi

  declare -A candidates=()
  local pkg dep
  while IFS= read -r pkg; do
    [[ -n "${pkg}" ]] || continue
    disable_symbol "PACKAGE_${pkg}"
    disable_package_suboptions "${pkg}"

    if [[ -s "${PACKAGEINFO}" ]]; then
      while IFS= read -r dep; do
        [[ -n "${dep}" ]] || continue
        candidates["${dep}"]=1
      done < <(package_dependency_closure "${pkg}" "${PACKAGEINFO}")
    fi
  done < "${DISABLED_LIST}"

  # Drop old dependency selections. Packages explicitly enabled during this
  # same menuconfig session are protected. Shared/default dependencies are
  # restored automatically by make defconfig below.
  for dep in "${!candidates[@]}"; do
    grep -Fxq "${dep}" "${ENABLED_LIST}" && continue
    if grep -qE "^CONFIG_PACKAGE_${dep}=[ym]$" "${HOME_PATH}/.config"; then
      disable_symbol "PACKAGE_${dep}"
      printf '%s\n' "${dep}" >> "${CLEANED_LIST}"
    fi
  done

  make defconfig >/dev/null 2>&1

  if [[ -s "${CLEANED_LIST}" ]]; then
    sort -u -o "${CLEANED_LIST}" "${CLEANED_LIST}"
    log "已清理旧依赖，并重新交给 Kconfig 解析共享依赖："
    while IFS= read -r dep; do
      if grep -qE "^CONFIG_PACKAGE_${dep}=[ym]$" "${HOME_PATH}/.config"; then
        printf '  = %s（仍被其他当前选择需要，已自动恢复）\n' "${dep}"
      else
        printf '  - %s\n' "${dep}"
      fi
    done < "${CLEANED_LIST}"
  else
    log "没有发现需要删除的历史依赖"
  fi

  log "seed 将以本次 menuconfig 的最终状态重新生成"
}

case "${MODE}" in
  snapshot) snapshot ;;
  cleanup) cleanup ;;
  *)
    echo "Usage: $0 {snapshot|cleanup}" >&2
    exit 2
    ;;
esac
