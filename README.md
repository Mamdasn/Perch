# Notchpop

A quiet meeting companion for macOS and Linux. Hover at the top center of your screen to reveal your current or next meeting. Nothing shows while idle.

- Scroll up or press **↑** for later events; scroll down or press **↓** for earlier ones while the popup is open.
- Click an event title to open it in your calendar app, or **Join** to open its meeting link.
- Try **Load demo meeting** in settings, then return to your calendars.

## Requirements

### Linux

- Python 3.10 or later, PyGObject, Pycairo, GTK 3, gtk-layer-shell, and Evolution Data Server.
- A Wayland compositor that supports layer-shell. Tested on Arch Linux with Niri.
- Calendars configured in GNOME Calendar or Evolution.
- A notch is optional: the popup uses the top center of your display.

GNOME Wayland does not support layer-shell. An X11 fallback is included but has not been tested.

### macOS

- macOS 14 Sonoma or later.
- Apple Silicon or Intel Mac; builds for the Mac you run the build on.
- A notch is optional: other displays use the top center.
- Calendars synced to the macOS Calendar app.

## Quick start

### Linux

Install the dependencies on Arch Linux:

```sh
sudo pacman -S --needed python-gobject python-cairo gtk3 gtk-layer-shell evolution-data-server
```

Then build and install the Linux port:

```sh
git clone --branch linux-port https://github.com/Mamdasn/Notchpop.git
cd Notchpop
bash linux/install.sh
~/.local/bin/notchpop
```

The script checks the dependencies, runs the tests, and installs the app for your user. Installation does not require sudo. Run it again after changing the code, then quit and reopen Notchpop.

Hover for a moment at the top center of your screen. Open **⚙** to select calendars, load a demo meeting, or quit. Click the card before using the arrow keys; press **Escape** to close it. Notchpop reads events locally; it never edits or uploads them.

To build without installing, run `bash build-linux.sh` and launch `dist/notchpop-linux/notchpop-launcher`. The existing `bash build-app.sh` command also builds the Linux version when run on Linux.

Useful launch options:

```sh
~/.local/bin/notchpop --preview-meeting  # preview a meeting in progress
~/.local/bin/notchpop --settings         # open calendar settings
~/.local/bin/notchpop --toggle           # show or hide the popup
~/.local/bin/notchpop --monitor 1        # use the second monitor
~/.local/bin/notchpop --quit
```

Launching again controls the running instance. Calendar selections are saved in `~/.config/notchpop/settings.json`, or under `$XDG_CONFIG_HOME` when set.

To start automatically in Niri, add this to `~/.config/niri/config.kdl`:

```kdl
spawn-at-startup "notchpop"
```

Use the full path to the installed executable if `~/.local/bin` is not in your session's `PATH`.

### macOS

Install Apple's Command Line Tools if needed:

```sh
xcode-select --install
```

After the tools finish installing, run:

```sh
git clone https://github.com/Mamdasn/Notchpop.git
cd Notchpop
bash build-app.sh
```

The script builds and signs the app, quits any running Notchpop, installs it in `/Applications`, and launches it. Run `bash build-app.sh` again after changing the code. Installation requires write access to `/Applications`.

Open **Calendar settings** from the menu-bar icon, click **Connect Calendar**, and grant access. Then hover over the notch. Notchpop reads events locally; it never edits or uploads them.

The build is locally signed, not notarized. Calendar event deep links and multi-display/full-screen behavior may vary across macOS versions.

Calendar access should survive quitting and reopening the same build. The default ad-hoc signature changes when the executable changes, so installing a rebuilt app can require granting access again. Calendar selections are saved separately. To keep a consistent identity across builds, use the same installed signing certificate:

```sh
SIGNING_IDENTITY="Apple Development: Your Name (TEAMID)" bash build-app.sh
```

Switching signing identities may require granting access once more. See [Apple's code-signing requirements](https://developer.apple.com/documentation/technotes/tn3127-inside-code-signing-requirements).

## Linux port

The Linux implementation lives in `linux/notchpop`. It replaces the macOS interface with Python and GTK, uses gtk-layer-shell to position the popup on Wayland, and reads calendars through Evolution Data Server instead of EventKit. The Swift implementation remains available for macOS.

The popup fades into view after a 350 ms hover and closes 250 ms after the pointer leaves. Its invisible hover target is 190 pixels wide and 6 pixels high. That target receives pointer events and can overlap the center of a top panel; the rest of the hidden window lets clicks pass through. Linux uses a fade animation rather than the macOS fluid highlight.

Calendars refresh every minute and cover the previous and next seven days. Evolution Data Server expands recurring events and exceptions using their time zones. All-day and cancelled events are excluded, along with declined events when the calendar identifies your email address.

Event titles use `calendar://` links and need a compatible handler such as Evolution. The handler controls which recurring occurrence opens. Recognized HTTPS conference links open in your default browser.

## Checks

### Linux

Build and run the meeting-selection, calendar-filtering, recurrence, and conference-link tests:

```sh
bash build-linux.sh
```

In a graphical session, check the popup:

```sh
dist/notchpop-linux/notchpop-launcher --smoke-test --preview-meeting
```

On a supported Wayland desktop, also check navigation, settings, and reopening:

```sh
PYTHONPATH=linux python3 linux/tests/check_desktop.py
```

### macOS

```sh
.build/release/Notchpop --self-test
```

## License

[GPL-3.0](LICENSE).
