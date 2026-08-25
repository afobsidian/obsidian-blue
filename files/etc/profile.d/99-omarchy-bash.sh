[ -n "${BASH_VERSION:-}" ] || return 0
[[ $- == *i* ]] || return 0
source "${OMARCHY_PATH:-/usr/share/omarchy}/default/bash/rc"
