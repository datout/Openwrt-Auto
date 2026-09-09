#!/usr/bin/env bash
# shellcheck shell=bash
# Workflow network preset validation and legacy variable overrides.

function Diy_network_normalize_inputs() {
  local normalized_file
  normalized_file="$(mktemp)"

  if ! python3 - \
    "${LAN_IP:-}" \
    "${LAN_NETMASK:-}" \
    "${LAN_GATEWAY:-}" \
    "${LAN_DNS:-}" \
    "${DHCP_MODE:-}" \
    "${ROUTER_HOSTNAME:-}" >"${normalized_file}" <<'PY'
import ipaddress
import re
import sys

lan_ip, netmask, gateway, dns, dhcp_mode, hostname = sys.argv[1:]


def fail(message: str) -> None:
    print(f"::error title=网络参数校验失败::{message}", file=sys.stderr)
    raise SystemExit(1)


def clean(value: str, label: str, max_length: int = 256) -> str:
    if any(char in value for char in ("\x00", "\r", "\n")):
        fail(f"{label} 不能包含换行或空字符")
    value = value.strip()
    if len(value) > max_length:
        fail(f"{label} 长度不能超过 {max_length} 个字符")
    return value


def normalize_ipv4(value: str, label: str) -> str:
    value = clean(value, label, 64)
    if value in ("", "0"):
        return value
    try:
        address = ipaddress.IPv4Address(value)
    except ipaddress.AddressValueError:
        fail(f"{label} 不是合法 IPv4 地址：{value}")
    if address.is_unspecified or address.is_loopback or address.is_multicast:
        fail(f"{label} 不能使用 {address}")
    if address == ipaddress.IPv4Address("255.255.255.255"):
        fail(f"{label} 不能使用广播地址 255.255.255.255")
    return str(address)


def normalize_netmask(value: str) -> str:
    value = clean(value, "LAN 子网掩码", 64)
    if value in ("", "0"):
        return value
    prefix = value[1:] if value.startswith("/") else value
    try:
        if prefix.isdigit():
            prefix_value = int(prefix)
            if not 1 <= prefix_value <= 30:
                fail("LAN 子网前缀必须在 1 到 30 之间（/31 和 /32 不适合作为 LAN 网段）")
            network = ipaddress.IPv4Network(f"0.0.0.0/{prefix_value}")
        else:
            network = ipaddress.IPv4Network(f"0.0.0.0/{value}")
    except (ipaddress.NetmaskValueError, ipaddress.AddressValueError):
        fail(f"LAN 子网掩码不合法：{value}")
    if not 1 <= network.prefixlen <= 30:
        fail("LAN 子网前缀必须在 1 到 30 之间（/31 和 /32 不适合作为 LAN 网段）")
    return str(network.netmask)


def normalize_dns(value: str) -> str:
    value = clean(value, "上游 DNS")
    if value in ("", "0"):
        return value
    if re.search(r"[^0-9.,\t ]", value):
        fail("上游 DNS 只允许 IPv4 地址，并使用空格或逗号分隔")
    items = [item for item in re.split(r"[\s,]+", value) if item]
    if not 1 <= len(items) <= 4:
        fail("上游 DNS 必须填写 1 到 4 个 IPv4 地址")
    normalized = []
    for item in items:
        item = normalize_ipv4(item, "上游 DNS")
        if item not in normalized:
            normalized.append(item)
    return " ".join(normalized)


def normalize_dhcp(value: str) -> str:
    value = clean(value, "DHCP 模式", 64)
    token = re.sub(r"[\s_-]+", "", value).lower()
    mapping = {
        "": "keep",
        "0": "keep",
        "keep": "keep",
        "default": "keep",
        "保持预设": "keep",
        "保持仓库预设": "keep",
        "enable": "enable",
        "enabled": "enable",
        "on": "enable",
        "true": "enable",
        "开启": "enable",
        "开启dhcp": "enable",
        "disable": "disable",
        "disabled": "disable",
        "off": "disable",
        "false": "disable",
        "关闭": "disable",
        "关闭dhcp": "disable",
    }
    if token not in mapping:
        fail(f"不支持的 DHCP 模式：{value}")
    return mapping[token]


def normalize_hostname(value: str) -> str:
    value = clean(value, "OpenWrt 主机名", 63)
    if value in ("", "0"):
        return value
    if not re.fullmatch(r"[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?", value):
        fail("OpenWrt 主机名只能包含英文字母、数字和连字符，且不能以连字符开头或结尾")
    return value


values = {
    "LAN_IP": normalize_ipv4(lan_ip, "LAN 管理地址"),
    "LAN_NETMASK": normalize_netmask(netmask),
    "LAN_GATEWAY": normalize_ipv4(gateway, "上级网关"),
    "LAN_DNS": normalize_dns(dns),
    "DHCP_MODE": normalize_dhcp(dhcp_mode),
    "ROUTER_HOSTNAME": normalize_hostname(hostname),
}

for key, value in values.items():
    print(f"{key}={value}")
PY
  then
    rm -f "${normalized_file}"
    return 1
  fi

  local key value
  while IFS='=' read -r key value; do
    case "${key}" in
      LAN_IP) LAN_IP="${value}" ;;
      LAN_NETMASK) LAN_NETMASK="${value}" ;;
      LAN_GATEWAY) LAN_GATEWAY="${value}" ;;
      LAN_DNS) LAN_DNS="${value}" ;;
      DHCP_MODE) DHCP_MODE="${value}" ;;
      ROUTER_HOSTNAME) ROUTER_HOSTNAME="${value}" ;;
    esac
  done < "${normalized_file}"
  rm -f "${normalized_file}"

  export LAN_IP LAN_NETMASK LAN_GATEWAY LAN_DNS DHCP_MODE ROUTER_HOSTNAME
}

