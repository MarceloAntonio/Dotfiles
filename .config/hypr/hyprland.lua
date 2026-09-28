---@module 'hl'

require("configs.monitors")
require("configs.autostart")
require("configs.windowrules")
require("configs.keybinds")
require("configs.animations")
hl.env("XCURSOR_THEME", "mcmojave-cursors")
hl.env("XCURSOR_SIZE", 24)
hl.env("HYPRCURSOR_THEME", "mcmojave-cursors")
hl.env("HYPRCURSOR_SIZE", 24)
hl.config({
	general = {
		gaps_in = 2,
		gaps_out = 2,
		border_size = 0,
		resize_on_border = false,
		allow_tearing = false,
		layout = "dwindle",
		col = {
			active_border = "rgba(ffffff33)",
			inactive_border = "rgba(ffffff15)",
		},
	},
})

hl.config({
	decoration = {
		rounding = 10,
		rounding_power = 2,
		active_opacity = 1.0,
		inactive_opacity = 0.95,
		shadow = {
			enabled = true,
			range = 6,
			render_power = 3,
			color = "rgba(131313ee)",
		},
		blur = {
			enabled = true,
			size = 4,
			passes = 2,
			vibrancy = 0.1,
		},
	},
})

hl.config({
	master = {
		new_status = "master",
	},
})

hl.config({
	misc = {
		force_default_wallpaper = 0,
		disable_hyprland_logo = true,
		mouse_move_enables_dpms = true,
		key_press_enables_dpms = true,
	},
})
hl.config({
	input = {
		kb_layout = "br",
		follow_mouse = 1,
		sensitivity = 0,
		touchpad = {
			natural_scroll = false,
		},
	},
})

hl.device({
	name = "epic-mouse-v1",
	sensitivity = -0.5,
})
