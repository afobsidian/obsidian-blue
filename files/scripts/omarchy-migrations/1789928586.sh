echo "Check the ARM Limine recovery setup"
if [[ $(uname -m) == aarch64 && -f ${OMARCHY_LIMINE_CONF:-/etc/default/limine} ]]; then
  echo "ARM Limine recovery requires a Fedora Atomic adaptation; migration remains pending." >&2
  exit 1
fi
