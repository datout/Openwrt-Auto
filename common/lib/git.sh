#!/usr/bin/env bash
# shellcheck shell=bash
# GitHub sparse/subtree download helper; sourced by common.sh.

function gitsvn() {
local url="${1%.git}"
local route="$2"
local tmpdir="$(mktemp -d)"
local base_url=""
local repo_name=""
local branch=""
local path_after_branch=""
local last_part=""
local files_name=""
local download_url=""
local parent_dir=""
local store_away=""

if [[ "$url" == *"tree"* ]]; then
    base_url=$(echo "$url" | sed 's|/tree/.*||')
    repo_name=$(echo "$base_url" | awk -F'/' '{print $5}')
    branch=$(echo "$url" | awk -F'/tree/' '{print $2}' | cut -d'/' -f1)
    path_after_branch=$(echo "$url" | sed -n "s|.*/tree/$branch||p" | sed 's|^/||')
    last_part=$(echo "$path_after_branch" | awk -F'/' '{print $NF}')
    [[ -n "$path_after_branch" ]] && path_name="$tmpdir/$path_after_branch" || path_name="$tmpdir"
    [[ -n "$last_part" ]] && files_name="$last_part" || files_name="$repo_name"
    [[ -z "$repo_name" ]] && { echo "错误链接,仓库名为空"; exit 1; }
elif [[ "$url" == *"blob"* ]]; then
    base_url=$(echo "$url" | sed 's|/blob/.*||')
    repo_name=$(echo "$base_url" | awk -F'/' '{print $5}')
    branch=$(echo "$url" | awk -F'/blob/' '{print $2}' | cut -d'/' -f1)
    path_after_branch=$(echo "$url" | sed -n "s|.*/blob/$branch||p" | sed 's|^/||')
    download_url="https://raw.githubusercontent.com/${base_url#*https://github.com/}/$branch/$path_after_branch"
    parent_dir="${path_after_branch%/*}"
    [[ -n "$path_after_branch" ]] && files_name="$path_after_branch" || { echo "错误链接,文件名为空"; exit 1; }
elif [[ "$url" == *"https://github.com"* ]]; then
    base_url="$url"
    repo_name=$(echo "$base_url" | awk -F'/' '{print $5}')
    path_name="$tmpdir"
    [[ -n "$repo_name" ]] && files_name="$repo_name" || { echo "错误链接,仓库名为空"; exit 1; }
else
    echo "无效的github链接"
    exit 1
fi

if [[ "$route" == "all" ]]; then
    store_away="$HOME_PATH/"
elif [[ "$route" == *"openwrt"* ]]; then
    store_away="$HOME_PATH/${route#*openwrt/}"
elif [[ "$route" == *"./"* ]]; then
    store_away="$HOME_PATH/${route#*./}"
elif [[ -n "$route" ]]; then
    store_away="$HOME_PATH/$route"
else
    store_away="$HOME_PATH/$files_name"
fi

if [[ "$url" == *"tree"* ]] && [[ -n "$path_after_branch" ]]; then
    if git clone -q --no-checkout "$base_url" "$tmpdir"; then
        cd "$tmpdir"
        git sparse-checkout init --cone > /dev/null 2>&1
        git sparse-checkout set "$path_after_branch" > /dev/null 2>&1
        git checkout "$branch" > /dev/null 2>&1
        grep -rl 'include ../../luci.mk' . | xargs -r sed -i 's#include ../../luci.mk#include \$(TOPDIR)/feeds/luci/luci.mk#g'
        grep -rl 'include ../../lang/' . | xargs -r sed -i 's#include ../../lang/#include \$(TOPDIR)/feeds/packages/lang/#g'
        if [[ "$route" == "all" ]]; then
            find "$path_name" -mindepth 1 -printf '%P\n' | while read -r item; do
            target="$HOME_PATH/${item}"
            if [ -e "$target" ]; then
                rm -rf "$target"
            fi
            done
            cp -r "$path_name"/* "$store_away"
        else
            rm -rf "$store_away" && cp -r "$path_name" "$store_away"
        fi
        [[ $? -eq 0 ]] && echo "$files_name文件下载完成" || { echo "$files_name文件下载失败"; exit 1; }
        cd "$HOME_PATH"
    else
        echo "$files_name文件下载失败"
        exit 1
    fi
elif [[ "$url" == *"tree"* ]] && [[ -n "$branch" ]]; then
    if git clone -q --single-branch --depth=1 --branch="$branch" "$base_url" "$tmpdir"; then
        if [[ "$route" == "all" ]]; then
            find "$path_name" -mindepth 1 -printf '%P\n' | while read -r item; do
            target="$HOME_PATH/${item}"
            if [ -e "$target" ]; then
                rm -rf "$target"
            fi
            done
            cp -r "$path_name"/* "$store_away"
        else
            rm -rf "$store_away" && cp -r "$path_name" "$store_away"
        fi
        [[ $? -eq 0 ]] && echo "$files_name文件下载完成" || { echo "$files_name文件下载失败"; exit 1; }
    else
        echo "$files_name文件下载失败"
        exit 1
    fi
elif [[ "$url" == *"blob"* ]]; then
    if [[ -n "$(echo "$parent_dir" | grep -E '/')" ]]; then
        [[ ! -d "${parent_dir}" ]] && mkdir -p "${parent_dir}"
    fi
    if curl -fsSL "$download_url" -o "$store_away"; then
        echo "$files_name 文件下载成功"
    else
        echo "$files_name文件下载失败"
        exit 1
    fi
elif [[ "$url" == *"https://github.com"* ]]; then
    if git clone -q --depth 1 "$base_url" "$tmpdir"; then
        if [[ "$route" == "all" ]]; then
            find "$path_name" -mindepth 1 -printf '%P\n' | while read -r item; do
            target="$HOME_PATH/${item}"
            if [ -e "$target" ]; then
                rm -rf "$target"
            fi
            done
            cp -r "$path_name"/* "$store_away"
        else
            rm -rf "$store_away" && cp -r "$path_name" "$store_away"
        fi
        [[ $? -eq 0 ]] && echo "$files_name文件下载完成" || { echo "$files_name文件下载失败"; exit 1; }
    else
        echo "$files_name文件下载失败"
        exit 1
    fi
else
    echo "无效的github链接"
    exit 1
fi
rm -rf "$tmpdir"
}



