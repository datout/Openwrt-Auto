#!/usr/bin/env bash
set -eo pipefail

cd "${GITHUB_WORKSPACE}"

write_env() {
  local name="$1"
  local value="${2:-}"
  printf -v "$name" '%s' "$value"
  export "$name"
  printf '%s=%s\n' "$name" "$value" >> "${GITHUB_ENV}"
}

write_unavailable_summary() {
  [[ -n "${GITHUB_STEP_SUMMARY:-}" ]] || return 0
  {
    echo "## ⚠️ 上游更新检查暂不可用（不阻断编译）"
    echo
    echo "> 无法获取 upstream 状态。本次编译仍继续使用 Fork 中的代码。"
  } >> "${GITHUB_STEP_SUMMARY}"
}

# Fork 构建时检查 upstream，但不阻断本次编译。
check_upstream() {
  if [[ "${GITHUB_REPOSITORY:-}" != "datout/Openwrt-Auto" ]]; then
    UPSTREAM_REPO="datout/Openwrt-Auto"
    UPSTREAM_BRANCH="main"
    UPSTREAM_URL="https://github.com/${UPSTREAM_REPO}.git"

    if git remote get-url upstream >/dev/null 2>&1; then
      git remote set-url upstream "${UPSTREAM_URL}" || {
        echo "::warning title=⚠️ 上游更新检查暂不可用::无法配置 upstream 远程仓库。本次编译仍会继续。"
        write_unavailable_summary
        return 0
      }
    else
      git remote add upstream "${UPSTREAM_URL}" || {
        echo "::warning title=⚠️ 上游更新检查暂不可用::无法添加 upstream 远程仓库。本次编译仍会继续。"
        write_unavailable_summary
        return 0
      }
    fi

    if ! git fetch upstream "${UPSTREAM_BRANCH}" --prune; then
      echo "::warning title=⚠️ 上游更新检查暂不可用::无法获取 ${UPSTREAM_REPO}/${UPSTREAM_BRANCH}。本次编译仍会继续。"
      write_unavailable_summary
      return 0
    fi

    LOCAL_COMMIT="$(git rev-parse HEAD)"
    UPSTREAM_COMMIT="$(git rev-parse "upstream/${UPSTREAM_BRANCH}")"
    AHEAD="$(git rev-list --count "${UPSTREAM_COMMIT}..${LOCAL_COMMIT}")"
    BEHIND="$(git rev-list --count "${LOCAL_COMMIT}..${UPSTREAM_COMMIT}")"

    if git merge-base --is-ancestor "${UPSTREAM_COMMIT}" "${LOCAL_COMMIT}"; then
      echo "::notice title=上游同步状态::当前提交已包含上游 main（ahead=${AHEAD}, behind=0）。"
    else
      COMMON_BASE="$(git merge-base "${LOCAL_COMMIT}" "${UPSTREAM_COMMIT}" 2>/dev/null || true)"
      if [[ -z "${COMMON_BASE}" ]]; then
        echo "::warning title=⚠️ 上游有更新（不阻断编译）::当前 Fork 与 ${UPSTREAM_REPO}/${UPSTREAM_BRANCH} 没有共同 Git 历史。本次编译仍会继续。"
        if [[ -n "${GITHUB_STEP_SUMMARY:-}" ]]; then
          {
            echo "## ⚠️ 上游有更新（不阻断编译）"
            echo
            echo "> **当前 Fork 与官方 upstream 没有共同 Git 历史。** 本次编译仍会继续。"
            echo
            echo "建议：如果你希望重新跟随官方框架，请执行 **Sync upstream**。"
          } >> "${GITHUB_STEP_SUMMARY}"
        fi
      else
        mapfile -t UPSTREAM_FILES < <(
          git diff --name-status --no-renames "${COMMON_BASE}" "${UPSTREAM_COMMIT}" | sed '/^$/d'
        )
        mapfile -t UPSTREAM_COMMITS < <(
          git log --format='%h %s' "${COMMON_BASE}..${UPSTREAM_COMMIT}" --max-count=50
        )

        echo "::warning title=⚠️ 上游有 ${BEHIND} 个新提交（不阻断编译）::当前 Fork 落后 upstream ${BEHIND} 个提交（ahead=${AHEAD}）。本次编译不会被阻止。"
        echo
        echo "============================================================"
        echo "⚠️  上游有新更新，但不会阻断本次编译"
        echo "============================================================"
        echo "当前 Fork：   ${LOCAL_COMMIT:0:12}"
        echo "官方 upstream：${UPSTREAM_COMMIT:0:12}"
        echo "领先提交：   ${AHEAD}"
        echo "落后提交：   ${BEHIND}"
        echo
        echo "📌 上游新增提交（最多 50 个）："
        if ((${#UPSTREAM_COMMITS[@]})); then
          printf '  %s\n' "${UPSTREAM_COMMITS[@]}"
        else
          echo "  （没有可显示的非 merge 提交）"
        fi
        echo
        echo "📂 上游变更文件（最多显示 100 个）："
        if ((${#UPSTREAM_FILES[@]})); then
          printf '  %s\n' "${UPSTREAM_FILES[@]:0:100}"
          if ((${#UPSTREAM_FILES[@]} > 100)); then
            echo "  ... 其余 $(( ${#UPSTREAM_FILES[@]} - 100 )) 个文件未展开"
          fi
        else
          echo "  （没有文件变更）"
        fi
        echo
        echo "👉 当前编译继续使用你 Fork 中的代码。"
        echo "👉 如需获得官方最新框架修复，请执行 Sync upstream。"
        echo "============================================================"

        if [[ -n "${GITHUB_STEP_SUMMARY:-}" ]]; then
          {
            echo "## ⚠️ 上游有 ${BEHIND} 个新提交（不阻断编译）"
            echo
            echo "> **不会阻止本次编译。** 当前编译继续使用 Fork 中的代码。"
            echo
            echo "| 项目 | 当前状态 |"
            echo "| --- | --- |"
            echo "| Fork | \`${LOCAL_COMMIT:0:12}\` |"
            echo "| upstream | \`${UPSTREAM_COMMIT:0:12}\` |"
            echo "| 领先 | ${AHEAD} 个提交 |"
            echo "| 落后 | **${BEHIND}** 个提交 |"
            echo
            echo "### 📌 上游新增提交"
            if ((${#UPSTREAM_COMMITS[@]})); then
              echo '```text'
              printf '%s\n' "${UPSTREAM_COMMITS[@]}"
              echo '```'
            else
              echo "（没有可显示的非 merge 提交）"
            fi
            echo
            echo "### 📂 上游变更文件"
            if ((${#UPSTREAM_FILES[@]})); then
              echo '```text'
              printf '%s\n' "${UPSTREAM_FILES[@]:0:100}"
              if ((${#UPSTREAM_FILES[@]} > 100)); then
                echo "... 其余 $(( ${#UPSTREAM_FILES[@]} - 100 )) 个文件未展开"
              fi
              echo '```'
            else
              echo "（没有文件变更）"
            fi
            echo
            echo "### 下一步"
            echo "如果希望获得官方最新框架修复，请执行 **Sync upstream**。"
          } >> "${GITHUB_STEP_SUMMARY}"
        fi
      fi
    fi
  fi

}

check_upstream

# 验证仓库密钥。
if [[ -z "${REPO_TOKEN:-}" ]]; then
  echo -e "\033[31m 您没有设置仓库密匙，请按教程设置好密匙再来 \033[0m\n"
  echo -e "\033[32m REPO_TOKEN密匙制作教程：https://git.io/jm.md \033[0m\n"
  exit 1
fi
rm -rf mishi
git clone --depth=1 -b "${GITHUB_REF_NAME}" "https://user:${REPO_TOKEN}@github.com/${GITHUB_REPOSITORY}.git" mishi
if [[ -z "$(ls -1 mishi)" ]]; then
  echo -e "\033[31m 您的密匙错误或已过期，或制作的时候勾选不正确，请按教程设置好密匙再来 \033[0m\n"
  echo -e "\033[32m REPO_TOKEN密匙制作教程：https://git.io/jm.md \033[0m\n"
  exit 1
fi
rm -rf mishi
git config --global user.email "41898282+github-actions[bot]@users.noreply.github.com"
git config --global user.name "github-actions[bot]"

COMPILE_PATH="${GITHUB_WORKSPACE}/build/${FOLDER_NAME}"

load_settings_file() {
  local settings_file="$1"
  if [[ ! -f "${settings_file}" ]]; then
    echo "::error title=settings.ini 缺失::${settings_file}"
    return 1
  fi
  if ! bash -n "${settings_file}"; then
    echo "::error title=settings.ini 语法错误::${settings_file}"
    return 1
  fi
  # shellcheck disable=SC1090
  source "${settings_file}"
}

if [[ "${GITHUB_EVENT_NAME}" == "push" ]]; then
  if [[ -f "${COMPILE_PATH}/relevance/settings.ini" ]]; then
    load_settings_file "${COMPILE_PATH}/relevance/settings.ini"
    write_env ERRUN_NUMBER "${ERRUN_NUMBER:-}"
  fi
elif [[ "${GITHUB_EVENT_NAME}" == "workflow_dispatch" ]]; then
  if [[ -n "${BUILD_CONTEXT:-}" ]]; then
    SSH_ACTION="false"
    echo "检测到两阶段 BUILD_CONTEXT，使用第一阶段传递的构建参数。"
  else
    if [[ -f "${COMPILE_PATH}/settings.ini" ]]; then
      load_settings_file "${COMPILE_PATH}/settings.ini"
    else
      echo "::error title=settings.ini 缺失::${COMPILE_PATH}/settings.ini"
      exit 1
    fi
    REPO_BRANCH="${BUILD_REPO_BRANCH:-${REPO_BRANCH:-}}"
    CONFIG_FILE="${BUILD_CONFIG_FILE:-${CONFIG_FILE:-}}"
    INFORMATION_NOTICE="${BUILD_INFORMATION_NOTICE:-${INFORMATION_NOTICE:-}}"
    KEEP_WORKFLOWS="${BUILD_KEEP_WORKFLOWS:-${KEEP_WORKFLOWS:-}}"
    KEEP_RELEASES="${BUILD_KEEP_RELEASES:-${KEEP_RELEASES:-}}"
    SSH_ACTION="${BUILD_SSH_ACTION:-${SSH_ACTION:-}}"
    UPLOAD_FIRMWARE="${BUILD_UPLOAD_FIRMWARE:-${UPLOAD_FIRMWARE:-}}"
    UPLOAD_RELEASE="${BUILD_UPLOAD_RELEASE:-${UPLOAD_RELEASE:-}}"
    CACHEWRTBUILD_SWITCH="${BUILD_CACHEWRTBUILD_SWITCH:-${CACHEWRTBUILD_SWITCH:-}}"
    UPDATE_FIRMWARE_ONLINE="${BUILD_UPDATE_FIRMWARE_ONLINE:-${UPDATE_FIRMWARE_ONLINE:-}}"
  fi
else
  if [[ -f "${COMPILE_PATH}/settings.ini" ]]; then
    load_settings_file "${COMPILE_PATH}/settings.ini"
  fi
fi

write_env SOURCE_CODE "${SOURCE_CODE:-}"
write_env REPO_BRANCH "${REPO_BRANCH:-}"
write_env INFORMATION_NOTICE "${INFORMATION_NOTICE:-}"
write_env KEEP_WORKFLOWS "${KEEP_WORKFLOWS:-}"
write_env KEEP_RELEASES "${KEEP_RELEASES:-}"
write_env SSH_ACTION "${SSH_ACTION:-}"
write_env UPLOAD_FIRMWARE "${UPLOAD_FIRMWARE:-}"
write_env UPLOAD_RELEASE "${UPLOAD_RELEASE:-}"
write_env CACHEWRTBUILD_SWITCH "${CACHEWRTBUILD_SWITCH:-}"
write_env UPDATE_FIRMWARE_ONLINE "${UPDATE_FIRMWARE_ONLINE:-}"
write_env GITHUB_LINK "https://github.com/${GITHUB_REPOSITORY}"
write_env GIT_ACTOR "${GITHUB_ACTOR}"
write_env WAREHOUSE_MAN "${GIT_REPOSITORY##*/}"
write_env RUN_NUMBER "${GITHUB_RUN_NUMBER}"
write_env GIT_REFNAME "${GITHUB_REF_NAME}"
write_env COMPILATION_INFORMATION "${COMPILATION_INFORMATION:-}"
write_env CONFIG_FILE "${CONFIG_FILE:-}"

HOME_PATH="${GITHUB_WORKSPACE}/openwrt"
write_env HOME_PATH "${HOME_PATH}"
write_env COMPILE_PATH "${COMPILE_PATH}"
write_env BUILD_DIY "${COMPILE_PATH}/diy"
write_env BUILD_FILES "${COMPILE_PATH}/files"
write_env BUILD_PATCHES "${COMPILE_PATH}/patches"
write_env BUILD_PARTSH "${COMPILE_PATH}/diy-part.sh"
write_env BUILD_SETTINGS "${COMPILE_PATH}/settings.ini"
write_env MYCONFIG_FILE "${COMPILE_PATH}/seed/${CONFIG_FILE}"

# 非 main 分支安全模式。
if [[ "${GITHUB_REF_NAME}" != "main" ]]; then
  write_env SAFE_BRANCH_MODE true
  write_env UPLOAD_RELEASE false
  write_env UPDATE_FIRMWARE_ONLINE false
  echo "::notice title=测试分支安全模式::当前分支 ${GITHUB_REF_NAME}：已强制关闭 Release 发布和在线更新云端上传，不影响 main。"
else
  write_env SAFE_BRANCH_MODE false
fi

# 标准化缓存与通知参数。
case "${CACHEWRTBUILD_SWITCH:-}" in
  *false*) write_env CACHEWRTBUILD_SWITCH false ;;
  *) write_env CACHEWRTBUILD_SWITCH true ;;
esac
case "${INFORMATION_NOTICE:-}" in
  *tg*|*TG*|*telegram*|*Telegram*) write_env INFORMATION_NOTICE TG ;;
  *push*|*PUSH*|*pushplus*|*Pushplus*) write_env INFORMATION_NOTICE PUSH ;;
  *) write_env INFORMATION_NOTICE false ;;
esac

# 初始化公共脚本。
LINSHI_COMMON="${GITHUB_WORKSPACE}/common"
write_env LINSHI_COMMON "${LINSHI_COMMON}"
write_env COMMON_SH "${LINSHI_COMMON}/common.sh"
write_env UPGRADE_SH "${LINSHI_COMMON}/upgrade.sh"
CONFIG_TXT="${LINSHI_COMMON}/config.txt"
write_env CONFIG_TXT "${CONFIG_TXT}"

if [[ -f "${LINSHI_COMMON}/custom/first.sh" ]] && grep -qE "bash" "${LINSHI_COMMON}/custom/first.sh"; then
  chmod -R +x "${LINSHI_COMMON}"
  if ! bash -n "${LINSHI_COMMON}/custom/first.sh"; then
    echo "::error title=common/custom/first.sh 语法错误::${LINSHI_COMMON}/custom/first.sh"
    exit 1
  fi
  set -E
  trap 'first_rc=$?; echo "::error title=初始化公共脚本失败::${BASH_SOURCE[0]}:${BASH_LINENO[0]} 返回状态 ${first_rc}"' ERR
  source "${LINSHI_COMMON}/custom/first.sh"
  trap - ERR
  set +E
else
  echo "缺少 common/custom/first.sh，请检查仓库文件"
  exit 1
fi

if [[ -f "${COMMON_SH}" ]] && grep -qE "bash" "${COMMON_SH}"; then
  chmod +x "${COMMON_SH}"
  # Keep the shared runtime in this same shell so variables exported by
  # common.sh (and written to GITHUB_ENV) are immediately available to the
  # following source-preparation functions.
  source "${COMMON_SH}"
  Diy_menu6
else
  echo "公共脚本初始化失败，请检查仓库文件"
  exit 1
fi

# 部署配置环境。
echo "::group::部署配置环境"
export DEBIAN_FRONTEND=noninteractive
export NEEDRESTART_MODE=a
export APT_LISTCHANGES_FRONTEND=none
timeout 20m bash -s <<'SETUP_ENV'
set -euo pipefail
sudo -E apt-get -qq -o Acquire::Retries=3 update
sudo -E apt-get -qq -o Acquire::Retries=3 install -y \
  gawk git gettext libssl-dev xsltproc zip wget curl grep \
  python2.7 python3 python3-pip libpython3-dev jq
sudo ln -snf "/usr/share/zoneinfo/${TZ}" /etc/localtime
echo "${TZ}" | sudo tee /etc/timezone >/dev/null
WORK_ROOT="/${DIY_WORK:?DIY_WORK 未设置}"
if [[ "${WORK_ROOT}" == "/" || "${WORK_ROOT}" == "//" ]]; then
  echo "::error::拒绝把仓库工作目录设置为系统根目录"
  exit 1
fi
sudo install -d -m 0755 -o "${USER}" -g "$(id -gn)" "${WORK_ROOT}"
echo "配置工作目录已准备：${WORK_ROOT}"
SETUP_ENV
echo "::endgroup::"

# 下载源码。
echo "::group::下载 ${FOLDER_NAME}-${REPO_BRANCH} 源码"
cd "/${DIY_WORK}"
git clone -q -b "${REPO_BRANCH}" --single-branch "${REPO_URL}" openwrt
ln -sfn "/${DIY_WORK}/openwrt" "${GITHUB_WORKSPACE}/openwrt"
Diy_feedsconf
write_env SHANG_CHUAN true
echo "::endgroup::"

# 公告。原 composite 的 if: env.SendMessage != 'true' 语义在脚本中保持。
echo "::group::公告"
if [[ "${SendMessage:-}" != "true" ]]; then
  cd "${HOME_PATH}"
  echo -e "\n\033[0;33m第一次用我仓库的，请不要拉取任何插件，先SSH进入固件配置那里看过我脚本实在是没有你要的插件才再拉取\033[0m"
  echo -e "\n\033[0;33m拉取插件应该单独拉取某一个你需要的插件，别一下子就拉取别人一个插件包，这样容易增加编译失败概率\033[0m"
  if [[ "${UPDATE_FIRMWARE_ONLINE}" == "true" ]]; then
    echo -e "\n\033[0;31mSSH连接固件输入命令'openwrt'可进行修改后台IP、清空密码、还原出厂设置和在线更新固件操作\033[0m"
  else
    echo -e "\n\033[0;31mSSH连接固件输入命令'openwrt'可进行修改后台IP，清空密码和还原出厂设置操作\033[0m"
  fi
  echo
fi
echo "::endgroup::"

echo "::group::下载源码后进行源码微调和增加插件源"
cd "${HOME_PATH}"
Diy_menu
echo "::endgroup::"

echo "::group::运行自定义文件"
Diy_menu2
echo "::endgroup::"

echo "::group::检查并设置默认主题"
Diy_menu3
echo "::endgroup::"

echo "统一源码构建入口已完成"
exit 0