function Diy_network_print_input_summary() {
  local keep_text="沿用 build/${FOLDER_NAME:-unknown}/diy-part.sh"
  local value

  echo "本次网络预设覆盖："
  for value in LAN_IP LAN_NETMASK LAN_GATEWAY LAN_DNS ROUTER_HOSTNAME; do
    if [[ -z "${!value:-}" ]]; then
      printf '  %-18s %s\n' "${value}:" "${keep_text}"
    elif [[ "${!value}" == "0" ]]; then
      case "${value}" in
        LAN_GATEWAY|LAN_DNS)
          printf '  %-18s %s\n' "${value}:" "不写入自定义值，保留源码默认"
          ;;
        *)
          printf '  %-18s %s\n' "${value}:" "不修改源码默认值"
          ;;
      esac
    else
      printf '  %-18s %s\n' "${value}:" "${!value}"
    fi
  done

  case "${DHCP_MODE:-keep}" in
    enable) echo "  DHCP_MODE:         明确开启 DHCP" ;;
    disable) echo "  DHCP_MODE:         明确关闭 DHCP" ;;
    *) echo "  DHCP_MODE:         ${keep_text}" ;;
  esac
}

function Diy_network_validate_effective_route() {
  local source_ip="${1:-}"
  local source_netmask="${2:-}"
  local effective_ip="${Ipv4_ipaddr:-}"
  local effective_netmask="${Netmask_netm:-}"
  local effective_gateway="${Gateway_Settings:-}"

  if [[ -z "${effective_ip}" || "${effective_ip}" == "0" ]]; then
    effective_ip="${source_ip}"
  fi
  if [[ -z "${effective_netmask}" || "${effective_netmask}" == "0" ]]; then
    effective_netmask="${source_netmask}"
  fi

  python3 - \
    "${effective_ip}" \
    "${effective_netmask}" \
    "${effective_gateway}" <<'PY'
import ipaddress
import sys

lan_ip, netmask, gateway = sys.argv[1:]
if not lan_ip or not netmask:
    print(
        "::error title=网络参数校验失败::无法从源码中取得最终 LAN 地址或子网掩码，不能安全应用本次网络覆盖",
        file=sys.stderr,
    )
    raise SystemExit(1)

try:
    address = ipaddress.IPv4Address(lan_ip)
    route = ipaddress.IPv4Network(f"{lan_ip}/{netmask}", strict=False)
except (ipaddress.AddressValueError, ipaddress.NetmaskValueError) as exc:
    print(f"::error title=网络参数校验失败::无法校验最终 LAN 网段：{exc}", file=sys.stderr)
    raise SystemExit(1)

if not 1 <= route.prefixlen <= 30:
    print(
        f"::error title=网络参数校验失败::LAN 网段 {route} 的前缀必须在 /1 到 /30 之间",
        file=sys.stderr,
    )
    raise SystemExit(1)
if address in (route.network_address, route.broadcast_address):
    print(
        f"::error title=网络参数校验失败::LAN 地址 {address} 不能是网段 {route} 的网络地址或广播地址",
        file=sys.stderr,
    )
    raise SystemExit(1)

if not gateway or gateway == "0":
    raise SystemExit(0)

try:
    next_hop = ipaddress.IPv4Address(gateway)
except ipaddress.AddressValueError as exc:
    print(f"::error title=网络参数校验失败::无法校验最终上级网关：{exc}", file=sys.stderr)
    raise SystemExit(1)

if next_hop not in route:
    print(
        f"::error title=网络参数校验失败::上级网关 {next_hop} 不在 LAN 网段 {route} 内",
        file=sys.stderr,
    )
    raise SystemExit(1)
if next_hop in (address, route.network_address, route.broadcast_address):
    print(
        f"::error title=网络参数校验失败::上级网关 {next_hop} 不能与 LAN 地址、网络地址或广播地址相同",
        file=sys.stderr,
    )
    raise SystemExit(1)
PY
}

