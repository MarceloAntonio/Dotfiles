---@module 'hl'

local mod = "SUPER"
local function bind(keys, action, desc, opts)
	opts = opts or {}
	opts.desc = desc
	hl.bind(keys, action, opts)
end
bind(mod .. " + Return", hl.dsp.exec_cmd("kitty"), "Terminal (kitty)")
bind(mod .. " + B", hl.dsp.exec_cmd("firefox"), "Navegador (Firefox)")
bind(mod .. " + E", hl.dsp.exec_cmd("nautilus"), "Arquivos (Nautilus)")
bind(mod .. " + space", hl.dsp.exec_cmd("rofi -show drun"), "Menu de aplicativos")
bind(mod .. " + V", hl.dsp.exec_cmd([[cliphist list | rofi -dmenu -i -no-show-icons -display-columns 2 -theme-str 'entry { placeholder: "Histórico do clipboard..."; }' | cliphist decode | wl-copy]]), "Histórico do clipboard")
bind(mod .. " + Q", hl.dsp.window.close(), "Fechar janela")
bind(mod .. " + Z", hl.dsp.window.float(), "Alternar flutuante")
bind(mod .. " + F", hl.dsp.window.fullscreen_state({ internal = 1, client = -1 }), "Tela cheia")
bind(mod .. " + M", hl.dsp.window.fullscreen("maximized", "toggle"), "Maximizar")
bind(mod .. " + P", hl.dsp.window.pseudo(), "Pseudo tiling")
bind(mod .. " + J", hl.dsp.layout("togglesplit"), "Alternar divisão")
for _, dir in ipairs({ "left", "right", "up", "down" }) do
	bind(mod .. " + " .. dir, hl.dsp.focus({ direction = dir }), dir == "left" and "Mover foco" or nil)
end
bind(mod .. " + mouse:272", hl.dsp.window.drag(), "Mover janela", { mouse = true })
bind(mod .. " + mouse:273", hl.dsp.window.resize(), "Redimensionar janela", { mouse = true })
bind(mod .. " + SHIFT + S", hl.dsp.exec_cmd('grim -g "$(slurp)" - | wl-copy'), "Screenshot de área")
bind(mod .. " + W", hl.dsp.exec_cmd("~/.config/hypr/scripts/theme-changer.sh wallpaper"), "Trocar wallpaper")
bind(mod .. " + T", hl.dsp.exec_cmd("~/.config/hypr/scripts/theme-changer.sh"), "Trocar tema")
bind(mod .. " + L", hl.dsp.exec_cmd("hyprlock"), "Bloquear tela")
for i = 1, 10 do
	local key = i % 10
	bind(mod .. " + " .. key, hl.dsp.focus({ workspace = i }), i == 1 and "Ir para workspace" or nil)
	bind(mod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }), i == 1 and "Mover janela para workspace" or nil)
end
bind(mod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }), "Trocar workspace")
bind(mod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))
local media = {
	XF86AudioRaiseVolume = "wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+",
	XF86AudioLowerVolume = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-",
	XF86AudioMute = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle",
	XF86AudioMicMute = "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle",
	XF86MonBrightnessUp = "brightnessctl -e4 -n2 set 5%+",
	XF86MonBrightnessDown = "brightnessctl -e4 -n2 set 5%-",
	XF86AudioNext = "playerctl next",
	XF86AudioPause = "playerctl play-pause",
	XF86AudioPlay = "playerctl play-pause",
	XF86AudioPrev = "playerctl previous",
}
for key, cmd in pairs(media) do
	bind(key, hl.dsp.exec_cmd(cmd), key == "XF86AudioRaiseVolume" and "Volume / brilho / player" or nil, { locked = true })
end
