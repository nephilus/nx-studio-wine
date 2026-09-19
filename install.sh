#!/bin/sh
set -eu

usage() {
  printf 'Usage: %s NX-Studio-installer.exe WebView2-Runtime-installer.exe\n' "$0" >&2
  exit 2
}

[ "$#" -eq 2 ] || usage
installer=$1
webview2_installer=$2
for file in "$installer" "$webview2_installer"; do
  [ -f "$file" ] || {
    printf 'Installer not found: %s\n' "$file" >&2
    exit 1
  }
done

for command in wine wineboot; do
  command -v "$command" >/dev/null 2>&1 || {
    printf 'Required command not found: %s\n' "$command" >&2
    exit 127
  }
done

repo_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
prefix=${NX_STUDIO_WINEPREFIX:-$HOME/.local/share/nx-studio/prefix}
launcher_dir=$HOME/.local/bin
desktop_dir=$HOME/.local/share/applications

mkdir -p "$prefix" "$launcher_dir" "$desktop_dir"
export WINEPREFIX=$prefix
export WINEARCH=win64

wineboot -u
winecfg -v win11
wine "$installer"

# NX Studio's Nikon ID/OAuth window embeds Microsoft Edge WebView2.
# Keep the prefix on Windows 11 while using Wine's per-app compatibility
# override for the WebView2 process.
wine reg add 'HKCU\Software\Wine\AppDefaults\msedgewebview2.exe' \
  /v Version /t REG_SZ /d win7 /f
wine "$webview2_installer" /silent /install

nx_exe="$prefix/drive_c/Program Files/Nikon/NXStudio/NXStudio.exe"
if [ ! -f "$nx_exe" ]; then
  printf '%s\n' 'NX Studio executable was not found after installation.' >&2
  exit 1
fi
webview2_root="$prefix/drive_c/Program Files (x86)/Microsoft/EdgeWebView/Application"
if ! find "$webview2_root" -name msedgewebview2.exe -print -quit 2>/dev/null | grep -q .; then
  printf '%s\n' 'Microsoft Edge WebView2 Runtime was not found after installation.' >&2
  exit 1
fi

install -m 0755 "$repo_dir/scripts/nx-studio" "$launcher_dir/nx-studio"
install -m 0755 "$repo_dir/scripts/nx-studio-hyprland" \
  "$launcher_dir/nx-studio-hyprland"
install -m 0755 "$repo_dir/scripts/check-folder-permissions" \
  "$launcher_dir/nx-studio-check-folder"
install -m 0644 "$repo_dir/packaging/nx-studio.desktop" "$desktop_dir/nx-studio.desktop"
install -m 0644 "$repo_dir/packaging/nx-studio-hyprland.desktop" \
  "$desktop_dir/nx-studio-hyprland.desktop"

if command -v update-desktop-database >/dev/null 2>&1; then
  update-desktop-database "$desktop_dir"
fi

printf 'NX Studio installed. Launch normally with: %s/nx-studio\n' "$launcher_dir"
printf 'Hyprland multi-monitor fixes: %s/nx-studio-hyprland\n' "$launcher_dir"
