# Notchpop

A quiet macOS notch companion. Hover to see your current or next meeting; scroll up for later events and down for earlier ones. Click an event to open it in Calendar.

## Requirements

- macOS 14 Sonoma or later.
- Apple Silicon or Intel Mac; builds for the Mac you run the build on.
- A notch is optional: other displays use the top center.
- Calendars synced to the macOS Calendar app.

## Build and install

Install Apple's Command Line Tools if needed:

```sh
xcode-select --install
```

Then:

```sh
git clone https://github.com/Mamdasn/Notchpop.git
cd Notchpop
bash build-app.sh
ditto dist/Notchpop.app /Applications/Notchpop.app
open /Applications/Notchpop.app
```

Open **Calendar settings** from the menu-bar icon, click **Connect Calendar**, and grant access. Notchpop reads events locally; it never edits or uploads them. Quit the app before replacing it with a new build.

The build is locally signed, not notarized. Calendar event deep links and multi-display/full-screen behavior may vary across macOS versions.

## Checks

```sh
.build/release/Notchpop --self-test
```

## License

[GPL-3.0](LICENSE).
