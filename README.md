# NX Studio on Wine

Run Nikon NX Studio on Linux through Wine, including fixes for Hyprland/XWayland multi-monitor behavior.

This project does **not** redistribute NX Studio. Download the Windows installer directly from Nikon and accept Nikon's license terms yourself.

## Tested configuration

- NX Studio 1.10.1
- Wine Staging 11.17
- Hyprland on Wayland
- Two HiDPI monitors at scale 2
- Arch Linux / Omarchy

Other recent Wine and Hyprland versions may work but have not been verified.

## What the patches fix

Wine exposes several NX Studio implementation windows to XWayland:

- `NX Studio`: the main application window.
- `Export`: a modal dialog which Wine may center across the combined X11 desktop instead of over the active monitor.
- `ImageFrameScreen`: an internal image-rendering helper which can appear as a separate black window.

The included launcher:

1. Runs NX Studio in a dedicated Wine prefix.
2. Keeps the internal `ImageFrameScreen` alive but unmaps its accidental top-level window.
3. Centers the Export dialog relative to the actual NX Studio window, so it works on whichever monitor contains NX Studio.

The optional Hyprland rule maximizes NX Studio to the monitor/workspace where it opens.

## Requirements

Arch Linux:

```sh
sudo pacman -S wine-staging xdotool
```

Also install the 32-bit graphics/audio libraries required by your Wine package. On non-Arch distributions, install equivalent packages for Wine and `xdotool`.

## Install

1. Download the current Windows installer from the [official Nikon Download Center](https://downloadcenter.nikonimglib.com/en/products/564/NX_Studio.html).
2. Clone this repository.
3. Run:

```sh
./install.sh ~/Downloads/S-NXSTDO-*.exe
```

The installer creates or updates:

- Wine prefix: `~/.local/share/nx-studio/prefix`
- Launcher: `~/.local/bin/nx-studio`
- Desktop entry: `~/.local/share/applications/nx-studio.desktop`

The Nikon installer is interactive. Complete it normally. Its bundled Microsoft Visual C++ runtime is supported in the tested prefix.

## Hyprland

Add this window rule after your distribution's default Hyprland configuration:

```lua
o.window({ class = "^nxstudio\\.exe$", title = "^NX Studio.*" }, { maximize = true })
```

Omarchy users can place it near the end of `~/.config/hypr/hyprland.lua`, after `require("default.hypr.omarchy")` and the personal configuration imports. Then validate:

```sh
hyprctl reload
hyprctl configerrors
```

If your configuration does not provide Omarchy's `o.window` helper, translate the match and `maximize` effect to the current native Hyprland window-rule syntax. Hyprland changes this syntax frequently; use the [current window-rule documentation](https://wiki.hypr.land/configuring/core/rules/window-rules/).

## Run

Launch **NX Studio** from the desktop menu or run:

```sh
nx-studio
```

File paths passed to the launcher are forwarded to NX Studio.

## Troubleshooting

### Export dialog still appears off-screen

Confirm the patched launcher is being used:

```sh
command -v nx-studio
```

It should resolve to `~/.local/bin/nx-studio`. `xdotool` must also be installed and XWayland must be enabled.

### Black `ImageFrameScreen` window

The patched launcher detects and unmaps this internal helper. Do not kill it: NX Studio uses it as part of its rendering implementation.

### UI scale

Wine DPI is prefix-specific. Open Wine configuration for this prefix if NX Studio is too large or too small:

```sh
WINEPREFIX="$HOME/.local/share/nx-studio/prefix" winecfg
```

Use the Graphics tab to adjust DPI. The tested HiDPI configuration uses 192 DPI.

### Reset the prefix

This deletes NX Studio's Wine installation and settings:

```sh
rm -rf "$HOME/.local/share/nx-studio/prefix"
```

Then rerun `install.sh` with the Nikon installer. Back up any prefix-local data first.

## Scope

Validated workflows:

- Browse Nikon NEF files.
- Render image previews.
- Maximize NX Studio on a selected monitor.
- Open and interact with the Export dialog on a multi-monitor Hyprland desktop.

Camera transfer, Nikon cloud services, video editing, GPU acceleration, printing, and color-managed production workflows have not been comprehensively validated.

## License

The scripts and documentation in this repository are MIT licensed. Nikon NX Studio is proprietary software owned and licensed by Nikon Corporation and is not included.
