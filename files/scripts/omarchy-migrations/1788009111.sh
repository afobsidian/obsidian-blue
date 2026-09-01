echo "Remove automatic printer discovery from the Fedora image"

machine_marker="${OMARCHY_CUPS_BROWSED_REMOVAL_MARKER:-/var/lib/omarchy/migrations/1788009111}"

[[ ! -e "$machine_marker" ]] || exit 0
rpm -q cups-browsed >/dev/null 2>&1 && exit 1
