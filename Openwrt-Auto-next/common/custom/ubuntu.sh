#!/bin/bash
# SPDX-License-Identifier: GPL-3.0-only

set -euo pipefail

PWD_DIR="$(pwd)"
TMP_DIR="${TMP_DIR:-/tmp}"

function install_mustrelyon(){
echo -e "\033[36m开始升级ubuntu插件和安装依赖.....\033[0m"

# 更新ubuntu源
apt-get update -y

# 升级ubuntu
apt-get full-upgrade -y

# 安装编译openwrt的依赖（合并到同一条 apt 命令，避免换行导致漏装）
apt-get install -y \
  ecj fastjar file gettext java-propose-classpath time xsltproc lib32gcc-s1 \
  ack antlr3 asciidoc autoconf automake autopoint binutils bison build-essential \
  bzip2 ccache cmake cpio curl device-tree-compiler flex gawk gcc-multilib g++-multilib \
  genisoimage git gperf haveged help2man intltool libc6-dev-i386 libelf-dev libglib2.0-dev \
  libgmp3-dev libltdl-dev libmpc-dev libmpfr-dev libncurses5-dev libncursesw5-dev libpython3-dev \
  libreadline-dev libssl-dev libtool llvm lrzsz msmtp ninja-build p7zip p7zip-full patch pkgconf \
  python2 python3 python3-pip python3-cryptography python3-docutils python3-ply python3-pyelftools python3-requests \
  python3-setuptools python3-distutils python3-netifaces qemu-utils rsync scons squashfs-tools subversion swig \
  texinfo uglifyjs upx-ucl unzip vim wget xmlto xxd zlib1g-dev \
  jq rename pigz clang gnupg

# alist依赖
apt-get install -y libfuse-dev

# N1打包需要的依赖（如确实需要 snap 可再加回去，这里先移除以减少不确定性）
# apt-get install -y snapd

# 修复：原脚本依赖 tinyurl 拉取包列表，但该链接当前已 404，会导致依赖缺失
apt-get install -y $(curl -fsSL https://raw.githubusercontent.com/ophub/amlogic-s9xxx-openwrt/refs/heads/main/make-openwrt/scripts/ubuntu2204-make-openwrt-depends)

# 安装gcc g++
GCC_VERSION="12"
add-apt-repository --yes ppa:ubuntu-toolchain-r/test
apt-get update -y
apt-get install -y gcc-${GCC_VERSION} g++-${GCC_VERSION}

update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-${GCC_VERSION} 60
update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-${GCC_VERSION} 60
update-alternatives --set gcc /usr/bin/gcc-${GCC_VERSION}
update-alternatives --set g++ /usr/bin/g++-${GCC_VERSION}

cd "$TMP_DIR"
# 安装golang（作为 Go 编译的 bootstrap，用于构建 OpenWrt 的 golang 包）
GO_VERSION="1.24.2"
wget -q "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz" -O "/tmp/go${GO_VERSION}.linux-amd64.tar.gz"
rm -rf /usr/local/go
tar -C /usr/local -xzf "/tmp/go${GO_VERSION}.linux-amd64.tar.gz"
echo 'export PATH=$PATH:/usr/local/go/bin' > /etc/profile.d/go.sh
# shellcheck disable=SC1091
source /etc/profile.d/go.sh
cd "$PWD_DIR"

# 安装nodejs yarn
curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
apt-get install -y nodejs
curl -sL https://dl.yarnpkg.com/debian/pubkey.gpg | gpg --batch --yes --dearmor -o /usr/share/keyrings/yarnkey.gpg
echo "deb [signed-by=/usr/share/keyrings/yarnkey.gpg] https://dl.yarnpkg.com/debian stable main" > /etc/apt/sources.list.d/yarn.list
apt-get update -y
apt-get install -y yarn gh

cd "$TMP_DIR"
# 安装UPX
UPX_VERSION="5.0.0"
curl -fLO "https://github.com/upx/upx/releases/download/v${UPX_VERSION}/upx-${UPX_VERSION}-amd64_linux.tar.xz"
tar -Jxf "upx-${UPX_VERSION}-amd64_linux.tar.xz"
rm -rf "/usr/bin/upx" "/usr/bin/upx-ucl"
cp -fp "upx-${UPX_VERSION}-amd64_linux/upx" "/usr/bin/upx-ucl"
chmod 0755 "/usr/bin/upx-ucl"
ln -svf "/usr/bin/upx-ucl" "/usr/bin/upx"
cd "$PWD_DIR"

cd "$TMP_DIR"
# 安装padjffs2
rm -rf "padjffs2"
git clone --filter=blob:none --no-checkout "https://github.com/openwrt/openwrt.git" "padjffs2"
pushd "padjffs2" >/dev/null
git config core.sparseCheckout true
echo "tools/padjffs2/src" >> ".git/info/sparse-checkout"
git checkout
cd "tools/padjffs2/src"
make padjffs2
strip "padjffs2" || true
rm -rf "/usr/bin/padjffs2"
cp -fp "padjffs2" "/usr/bin/padjffs2"
popd >/dev/null
cd "$PWD_DIR"

cd "$TMP_DIR"
# 安装po2lmo
rm -rf "po2lmo"
git clone --filter=blob:none --no-checkout "https://github.com/openwrt/luci.git" "po2lmo"
pushd "po2lmo" >/dev/null
git config core.sparseCheckout true
echo "modules/luci-base/src" >> ".git/info/sparse-checkout"
git checkout
cd "modules/luci-base/src"
make po2lmo
strip "po2lmo" || true
rm -rf "/usr/bin/po2lmo"
cp -fp "po2lmo" "/usr/bin/po2lmo"
popd >/dev/null
cd "$PWD_DIR"

curl -fL "https://build-scripts.immortalwrt.org/modify-firmware.sh" -o "/usr/bin/modify-firmware"
chmod 0755 "/usr/bin/modify-firmware"
}

function update_apt_source(){
apt-get autoremove -y --purge
apt-get clean -y

python2.7 --version || true
python3 --version
node -v
yarn -v
go version
gcc --version
g++ --version
clang --version
upx --version
echo "GitHub CLI：$(gh --version)"
echo -e "\033[32m全部依赖安装完毕!\033[0m"
}

function main(){
  install_mustrelyon
  update_apt_source
}

main
