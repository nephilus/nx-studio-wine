#!/bin/sh
set -eu

usage() {
  printf 'Usage: %s /path/to/NX-Studio-installer.exe\n' "$0" >&2
  exit 2
}

[ "$#" -eq 1 ] || usage
installer=$1
[ -f "$installer" ] || {
  printf 'Installer not found: %s\n' "$installer" >&2
  exit 1
}

for command in wine wineboot xdotool; do
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

nx_exe="$prefix/drive_c/Program Files/Nikon/NXStudio/NXStudio.exe"
if [ ! -f "$nx_exe" ]; then
  printf '%s\n' 'NX Studio executable was not found after installation.' >&2
  exit 1
fi

install -m 0755 "$repo_dir/scripts/nx-studio" "$launcher_dir/nx-studio"
install -m 0644 "$repo_dir/packaging/nx-studio.desktop" "$desktop_dir/nx-studio.desktop"

if command -v update-desktop-database >/dev/null 2>&1; then
  update-desktop-database "$desktop_dir"
fi

printf 'NX Studio installed. Launch it with: %s/nx-studio\n' "$launcher_dir"
