#!/usr/bin/env bash
set -euo pipefail

repo="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
root="$(mktemp -d)"
trap 'rm -rf "$root"' EXIT
mkdir -p "$root/bin" "$root/etc"
sed "s|/etc/sddm.conf|$root/etc/sddm.conf|g" "$repo/files/usr/bin/obsidian-blue-setup" >"$root/setup"
export TEST_ROOT="$root" XDG_STATE_HOME="$root/state"
export PATH="$root/bin:$PATH"

cat >"$root/bin/id" <<'EOF'
#!/usr/bin/env bash
case "$1" in -u) echo "${TEST_UID:-1000}" ;; -un) printf '%s\n' "${TEST_ACCOUNT:-tester}" ;; esac
EOF
cat >"$root/bin/gum" <<'EOF'
#!/usr/bin/env bash
case "$1" in
  choose)
    IFS= read -r choice <"$TEST_ROOT/choices" || exit 130
    tail -n +2 "$TEST_ROOT/choices" >"$TEST_ROOT/remaining"
    mv "$TEST_ROOT/remaining" "$TEST_ROOT/choices"
    printf '%s\n' "$choice"
    ;;
  confirm) [[ "${CONFIRM:-yes}" == yes ]] ;;
esac
EOF
cat >"$root/bin/sudo" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$*" >>"$TEST_ROOT/sudo.log"
target="${!#}"
[[ "$target" == "$TEST_ROOT/etc/sddm.conf.d/90-obsidian-blue-autologin.conf" ]] || exit 1
case "$1" in
  install) mkdir -p "$(dirname "$target")"; cp "${@: -2:1}" "$target" ;;
  rm) rm -f -- "$target" ;;
  *) exit 1 ;;
esac
EOF
cat >"$root/bin/fwupdmgr" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >>"$TEST_ROOT/firmware.log"
[[ "$1" != refresh || "${REFRESH_FAIL:-0}" == 0 ]]
EOF
cat >"$root/bin/journalctl" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
cat >"$root/bin/omarchy-launch-floating-terminal-with-presentation" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$@" >"$TEST_ROOT/launch.log"
EOF
chmod +x "$root/bin/"*
run_setup() { bash "$root/setup" "$@" >/dev/null; }
choices() { printf '%s\n' "$@" >"$root/choices"; }
managed="$root/etc/sddm.conf.d/90-obsidian-blue-autologin.conf"
marker="$XDG_STATE_HOME/obsidian-blue/setup-v1.done"

run_setup --first-login
grep -Fxq /usr/bin/obsidian-blue-setup "$root/launch.log"
choices Later
run_setup
test ! -e "$marker"

choices 'Automatic login' 'Automatically log in as tester' 'Finish setup'
run_setup
grep -Fxq 'User=tester' "$managed"
grep -Fxq 'Session=omarchy.desktop' "$managed"
test -f "$marker"
rm "$root/launch.log"
run_setup --first-login
test ! -e "$root/launch.log"

printf 'personal\n' >"$root/etc/sddm.conf.d/10-personal.conf"
choices 'Automatic login' 'Disable setup-managed autologin' 'Finish setup'
run_setup
test ! -e "$managed"
grep -Fxq personal "$root/etc/sddm.conf.d/10-personal.conf"

choices 'Automatic login' 'Automatically log in as tester' 'Finish setup'
CONFIRM=no run_setup
test ! -e "$managed"
printf '[Autologin]\nUser=other\n' >"$root/etc/sddm.conf"
choices 'Automatic login' 'Automatically log in as tester' 'Finish setup'
run_setup 2>/dev/null
test ! -e "$managed"
grep -Fxq 'User=other' "$root/etc/sddm.conf"

choices 'Firmware and Secure Boot' 'Finish setup'
CONFIRM=no run_setup
grep -Fxq 'security --no-security-fix' "$root/firmware.log"
! grep -Fxq update "$root/firmware.log"
choices 'Firmware and Secure Boot' 'Finish setup'
REFRESH_FAIL=1 run_setup 2>/dev/null
grep -Fxq refresh "$root/firmware.log"
! grep -Fxq update "$root/firmware.log"
choices 'Firmware and Secure Boot' 'Finish setup'
run_setup
grep -Fxq update "$root/firmware.log"

if TEST_ACCOUNT='bad]name' run_setup 2>/dev/null; then exit 1; fi
if TEST_UID=0 run_setup 2>/dev/null; then exit 1; fi
grep -Fxq 'ExecStartPost=/usr/bin/obsidian-blue-setup --first-login' \
  "$repo/files/usr/lib/systemd/user/omarchy-migrate-notify.service.d/20-obsidian-blue-setup.conf"
