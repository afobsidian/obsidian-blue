echo "Keep Kvantum out of the Fedora image"

for package in kvantum-qt5 kvantum; do
  if rpm -q "$package" >/dev/null 2>&1; then
    echo "Remove image package '$package' through the recipe." >&2
    exit 1
  fi
done
