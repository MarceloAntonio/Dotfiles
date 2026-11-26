---@module 'hl'

local mod = "SUPER"
-- Descrições no idioma do sistema; o seletor de idioma da Central roda `hyprctl reload`.
local locale = io.open("/etc/locale.conf")
local en = locale ~= nil and (locale:read("a"):match("LANG=en") ~= nil)
if locale then locale:close() end
local function tr(pt, english) return en and english or pt end
local function bind(keys, action, desc, opts)
  opts = opts or {}
  opts.desc = desc
  hl.bind(keys, action, opts)
end
bind(mod .. " + Return", hl.dsp.exec_cmd("kitty"), "Terminal (kitty)")
bind(mod .. " + B", hl.dsp.exec_cmd("firefox"), tr("Navegador (Firefox)", "Browser (Firefox)"))
bind(mod .. " + E", hl.dsp.exec_cmd("nautilus --new-window"), tr("Arquivos (Nautilus)", "Files (Nautilus)"))
bind(mod .. " + space", hl.dsp.exec_cmd("~/.config/hypr/scripts/launcher.sh"), tr("Menu de aplicativos", "Application menu"))
bind(mod .. " + V",
  hl.dsp.exec_cmd(
  [[cliphist list | rofi -dmenu -i -no-show-icons -display-columns 2 -theme-str 'entry { placeholder: "]] .. tr("Histórico do clipboard...", "Clipboard history...") .. [["; }' | cliphist decode | wl-copy]]),
  tr("Histórico do clipboard", "Clipboard history"))
bind(mod .. " + Q", hl.dsp.window.close(), tr("Fechar janela", "Close window"))
bind(mod .. " + Z", hl.dsp.window.float(), tr("Alternar flutuante", "Toggle floating"))
bind(mod .. " + F", hl.dsp.window.fullscreen_state({ internal = 1, client = -1 }), tr("Tela cheia", "Fullscreen"))
bind(mod .. " + M", hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }), tr("Alternar tela cheia", "Toggle fullscreen"))
bind(mod .. " + P", hl.dsp.window.pseudo(), "Pseudo tiling")
bind(mod .. " + J", hl.dsp.layout("togglesplit"), tr("Alternar divisão", "Toggle split"))
for _, dir in ipairs({ "left", "right", "up", "down" }) do
  bind(mod .. " + " .. dir, hl.dsp.focus({ direction = dir }), dir == "left" and tr("Mover foco", "Move focus") or nil)
end
bind(mod .. " + mouse:272", hl.dsp.window.drag(), tr("Mover janela", "Move window"), { mouse = true })
bind(mod .. " + mouse:273", hl.dsp.window.resize(), tr("Redimensionar janela", "Resize window"), { mouse = true })
bind(mod .. " + SHIFT + S", hl.dsp.exec_cmd("~/.config/hypr/scripts/screenshot.sh"), tr("Screenshot de área", "Area screenshot"))
bind(mod .. " + W", hl.dsp.exec_cmd("~/.config/hypr/scripts/theme-changer.sh wallpaper"), tr("Trocar wallpaper", "Change wallpaper"))
bind(mod .. " + L", hl.dsp.exec_cmd(os.getenv("HOME") .. "/.local/bin/rice-lock"), tr("Bloquear tela", "Lock screen"))
bind(mod .. " + SHIFT + D", hl.dsp.exec_cmd("qs -c control-center ipc call monitors open"), tr("Configurar monitores", "Configure monitors"))
bind(mod .. " + C", hl.dsp.exec_cmd("qs -c control-center ipc call control toggle geral"), tr("Central de controle", "Control center"))
for i = 1, 10 do
  local key = i % 10
  bind(mod .. " + " .. key, hl.dsp.focus({ workspace = i }), i == 1 and tr("Ir para workspace", "Go to workspace") or nil)
  bind(mod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }),
    i == 1 and tr("Mover janela para workspace", "Move window to workspace") or nil)
end
bind(mod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }), tr("Trocar workspace", "Switch workspace"))
bind(mod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))
local media = {
  XF86AudioRaiseVolume = "~/.config/hypr/scripts/qs-media.sh volume-up",
  XF86AudioLowerVolume = "~/.config/hypr/scripts/qs-media.sh volume-down",
  XF86AudioMute = "~/.config/hypr/scripts/qs-media.sh mute",
  XF86AudioMicMute = "~/.config/hypr/scripts/qs-media.sh mic-mute",
  XF86MonBrightnessUp = "~/.config/hypr/scripts/qs-media.sh brightness-up",
  XF86MonBrightnessDown = "~/.config/hypr/scripts/qs-media.sh brightness-down",
  XF86AudioNext = "playerctl next",
  XF86AudioPause = "playerctl play-pause",
  XF86AudioPlay = "playerctl play-pause",
  XF86AudioPrev = "playerctl previous",
}
for key, cmd in pairs(media) do
  bind(key, hl.dsp.exec_cmd(cmd), key == "XF86AudioRaiseVolume" and tr("Volume / brilho / player", "Volume / brightness / player") or nil, { locked = true })
end