function Diy_network_apply_overrides() {
  Diy_network_normalize_inputs || return 1

  NETWORK_ROUTE_OVERRIDE="false"

  if [[ -n "${LAN_IP}" ]]; then
    Ipv4_ipaddr="${LAN_IP}"
    NETWORK_ROUTE_OVERRIDE="true"
  fi
  if [[ -n "${LAN_NETMASK}" ]]; then
    Netmask_netm="${LAN_NETMASK}"
    NETWORK_ROUTE_OVERRIDE="true"
  fi
  if [[ -n "${LAN_GATEWAY}" ]]; then
    Gateway_Settings="${LAN_GATEWAY}"
    NETWORK_ROUTE_OVERRIDE="true"
  fi
  if [[ -n "${LAN_DNS}" ]]; then
    DNS_Settings="${LAN_DNS}"
  fi
  if [[ -n "${ROUTER_HOSTNAME}" ]]; then
    Op_name="${ROUTER_HOSTNAME}"
  fi

  case "${DHCP_MODE}" in
    enable) Disable_DHCP="2" ;;
    disable) Disable_DHCP="1" ;;
    keep) ;;
    *)
      echo "::error title=网络参数校验失败::未知 DHCP 模式：${DHCP_MODE}" >&2
      return 1
      ;;
  esac

  export Ipv4_ipaddr Netmask_netm Gateway_Settings DNS_Settings Op_name Disable_DHCP
  export NETWORK_ROUTE_OVERRIDE

  local ip_summary="${Ipv4_ipaddr:-保留源码默认}"
  local netmask_summary="${Netmask_netm:-保留源码默认}"
  local gateway_summary="${Gateway_Settings:-保留源码默认}"
  local dns_summary="${DNS_Settings:-保留源码默认}"
  local hostname_summary="${Op_name:-保留源码默认}"
  [[ "${ip_summary}" == "0" ]] && ip_summary="保留源码默认"
  [[ "${netmask_summary}" == "0" ]] && netmask_summary="保留源码默认"
  [[ "${gateway_summary}" == "0" ]] && gateway_summary="保留源码默认"
  [[ "${dns_summary}" == "0" ]] && dns_summary="保留源码默认"
  [[ "${hostname_summary}" == "0" ]] && hostname_summary="保留源码默认"

  echo "准备应用的网络预设："
  echo "  LAN 管理地址: ${ip_summary}"
  echo "  LAN 子网掩码: ${netmask_summary}"
  echo "  上级网关: ${gateway_summary}"
  echo "  上游 DNS: ${dns_summary}"
  local dhcp_summary="沿用预设"
  case "${Disable_DHCP:-0}" in
    1) dhcp_summary="关闭" ;;
    2) dhcp_summary="开启" ;;
  esac
  echo "  DHCP: ${dhcp_summary}"
  echo "  OpenWrt 主机名: ${hostname_summary}"
}
