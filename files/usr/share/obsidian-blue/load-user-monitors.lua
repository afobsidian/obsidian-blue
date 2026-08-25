local home = os.getenv("HOME") or ""
local config_home = os.getenv("XDG_CONFIG_HOME") or home .. "/.config"
local user_monitors = loadfile(config_home .. "/omarchy/hypr/monitors.lua")

if user_monitors then user_monitors() end
