echo "Verify the Fedora power profiles daemon"
if [[ $(uname -m) == aarch64 ]]; then
  echo "ARM CPPC power profiles require a Fedora Atomic adaptation; migration remains pending." >&2
  exit 1
fi
rpm -q power-profiles-daemon >/dev/null
