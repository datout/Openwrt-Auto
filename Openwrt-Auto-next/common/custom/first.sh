#!/bin/bash
# Build scripts are repo-local (no external build-actions dependency)
# common module (repo-local)
# matrix.target=${FOLDER_NAME}

export SYNCHRONISE=""

# 颜色输出函数
function TIME() {
  case "$1" in
    r) local Color="\033[0;31m";;
    g) local Color="\033[0;32m";;
    y) local Color="\033[0;33m";;
    b) local Color="\033[0;34m";;
    z) local Color="\033[0;35m";;
    l) local Color="\033[0;36m";;
    *) local Color="\033[0;0m";;
  esac
echo -e "\n${Color}${2}\033[0m"
}

# 第一个自定义函数
Diy_one() {
    cd "${GITHUB_WORKSPACE}"
# Prefer repo-local common scripts; allow override via pre-set LINSHI_COMMON
if [[ -z "${LINSHI_COMMON}" ]]; then
  if [[ -d "${GITHUB_WORKSPACE}/common" ]]; then
    export LINSHI_COMMON="${GITHUB_WORKSPACE}/common"
  else
    export LINSHI_COMMON="/tmp/common"
  fi
fi
echo "LINSHI_COMMON=${LINSHI_COMMON}" >> "${GITHUB_ENV}"
# If common dir missing, stop early with clear error
if [[ ! -d "${LINSHI_COMMON}" ]]; then
  TIME r "缺少 common 目录：${LINSHI_COMMON}"
  exit 1
fi

    export COMMON_SH="${LINSHI_COMMON}/common.sh"
    export UPGRADE_SH="${LINSHI_COMMON}/upgrade.sh"
    export CONFIG_TXT="${LINSHI_COMMON}/config.txt"
    export ACTIONS_VERSION1=$(sed -nE 's/^[[:space:]]*ACTIONS_VERSION[[:space:]]*=[[:space:]]*"?([0-9.]+)"?.*/\1/p' "${COMMON_SH}")
    
    if [[ -d "build" ]] && [[ "${BENDI_VERSION}" == "2" ]]; then
        rm -rf "${OPERATES_PATH}"
        cp -Rf build "${OPERATES_PATH}"
    fi
}

# 第二个自定义函数
Diy_two() {
    cd "${GITHUB_WORKSPACE}"
    local required_dirs=("${OPERATES_PATH}" "${COMPILE_PATH}")
    local required_files=("${BUILD_PARTSH}" "${BUILD_SETTINGS}" "${COMPILE_PATH}/relevance/actions_version" "${COMPILE_PATH}/seed/${CONFIG_FILE}")

    for dir in "${required_dirs[@]}"; do
        if [[ ! -d "$dir" ]]; then
            SYNCHRONISE="NO"
            [[ "${BENDI_VERSION}" == "2" ]] && TIME r "缺少编译主文件build，请检查仓库文件（已禁用自动同步上游）..."
            [[ "${BENDI_VERSION}" == "1" ]] && TIME r "缺少编译主文件operates，请检查仓库文件（已禁用自动同步上游）..."
            return
        fi
    done

    for file in "${required_files[@]}"; do
        if [[ ! -f "$file" ]]; then
            if [[ "$file" == "${COMPILE_PATH}/seed/${CONFIG_FILE}" ]]; then
                TIME r "缺少 seed/${CONFIG_FILE} 文件，请先建立该文件"
                exit 1
            else
                SYNCHRONISE="NO"
                tongbu_message="缺少$file文件"
                TIME r "缺少$file文件，请检查仓库文件（已禁用自动同步上游）..."
                return
            fi
        fi
    done

    if [[ -f "${COMPILE_PATH}/relevance/actions_version" ]]; then
        ACTIONS_VERSION2=$(sed -nE 's/^[[:space:]]*ACTIONS_VERSION[[:space:]]*=[[:space:]]*"?([0-9.]+)"?.*/\1/p' "${COMPILE_PATH}/relevance/actions_version")
        if [[ -n "${ACTIONS_VERSION2}" && "${ACTIONS_VERSION1}" != "${ACTIONS_VERSION2}" ]]; then
            TIME y "检测到 actions_version 不一致：${ACTIONS_VERSION2} -> ${ACTIONS_VERSION1}（已自动更新；自动同步上游已禁用）"
            echo "ACTIONS_VERSION=${ACTIONS_VERSION1}" > "${COMPILE_PATH}/relevance/actions_version" || true
        fi
        SYNCHRONISE="YES"
    else
        SYNCHRONISE="YES"
    fi
}

# 第三个自定义函数
Diy_three() {
    cd "${GITHUB_WORKSPACE}"
    if [[ "$SYNCHRONISE" == "NO" ]]; then
        TIME r "检测到编译文件缺失或版本不一致，但已禁用自动同步上游。请检查仓库 build/${FOLDER_NAME} 与 settings.ini 是否完整，然后重新运行。"
        exit 1
    fi
}

# 第四个自定义函数
Diy_four() {
    cp -Rf "${COMPILE_PATH}" "${LINSHI_COMMON}/${FOLDER_NAME}"
    export DIY_PT1_SH="${LINSHI_COMMON}/${FOLDER_NAME}/diy-part.sh"
    export DIY_PT2_SH="${LINSHI_COMMON}/${FOLDER_NAME}/diy2-part.sh"

    echo "DIY_PT1_SH=${DIY_PT1_SH}" >> "${GITHUB_ENV}"
    echo "DIY_PT2_SH=${DIY_PT2_SH}" >> "${GITHUB_ENV}"
    echo "COMMON_SH=${COMMON_SH}" >> "${GITHUB_ENV}"
    echo "UPGRADE_SH=${UPGRADE_SH}" >> "${GITHUB_ENV}"
    echo "CONFIG_TXT=${CONFIG_TXT}" >> "${GITHUB_ENV}"

    echo '#!/bin/bash' > "${DIY_PT2_SH}"
    if grep -q "export" "${DIY_PT1_SH}"; then
      grep -E '.*export.*=".*"' "${DIY_PT1_SH}" >> "${DIY_PT2_SH}"
    fi
    chmod +x "${DIY_PT2_SH}"
    source "${DIY_PT2_SH}"

    if [[ -n "$(grep -Eo "grep -rl '.*'.*|.*xargs -r sed -i" "${DIY_PT1_SH}")" ]]; then
      grep -E 'grep -rl '.*'.*|.*xargs -r sed -i' "$DIY_PT1_SH" >> "${DIY_PT2_SH}"
      sed -i 's/\. |/${HOME_PATH}\/feeds |/g' "${DIY_PT2_SH}"
      grep -E 'grep -rl '.*'.*|.*xargs -r sed -i' "$DIY_PT1_SH" >> "${DIY_PT2_SH}"
      sed -i 's/\. |/${HOME_PATH}\/package |/g' "${DIY_PT2_SH}"
      grep -vE '^[[:space:]]*grep -rl '.*'.*|.*xargs -r sed -i' "${DIY_PT1_SH}" > tmp && mv tmp "${DIY_PT1_SH}"
    fi

    echo "OpenClash_branch=${OpenClash_branch}" >> "${GITHUB_ENV}"
    echo "Mandatory_theme=${Mandatory_theme}" >> "${GITHUB_ENV}"
    echo "Default_theme=${Default_theme}" >> "${GITHUB_ENV}"
    chmod -R +x "${OPERATES_PATH}"
    chmod -R +x "${LINSHI_COMMON}"
}

# 主菜单函数
Diy_memu() {
    Diy_one
    Diy_two
    Diy_three
    Diy_four
}

Diy_memu "$@"
