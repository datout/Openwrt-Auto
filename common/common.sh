#!/bin/bash
# https://github.com/datout/Openwrt-Auto
# common Module by datout
# matrix.target=${FOLDER_NAME}

ACTIONS_VERSION="2.12.0"

# Runtime helpers are split into small sourced modules for maintainability.
COMMON_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib"
source "${COMMON_LIB_DIR}/core.sh"
source "${COMMON_LIB_DIR}/git.sh"
source "${COMMON_LIB_DIR}/feeds.sh"
source "${COMMON_LIB_DIR}/sources.sh"
source "${COMMON_LIB_DIR}/config.sh"
source "${COMMON_LIB_DIR}/firmware.sh"
source "${COMMON_LIB_DIR}/bootstrap.sh"
source "${COMMON_LIB_DIR}/checkout.sh"
source "${COMMON_LIB_DIR}/finalize.sh"
source "${COMMON_LIB_DIR}/definition.sh"
source "${COMMON_LIB_DIR}/prevent.sh"

# Bootstrap helpers moved to lib/bootstrap.sh
# Checkout preparation moved to lib/checkout.sh
# Source-specific adjustment functions moved to lib/sources.sh

# Menu/config preparation functions moved to lib/config.sh
# Post-menu management helper moved to lib/finalize.sh
# Final system/profile definition helper moved to lib/definition.sh
# Package conflict/prevention helper moved to lib/prevent.sh
# Firmware post-build function moved to lib/firmware.sh
# GitHub download helper moved to lib/git.sh
function Diy_menu() {
cd $HOME_PATH
Diy_checkout
Diy_${SOURCE_CODE}
}

function Diy_menu2() {
cd $HOME_PATH
Diy_partsh
}

function Diy_menu3() {
cd $HOME_PATH
Diy_scripts
}

function Diy_menu4() {
cd $HOME_PATH
Diy_profile
}

function Diy_menu5() {
cd $HOME_PATH
Diy_management
Diy_definition
Diy_prevent
}

function Diy_menu6() {
Diy_variable
}

if [[ "${BENDI_VERSION}" == "2" ]]; then
  case "${1}" in
    "Diy_menu") Diy_menu ;;
    "Diy_menu2") Diy_menu2 ;;
    "Diy_menu3") Diy_menu3 ;;
    "Diy_menu4") Diy_menu4 ;;
    "Diy_menu5") Diy_menu5 ;;
    "Diy_menu6") Diy_menu6 ;;
    "Diy_firmware") Diy_firmware ;;
    "Diy_feedsconf") Diy_feedsconf ;;
    *) 
      echo "不支持${1}" ;;
  esac
fi
