#!/usr/bin/env bash
# Optional visual assets; all downloads/builds stay in a unique temporary folder.
set -Eeuo pipefail
work=$(mktemp -d -t dotfiles-assets.XXXXXXXX)
trap 'rm -rf -- "$work"' EXIT

git clone --depth 1 https://github.com/vinceliuice/WhiteSur-icon-theme.git "$work/WhiteSur-icon-theme"
bash "$work/WhiteSur-icon-theme/install.sh" -a

git clone --depth 1 https://github.com/vinceliuice/McMojave-cursors.git "$work/McMojave-cursors"
(cd "$work/McMojave-cursors" && bash ./install.sh)
for directory in "$HOME/.local/share/icons" "$HOME/.icons"; do
  if [[ -d "$directory/McMojave-cursors" ]]; then
    mkdir -p "$directory/mcmojave-cursors"
    cp -a "$directory/McMojave-cursors/." "$directory/mcmojave-cursors/"
    rm -rf -- "$directory/McMojave-cursors"
  fi
done

# SF Pro is downloaded from Apple, rather than redistributed in the dotfiles.
curl -fL --retry 2 -o "$work/SF-Pro.dmg" https://devimages-cdn.apple.com/design/resources/download/SF-Pro.dmg
7z x "$work/SF-Pro.dmg" -o"$work/dmg" -y >/dev/null
package=$(find "$work/dmg" -type f -name 'SFProFonts.pkg' -print -quit)
[[ -n "$package" ]] || { printf 'Pacote SFProFonts.pkg não encontrado na imagem da Apple.\n' >&2; exit 1; }
7z x "$package" -o"$work/pkg" -y >/dev/null
payload=$(find "$work/pkg" -type f -name Payload -print -quit)
[[ -n "$payload" ]] || { printf 'Payload das fontes SF Pro não encontrado.\n' >&2; exit 1; }
mkdir -p "$work/fonts" "$HOME/.local/share/fonts/sf-pro-display"
(cd "$work/fonts" && gzip -dc "$payload" | cpio -id --quiet)
found=false
while IFS= read -r -d '' font; do
  cp -- "$font" "$HOME/.local/share/fonts/sf-pro-display/"
  found=true
done < <(find "$work/fonts" -type f \( -name 'SF-Pro-Display-*.otf' -o -name 'SF-Pro-Display-*.ttf' \) -print0)
$found || { printf 'Fontes SF Pro Display não encontradas.\n' >&2; exit 1; }
fc-cache -f
