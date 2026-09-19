# NX Studio on Wine

Run Nikon NX Studio on Linux through Wine, including fixes for Hyprland/XWayland multi-monitor behavior.

This project does **not** redistribute NX Studio. Download the Windows installer directly from Nikon and accept Nikon's license terms yourself.

## Tested configuration

- NX Studio 1.10.1
- Wine Staging 11.17
- Microsoft Edge WebView2 Runtime 153.0.4234.32
- Hyprland on Wayland
- Two HiDPI monitors at scale 2
- Arch Linux / Omarchy

Other recent Wine and Hyprland versions may work but have not been verified.

## What the patches fix

The window-placement workarounds below are specifically for NX Studio under Hyprland/XWayland with multiple monitors. They are not general Wine desktop fixes and may be unnecessary under other compositors or a single-monitor setup.

Wine exposes several NX Studio implementation windows to XWayland:

- `NX Studio`: the main application window.
- Modal dialogs such as `Export` and `Options`, which Wine may center across the combined X11 desktop instead of over the active monitor.
- `ImageFrameScreen`: an internal image-rendering helper which can appear as a separate black window.

Two launchers keep the workaround isolated:

- `nx-studio` starts NX Studio directly through Wine. Use this on a single monitor or when the compositor already places Wine windows correctly.
- `nx-studio-hyprland` applies the Hyprland/XWayland multi-monitor workarounds: it unmaps the accidental `ImageFrameScreen` top-level window and centers the known `Export` and `Options` dialogs over the main window. NX Studio also labels popup menus as X11 dialogs, so matching every `_NET_WM_WINDOW_TYPE_DIALOG` would move menus and break pointer hit-testing.

The optional Hyprland rule maximizes NX Studio to the monitor/workspace where it opens.

NX Studio's Nikon ID sign-in and OAuth flow require the **Microsoft Edge WebView2 Runtime**. This is the runtime redistributable, not the WebView2 SDK used by developers. The installer adds the Runtime to the same Wine prefix and applies the per-process Wine compatibility override required by the tested setup.

## Requirements

Arch Linux:

```sh
sudo pacman -S wine-staging
```

The Hyprland multi-monitor launcher additionally requires `xdotool`:

```sh
sudo pacman -S xdotool
```

Also install the 32-bit graphics/audio libraries required by your Wine package. On non-Arch distributions, install equivalent packages for Wine and, when needed, `xdotool`.

## Install

