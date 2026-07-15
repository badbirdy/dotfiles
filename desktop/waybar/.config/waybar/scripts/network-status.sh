#!/usr/bin/env bash
set -euo pipefail

wifi_if="${WAYBAR_WIFI_IF:-wlp4s0}"
ethernet_if="${WAYBAR_ETHERNET_IF:-eno1}"
state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/waybar"
mode_file="$state_dir/network-display-mode"

display_mode() {
  [[ -r "$mode_file" ]] && cat "$mode_file" || printf 'name\n'
}

toggle_mode() {
  mkdir -p "$state_dir"
  if [[ "$(display_mode)" == "icon" ]]; then
    printf 'name\n' > "$mode_file"
  else
    printf 'icon\n' > "$mode_file"
  fi
}

display_text() {
  local icon="$1"
  local name="$2"

  if [[ "$(display_mode)" == "icon" ]]; then
    printf '%s' "$icon"
  else
    printf '%s  %s' "$icon" "$name"
  fi
}

if [[ "${1:-}" == "toggle" ]]; then
  toggle_mode
  exit 0
fi

device_state() {
  nmcli -t -f DEVICE,STATE device status 2>/dev/null | awk -F: -v dev="$1" '$1 == dev { print $2; exit }' || true
}

device_connection() {
  nmcli -g GENERAL.CONNECTION device show "$1" 2>/dev/null | head -n 1 || true
}

device_ip() {
  nmcli -g IP4.ADDRESS device show "$1" 2>/dev/null | sed 's#/.*##' | head -n 1 || true
}

wifi_signal() {
  nmcli -t -f ACTIVE,SIGNAL device wifi list ifname "$wifi_if" 2>/dev/null |
    awk -F: '$1 == "yes" { print $2; exit }' || true
}

emit() {
  local mode_class

  mode_class="$(display_mode)"
  jq -cn \
    --arg text "$1" \
    --arg tooltip "$2" \
    --arg class "$3" \
    --arg mode_class "$mode_class" \
    '{text: $text, tooltip: $tooltip, class: [$class, $mode_class]}'
}

wifi_state="$(device_state "$wifi_if")"
ethernet_state="$(device_state "$ethernet_if")"

if [[ "$wifi_state" == "connected" ]]; then
  ssid="$(device_connection "$wifi_if")"
  signal="$(wifi_signal)"
  ipaddr="$(device_ip "$wifi_if")"
  tooltip="${ssid:-Wi-Fi} (${signal:-?}%)"$'\n'"$wifi_if : ${ipaddr:-no IPv4}"
  emit "$(display_text "" "${ssid:-Wi-Fi}")" "$tooltip" "wifi"
elif [[ "$ethernet_state" == "connected" ]]; then
  connection="$(device_connection "$ethernet_if")"
  ipaddr="$(device_ip "$ethernet_if")"
  tooltip="${connection:-Ethernet}"$'\n'"$ethernet_if : ${ipaddr:-no IPv4}"
  emit "$(display_text "󰈀" "${connection:-$ethernet_if}")" "$tooltip" "ethernet"
else
  emit "$(display_text "" "Disconnected")" "Disconnected | Click to open GUI" "disconnected"
fi
