-- AUTOSTART --
hl.on("hyprland.start", function () 
    hl.exec_cmd("hyprpaper")
	hl.exec_cmd("qs")
	hl.exec_cmd("fcitx5 -d")
	hl.exec_cmd("systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
	hl.exec_cmd("systemctl --user start cliphist.service")
	hl.exec_cmd("systemctl --user start hypridle.service")
end)
