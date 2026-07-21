#!/usr/bin/env bash
set -Eeuo pipefail

primary_interface() {
  ip route show default | awk 'NR==1 {print $5}'
}

network_summary() {
  local iface
  iface="$(primary_interface)"
  printf 'Interface: %s\n' "${iface:-unknown}"
  ip -4 -brief address show dev "${iface}" 2>/dev/null || true
  ip route show default || true
}

configure_dhcp() {
  local iface="${1:-$(primary_interface)}"
  [[ -n "${iface}" ]] || {
    echo 'Unable to detect primary interface.' >&2
    return 1
  }
  nmcli connection modify "${iface}" ipv4.method auto ipv4.addresses '' ipv4.gateway '' ipv4.dns '' || {
    local con
    con="$(nmcli -g GENERAL.CONNECTION device show "${iface}")"
    nmcli connection modify "${con}" ipv4.method auto ipv4.addresses '' ipv4.gateway '' ipv4.dns ''
  }
  nmcli device reapply "${iface}" || nmcli connection up "$(nmcli -g GENERAL.CONNECTION device show "${iface}")"
}

configure_static() {
  local iface="$1" address="$2" gateway="$3" dns="$4"
  local con
  con="$(nmcli -g GENERAL.CONNECTION device show "${iface}")"
  [[ -n "${con}" && "${con}" != '--' ]] || {
    echo "No NetworkManager connection for ${iface}" >&2
    return 1
  }
  nmcli connection modify "${con}" ipv4.method manual ipv4.addresses "${address}" ipv4.gateway "${gateway}" ipv4.dns "${dns}"
  nmcli connection up "${con}"
}

test_network() {
  ip route show default >/dev/null
  getent hosts charts.kasten.io >/dev/null
  curl --fail --silent --show-error --max-time 10 https://charts.kasten.io/ >/dev/null
}
