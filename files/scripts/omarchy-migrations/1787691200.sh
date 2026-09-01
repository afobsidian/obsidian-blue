echo "Skip Chromium's new first-run EULA on Fedora"

chromium_seed='{"distribution":{"require_eula":false},"browser":{"theme":{"color_scheme":0,"color_scheme2":0}}}'

for chromium_prefs in \
  /usr/lib64/chromium-browser/initial_preferences \
  /usr/lib/chromium-browser/initial_preferences \
  /usr/lib64/chromium/initial_preferences \
  /usr/lib/chromium/initial_preferences; do
  [[ -d "$(dirname "$chromium_prefs")" ]] || continue
  [[ $(cat "$chromium_prefs" 2>/dev/null) == "$chromium_seed" ]] && continue
  printf '%s\n' "$chromium_seed" | sudo tee "$chromium_prefs" >/dev/null
done
