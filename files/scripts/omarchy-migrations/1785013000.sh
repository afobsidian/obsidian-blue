echo "Move zram tuning to a vendor drop-in"

zram_conf="${OMARCHY_ZRAM_CONF:-/etc/systemd/zram-generator.conf}"
zram_dropin="${OMARCHY_ZRAM_DROPIN:-/usr/lib/systemd/zram-generator.conf.d/90-omarchy.conf}"

[[ -f "$zram_conf" ]] || exit 0
[[ -f "$zram_dropin" ]] || exit 0
rpm -qf "$zram_conf" >/dev/null 2>&1 && exit 0

settings="$(grep -vE '^[[:space:]]*([#;]|$)' "$zram_conf" | tr -d '[:space:]')" || true
if [[ -z "$settings" || "$settings" =~ ^\[zram0\]compression-algorithm=[[:alnum:]-]+$ ]]; then
  sudo rm -f "$zram_conf" || true
else
  echo "Keeping $zram_conf; it has local edits."
fi
