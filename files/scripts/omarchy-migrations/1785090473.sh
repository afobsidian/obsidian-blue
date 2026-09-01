echo "Keep Fedora fingerprint support"

if rpm -q libfprint-git >/dev/null 2>&1; then
  echo "libfprint-git is not supported by the Fedora image." >&2
  exit 1
fi

if rpm -q fprintd >/dev/null 2>&1 && ! rpm -q libfprint >/dev/null 2>&1; then
  echo "The Fedora image is missing libfprint." >&2
  exit 1
fi
