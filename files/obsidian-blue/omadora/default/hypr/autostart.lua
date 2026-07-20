-- Slow app launch fix -- set systemd vars.
o.exec_on_start("systemctl --user import-environment $(env | cut -d'=' -f 1)")
o.exec_on_start("dbus-update-activation-environment --systemd --all")

-- obsidian-blue starts Hyprland directly, so provide the session anchor that
-- UWSM would normally activate.
o.exec_on_start(
  "sh -c 'systemctl --user cat obsidian-blue-session.target >/dev/null 2>&1 && systemctl --user start obsidian-blue-session.target || true'"
)

-- Start the Omadora services.
o.exec_on_start("systemctl --user start omadora-session.target")

-- Run post-boot hooks after startup config has loaded.
o.exec_on_start("sleep 2 && omadora-exec omadora-hook post-boot")
