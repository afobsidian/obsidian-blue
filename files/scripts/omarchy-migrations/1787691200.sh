echo "Skip Chromium's new first-run EULA on Fedora"

chromium_prefs="${OMARCHY_CHROMIUM_PREFS:-/etc/chromium/master_preferences}"
[[ -f "$chromium_prefs" ]] || exit 0

tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT
jq '
  .distribution.require_eula = false |
  .browser.theme.color_scheme = 0 |
  .browser.theme.color_scheme2 = 0
' "$chromium_prefs" >"$tmp"
cmp -s "$tmp" "$chromium_prefs" && exit 0
if (( EUID == 0 )); then
  install -m 0644 "$tmp" "$chromium_prefs"
else
  sudo install -m 0644 "$tmp" "$chromium_prefs"
fi
