-- Variables (globals — accessible from required modules)
terminal    = "kitty"
fileManager = "thunar"
browser     = "firefox"
menu        = "~/.config/rofi/launcher.sh"
mainMod     = "SUPER"

require("monitors")
require("appearance")
require("input")
require("keybindings")
require("windowrules")

hl.env("XCURSOR_SIZE",          "24")
hl.env("HYPRCURSOR_SIZE",       "24")
hl.env("QT_QPA_PLATFORMTHEME",  "qt5ct")
-- XDG session vars omitted: Hyprland's native USES_SYSTEMD sets them automatically

hl.on("hyprland.start", function()
    hl.exec_cmd("systemctl --user start hyprland-session.target")
    hl.exec_cmd("waybar")
    hl.exec_cmd("hyprpaper")
    hl.exec_cmd("dunst")
    hl.exec_cmd("/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1")
end)

hl.on("hyprland.shutdown", function()
    hl.exec("systemctl --user stop hyprland-session.target")
end)
