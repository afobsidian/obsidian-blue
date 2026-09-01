echo "Drop the default input group grant"

if id -nG "$USER" | grep -qw input; then
  if rpm -q xpadneo-dkms >/dev/null 2>&1 || rpm -q ydotool >/dev/null 2>&1 ||
    command -v ydotool >/dev/null 2>&1; then
    echo "Keeping $USER in the input group: controller or ydotool support is installed."
  else
    sudo gpasswd -d "$USER" input >/dev/null
    echo "Removed $USER from the input group. Log out and back in to apply."
    omarchy-state set reboot-required
  fi
fi
