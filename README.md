# Notchpop for Linux

Your next meeting, at the top of your screen. Hover at the top center to reveal your current or upcoming event; move away and the card fades out of view.

This branch contains the Linux port. For macOS downloads and instructions, see [Notchpop for macOS](https://github.com/Mamdasn/Notchpop/tree/main).

## Requirements

- Python 3.10 or later, PyGObject, Pycairo, GTK 3, gtk-layer-shell, and Evolution Data Server.
- A Wayland desktop with layer-shell support. The port has been tested on Arch Linux with Niri.
- Calendars configured in GNOME Calendar or Evolution.

A notch is not required. GNOME Wayland does not support layer-shell; the included X11 fallback is untested.

## Build and install

On Arch Linux, install the dependencies:

```sh
sudo pacman -S --needed python-gobject python-cairo gtk3 gtk-layer-shell evolution-data-server
```

Then run:

```sh
git clone --branch linux-port https://github.com/Mamdasn/Notchpop.git
cd Notchpop
bash linux/install.sh
~/.local/bin/notchpop
```

The installer checks dependencies, runs tests, and installs the app for your user without sudo. It also adds Notchpop to your application menu. To install source updates, rerun the installer, then quit and reopen the app.

## Use

- **Reveal your meeting:** hover briefly at the top center of your screen.
- **Browse events:** scroll up for later events or down for earlier ones. Click the card to use **↑** and **↓**; press **Escape** to close it.
- **Open or join:** click the event title to open it in a compatible calendar app such as Evolution, or click **Join** to open its meeting link.
- **Choose calendars or try a demo:** open **⚙** on the card. You can also quit from there.

Notchpop reads events locally; it never edits or uploads them. Calendars refresh every minute and cover the previous and next seven days. All-day and cancelled events are hidden, as are declined events when your calendar identifies your email address.

The Linux port uses a fade animation rather than the macOS fluid highlight. Its small hover target can overlap the center of a desktop panel. Opening a specific recurring occurrence depends on your calendar app.

## Start at login

In Niri, add this line to `~/.config/niri/config.kdl`:

```kdl
spawn-at-startup "notchpop"
```

Use the full path to `~/.local/bin/notchpop` if that directory is not in your session’s `PATH`. On other supported desktops, add the executable to your desktop’s startup applications.

## Launch options

```sh
~/.local/bin/notchpop --settings         # open settings
~/.local/bin/notchpop --preview-meeting  # show a demo meeting
~/.local/bin/notchpop --toggle           # show or hide the card
~/.local/bin/notchpop --monitor 1        # use the second monitor
~/.local/bin/notchpop --quit
```

Launching again controls the running instance. Calendar selections are saved in `~/.config/notchpop/settings.json`, or under `$XDG_CONFIG_HOME` when set.

## Build without installing

```sh
bash build-linux.sh
dist/notchpop-linux/notchpop-launcher
```

The build runs the automated tests. In a supported graphical session, run the desktop checks with:

```sh
dist/notchpop-linux/notchpop-launcher --smoke-test --preview-meeting
PYTHONPATH=linux python3 linux/tests/check_desktop.py
```

## Uninstall

Remove any startup entry and quit Notchpop. Delete `~/.local/bin/notchpop`, `~/.local/share/notchpop`, and `~/.local/share/applications/notchpop.desktop`. If you set `$XDG_DATA_HOME`, use that directory instead of `~/.local/share`.

## License

[GPL-3.0](LICENSE).