1. Download the current Windows installer from the [official Nikon Download Center](https://downloadcenter.nikonimglib.com/en/products/564/NX_Studio.html).
2. Download the x64 **Evergreen Standalone Installer** for the Microsoft Edge WebView2 Runtime from [Microsoft's official WebView2 page](https://developer.microsoft.com/en-us/microsoft-edge/webview2/).
3. Clone this repository.
4. Run:

```sh
./install.sh \
  ~/Downloads/S-NXSTDO-*.exe \
  ~/Downloads/MicrosoftEdgeWebView2RuntimeInstallerX64.exe
```

The installer creates or updates:

- Wine prefix: `~/.local/share/nx-studio/prefix`
- Launchers: `~/.local/bin/nx-studio` and `~/.local/bin/nx-studio-hyprland`
- Desktop entries: `NX Studio` and `NX Studio (Hyprland Multi-Monitor)`

Only the plain `NX Studio` desktop entry registers as a photo MIME handler. Opening a photo from a file manager therefore uses the launcher without Hyprland-specific workarounds; select the Hyprland entry explicitly when those workarounds are required.

The Nikon installer is interactive. Complete it normally. Its bundled Microsoft Visual C++ runtime is supported in the tested prefix. The WebView2 installer runs silently afterward and is required for the Nikon ID/OAuth login window.

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

Use **NX Studio** or the base command when no window workaround is needed:

```sh
nx-studio
```

On a Hyprland/XWayland multi-monitor setup affected by misplaced dialogs or the black helper window, use **NX Studio (Hyprland Multi-Monitor)** or:

```sh
nx-studio-hyprland
```

Both launchers forward file paths to NX Studio.

## Troubleshooting

### A dialog still appears off-screen

Confirm the Hyprland multi-monitor launcher is being used:

```sh
command -v nx-studio-hyprland
```

It should resolve to `~/.local/bin/nx-studio-hyprland`. `xdotool` and XWayland must be available. The launcher deliberately matches known top-level dialog titles because NX Studio exposes popup menus with the same X11 dialog type.

### Black `ImageFrameScreen` window

The Hyprland multi-monitor launcher detects and unmaps this internal helper. Do not kill it: NX Studio uses it as part of its rendering implementation.

### Nikon ID/OAuth login is blank

The login flow is rendered by Microsoft Edge WebView2. Confirm that the Runtime exists inside the NX Studio prefix:

```sh
find "$HOME/.local/share/nx-studio/prefix/drive_c/Program Files (x86)/Microsoft/EdgeWebView/Application" \
  -name msedgewebview2.exe
```

The tested setup also has this per-application Wine override:

```sh
WINEPREFIX="$HOME/.local/share/nx-studio/prefix" wine reg query \
  'HKCU\Software\Wine\AppDefaults\msedgewebview2.exe' /v Version
```

It should report `win7`. Rerun `install.sh` with both installers to repair a missing Runtime or override.

### Adjustments are not saved or folders cannot be created

NX Studio normally saves non-destructive adjustments beside the source image:

```text
<photo-folder>/NKSC_PARAM/<original-filename>.nksc
```

The source folder must therefore allow the current Linux user to search the directory and create files and subdirectories. Read-only media, root-owned folders, network shares, restrictive ACLs, and filesystems mounted read-only will prevent adjustments from being saved.

Test a prospective photo folder through the same Wine prefix:

```sh
nx-studio-check-folder "$HOME/Pictures"
nx-studio-check-folder "/path/to/photo-folder"
```

The probe creates, reads, and removes a temporary folder and file. It does not modify photos.

The standard folders verified on the reference system are:

- `C:\users\<user>\Pictures` → `~/Pictures`
- `C:\users\<user>\Documents` → `~/Documents`
- `C:\users\<user>\Downloads` → `~/Downloads`
- `C:\users\<user>\Desktop` → `~/` in this Wine prefix

`~/Pictures` is the recommended library root. NX Studio successfully created and updated `NKSC_PARAM` sidecars there through Wine.

NX Studio 1.10.1 can still report `Error Renaming File/Folder` for a writable folder that it currently has open. This is an NX Studio/Wine file-handle behavior, not a Linux permission failure: the same rename succeeds through Wine's `cmd.exe`. Close NX Studio or navigate away from the folder, rename it with the Linux file manager or `mv`, then reopen or refresh NX Studio.

Do not solve permission errors with recursive `chmod 777`. For a Linux-owned folder, restore ownership to the current user and grant only user write access:

```sh
sudo chown -R "$USER:$USER" "/path/to/photo-folder"
chmod -R u+rwX "/path/to/photo-folder"
```

Only run those commands on a folder you own and intend to modify. For removable or network storage, correct its mount options or server permissions instead. System paths such as `/usr`, read-only mounts, and another user's private folders are intentionally not globally writable.

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

Then rerun `install.sh` with both the Nikon and WebView2 installers. Back up any prefix-local data first.

## Scope

Validated workflows:

- Browse Nikon NEF files.
- Render image previews.
- Maximize NX Studio on a selected monitor.
- Open and interact with the Export and Options dialogs on a multi-monitor Hyprland desktop.

Camera transfer, Nikon cloud services, video editing, GPU acceleration, printing, and color-managed production workflows have not been comprehensively validated.

## License

The scripts and documentation in this repository are MIT licensed. Nikon NX Studio is proprietary software owned and licensed by Nikon Corporation and is not included.
