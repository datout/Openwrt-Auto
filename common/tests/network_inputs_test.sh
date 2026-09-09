#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=../lib/network.sh
source "${ROOT_DIR}/common/lib/network.sh"

fail() {
  echo "TEST FAILED: $*" >&2
  exit 1
}

assert_eq() {
  local expected="$1"
  local actual="$2"
  local label="$3"
  [[ "${expected}" == "${actual}" ]] || fail "${label}: expected '${expected}', got '${actual}'"
}

reset_inputs() {
  LAN_IP=""
  LAN_NETMASK=""
  LAN_GATEWAY=""
  LAN_DNS=""
  DHCP_MODE=""
  ROUTER_HOSTNAME=""
}

reset_inputs
Diy_network_normalize_inputs
assert_eq "" "${LAN_IP}" "blank LAN_IP"
assert_eq "keep" "${DHCP_MODE}" "blank DHCP_MODE"

LAN_IP="10.0.0.252"
LAN_NETMASK="/24"
LAN_GATEWAY="10.0.0.253"
LAN_DNS="223.5.5.5, 119.29.29.29 223.5.5.5"
DHCP_MODE="关闭 DHCP"
ROUTER_HOSTNAME="OpenWrt-B9"
Diy_network_normalize_inputs
assert_eq "10.0.0.252" "${LAN_IP}" "normalized LAN_IP"
assert_eq "255.255.255.0" "${LAN_NETMASK}" "normalized LAN_NETMASK"
assert_eq "10.0.0.253" "${LAN_GATEWAY}" "normalized LAN_GATEWAY"
assert_eq "223.5.5.5 119.29.29.29" "${LAN_DNS}" "normalized LAN_DNS"
assert_eq "disable" "${DHCP_MODE}" "normalized DHCP_MODE"
assert_eq "OpenWrt-B9" "${ROUTER_HOSTNAME}" "normalized hostname"

runtime_settings="$(mktemp)"
printf '%s=%q\n' "LAN_DNS" "${LAN_DNS}" > "${runtime_settings}"
LAN_DNS=""
# shellcheck disable=SC1090
source "${runtime_settings}"
rm -f "${runtime_settings}"
assert_eq "223.5.5.5 119.29.29.29" "${LAN_DNS}" "runtime settings DNS quoting"

LAN_IP="10.0.0.252"
LAN_NETMASK="255.255.255.0"
LAN_GATEWAY="10.0.0.253"
LAN_DNS="1.1.1.1"
DHCP_MODE="开启 DHCP"
ROUTER_HOSTNAME="OpenWrt"
Ipv4_ipaddr="192.168.1.1"
Netmask_netm="255.255.255.0"
Gateway_Settings="0"
DNS_Settings="0"
Disable_DHCP="1"
Op_name="OldName"
Diy_network_apply_overrides >/dev/null
Diy_network_validate_effective_route "192.168.1.1" "255.255.255.0" >/dev/null
assert_eq "10.0.0.252" "${Ipv4_ipaddr}" "applied LAN_IP"
assert_eq "255.255.255.0" "${Netmask_netm}" "applied LAN_NETMASK"
assert_eq "10.0.0.253" "${Gateway_Settings}" "applied LAN_GATEWAY"
assert_eq "1.1.1.1" "${DNS_Settings}" "applied LAN_DNS"
assert_eq "2" "${Disable_DHCP}" "explicit DHCP enable"
assert_eq "OpenWrt" "${Op_name}" "applied hostname"

reset_inputs
LAN_IP="10.0.0.999"
if Diy_network_normalize_inputs >/dev/null 2>&1; then
  fail "invalid IPv4 address was accepted"
fi

reset_inputs
LAN_NETMASK="255.0.255.0"
if Diy_network_normalize_inputs >/dev/null 2>&1; then
  fail "invalid netmask was accepted"
fi

reset_inputs
LAN_NETMASK="/0"
if Diy_network_normalize_inputs >/dev/null 2>&1; then
  fail "zero-length netmask was accepted"
fi

reset_inputs
LAN_NETMASK="/31"
if Diy_network_normalize_inputs >/dev/null 2>&1; then
  fail "LAN /31 netmask was accepted"
fi

reset_inputs
LAN_NETMASK="255.255.255.254"
if Diy_network_normalize_inputs >/dev/null 2>&1; then
  fail "dotted LAN /31 netmask was accepted"
fi

reset_inputs
LAN_DNS="1.1.1.1;rm -rf /"
if Diy_network_normalize_inputs >/dev/null 2>&1; then
  fail "unsafe DNS value was accepted"
fi

reset_inputs
ROUTER_HOSTNAME="bad hostname"
if Diy_network_normalize_inputs >/dev/null 2>&1; then
  fail "invalid hostname was accepted"
fi

reset_inputs
LAN_IP="10.0.0.255"
LAN_NETMASK="255.255.255.0"
LAN_GATEWAY="0"
Ipv4_ipaddr="192.168.1.1"
Netmask_netm="255.255.255.0"
Gateway_Settings="0"
DNS_Settings="0"
Disable_DHCP="0"
Op_name="OpenWrt"
Diy_network_apply_overrides >/dev/null
if Diy_network_validate_effective_route "192.168.1.1" "255.255.255.0" >/dev/null 2>&1; then
  fail "broadcast LAN address was accepted without a gateway"
fi

reset_inputs
LAN_IP="10.0.0.0"
LAN_NETMASK="255.255.255.0"
LAN_GATEWAY="10.0.0.1"
Ipv4_ipaddr="192.168.1.1"
Netmask_netm="255.255.255.0"
Gateway_Settings="0"
DNS_Settings="0"
Disable_DHCP="0"
Op_name="OpenWrt"
Diy_network_apply_overrides >/dev/null
if Diy_network_validate_effective_route "192.168.1.1" "255.255.255.0" >/dev/null 2>&1; then
  fail "network address was accepted as LAN address"
fi

reset_inputs
LAN_IP="10.0.0.2"
LAN_NETMASK="255.255.255.0"
LAN_GATEWAY="192.168.1.1"
Ipv4_ipaddr="192.168.1.1"
Netmask_netm="255.255.255.0"
Gateway_Settings="0"
DNS_Settings="0"
Disable_DHCP="0"
Op_name="OpenWrt"
Diy_network_apply_overrides >/dev/null
if Diy_network_validate_effective_route "192.168.1.1" "255.255.255.0" >/dev/null 2>&1; then
  fail "off-subnet gateway was accepted"
fi

echo "network input tests passed"
