# Notchpop

A quiet macOS notch companion. Hover to reveal your current or next meeting with a subtle fluid highlight. When no meeting is in progress, the final five minutes before the next meeting bring a thin blue-to-green highlight around the notch—or a small top-center line on displays without a notch. It disappears when the meeting starts.

- Scroll up or press **↑** for later events; scroll down or press **↓** for earlier ones while the popup is open.
- Toggle **Upcoming meeting highlight** under **Settings → General** to enable or disable the five-minute reminder. Your choice is saved.
- **Disconnect Calendar** under **Settings → General** stops loading events until you reconnect in Calendars, including after restarting the app. It does not revoke macOS Calendar permission.
- While that setting is off, rest your pointer over it to preview the blue-to-green transition in five seconds. It loops while hovered and finishes the current cycle when you move away.
- Click an event title to open it in Calendar, or **Join** to open its meeting link.
- Organizer names and initials appear on the event card when available.
- Click **Load Demo Meeting** under **Settings → Calendars** to show a sample immediately. Move your pointer just below the notch to explore it. Your calendar returns automatically when the preview closes.

## Requirements

- macOS 14 Sonoma or later.
- Apple Silicon or Intel Mac; builds for the Mac you run the build on.
- A notch is optional: other displays use the top center.
- Calendars synced to the macOS Calendar app.

## Quick start

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

Open **Settings** from the menu-bar icon, click **Connect Calendar**, and grant access. Then hover over the notch. Notchpop reads events locally; it never edits or uploads them.

The build is locally signed, not notarized. Calendar event deep links and multi-display/full-screen behavior may vary across macOS versions.

Calendar access should survive quitting and reopening the same build. The default ad-hoc signature changes when the executable changes, so installing a rebuilt app can require granting access again. Calendar selections are saved separately. To keep a consistent identity across builds, use the same installed signing certificate:

```sh
SIGNING_IDENTITY="Apple Development: Your Name (TEAMID)" bash build-app.sh
```

Switching signing identities may require granting access once more. See [Apple's code-signing requirements](https://developer.apple.com/documentation/technotes/tn3127-inside-code-signing-requirements).

## After restarting your Mac

Enable **Launch at login** in Notchpop's menu-bar **Settings** to open it automatically when you sign in. If approval is required, click **Open Login Items Settings**. You do not need to reinstall or rebuild after restarting. Turn the toggle off to disable automatic launch. To uninstall, disable it, quit Notchpop, and move `/Applications/Notchpop.app` to Trash.

## Checks

```sh
.build/release/Notchpop --self-test
```

## License

[GPL-3.0](LICENSE).
