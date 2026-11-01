echo "Stop browsers asking to be the default behind Omarchy's link routing"

for flags_file in "$HOME"/.config/{chromium,chrome,microsoft-edge-stable,brave,brave-origin}-flags.conf; do
  [[ -f $flags_file ]] || continue
  grep -qxF -- '--no-default-browser-check' "$flags_file" && continue

  [[ -n $(tail -c1 "$flags_file") ]] && echo >>"$flags_file"
  echo '--no-default-browser-check' >>"$flags_file"
done

# Machine browser policies are installed by the image; /usr is read-only.
