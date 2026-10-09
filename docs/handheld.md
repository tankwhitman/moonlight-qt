# Handheld UI development

This personal branch builds on Nonary's Moonlight streaming client. It adds a
responsive dark library with large cards and controller prompts, fullscreen
launching for Gamescope, and explicit LAN/Tailscale connection selection.
Existing streaming, codec, calibration, and advanced settings remain available.

## Build on CachyOS / Arch

Install build dependencies using the distro package manager when needed:

```sh
sudo pacman -S --needed base-devel qt6-base qt6-declarative qt6-svg qt6-wayland \
  sdl2-compat sdl2_ttf ffmpeg opus openssl libva libvdpau libdrm libplacebo \
  vulkan-headers wayland-protocols

git submodule update --init --recursive
mkdir -p build-handheld
cd build-handheld
qmake6 ../moonlight-qt.pro CONFIG+=release
make -j4
```

The executable is `build-handheld/app/moonlight`. This is a native development
build, not an AppImage; it uses the system libraries from the build machine.
Use the existing packaging pipeline for a distributable release.

## Add to Steam

Add the executable as a non-Steam game. Set launch options to:

```text
MOONLIGHT_HANDHELD=1 %command%
```

Gamescope display detection (`GAMESCOPE_WAYLAND_DISPLAY`) or Steam's
`STEAM_GAMEPADUI` environment enables fullscreen automatically. The explicit
option avoids depending on how a specific session exposes those variables.
The window fills the compositor's advertised surface, and the library scales
with its logical size. The UI flag does not change streaming resolution;
choose that separately in Moonlight settings. Steam/Gamescope must expose
1920×1080 to the app to render the UI at that resolution.

Use a Steam Input layout exposing a gamepad, rather than a desktop mouse layout.
Moonlight uses its SDL controller navigation: A selects, B returns, X opens
options, and Y/Start opens settings. Prompts follow the face-button swap setting.
Settings use sequential focus navigation. On-screen keyboard buttons use
D-pad navigation and A; B cancels. Focused host name/address and custom
resolution/frame-rate fields open the keyboard with A when a controller is
connected. Touch, mouse, and physical keyboard entry remain available.

## LAN / Tailscale

Select a host and press X → **Connection: LAN / Tailscale**. Enter the host's
LAN IPv4 address and its Tailscale IPv4 address once. An optional `:port`
sets the Moonlight HTTP port (default 47989); HTTPS ports are discovered from
serverinfo as before. Use the built-in IP keypad with **Edit LAN** or
**Edit Tailscale**, or type using a keyboard.

Select **LAN**, **Tailscale**, or **Automatic**, then **Save connection**.
Explicit modes poll only the selected address. If it is unreachable, the
host stays offline rather than quietly connecting through a different route.
Automatic retains Moonlight's existing address fallback behavior. The host's
UUID and pinned pairing certificate are preserved, and responding hosts must
match the existing UUID. Route edits invalidate in-flight polling replies.
The host card and details show the chosen mode and active address.

Tailscale addresses are validated against 100.64.0.0/10. Tailscale must already
be installed, connected, and allowed to reach Sunshine on the host. This UI
does not manage Tailscale login or access rules. IPv6 and DNS hostnames remain
available through Moonlight's existing automatic mode; explicit route fields
currently accept IPv4 addresses only.

Route switching is performed from the host screen before launching a stream.
It does not migrate an active streaming session to another network.

## Checks

```sh
mkdir -p build-connection-tests
cd build-connection-tests
qmake6 ../tests/connection/connection.pro
make -j2
./tst_connectionpolicy
```

Controller navigation: build `tests/qml/controller-navigation.pro` in a separate
build directory and run `QT_QPA_PLATFORM=offscreen ./tst_controllernavigation`.

UI check: build `tests/qml/handheld-ui.pro` separately and run:

```sh
QT_QPA_PLATFORM=offscreen QT_QUICK_CONTROLS_STYLE=Material \
  QT_QUICK_BACKEND=software ./tst_handheldui
```

UI images default to `/tmp/moonlight-handheld-ui-test`; set
`MOONLIGHT_TEST_OUTPUT` to choose another directory. The UI check renders the
actual library/dialog components with sample game data at 1080p and 720p,
then exercises keyboard input, committing text, and restoring navigation mode.
It does not establish successful streaming or native Gamescope behavior.

Initial validation: Linux release build and isolated application startup pass;
connection policy has four behavioral cases; existing controller event tests
pass; the UI keyboard check passes. Live pairing, LAN and Tailscale streaming,
hardware decoding, and Steam/Gamescope focus on the physical Ally still need
manual testing. Sunshine pairing may require entering the PIN on the host.
