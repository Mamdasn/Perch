# Notchpop

Your next meeting, tucked behind the notch. Hover inside the notch to reveal your current or upcoming event; move away and the card slides out of view.

Works with calendars synced to the macOS Calendar app, including Google and Outlook accounts. Requires **macOS 14 Sonoma or later** on Apple Silicon or Intel. No notch? Use the top center of your display.

## Install

1. Download the **universal ZIP** from the [latest release](https://github.com/Mamdasn/Notchpop/releases/latest).
2. Unzip it and move **Notchpop.app** to **Applications**.
3. Open Notchpop. From its menu-bar icon, choose **Settings → Calendars → Connect Calendar** and allow calendar access.

No build tools are needed. Enable **Launch at login** in **Settings → General** to start Notchpop automatically after restarting your Mac.

The release is not notarized by Apple. If macOS blocks it, use **System Settings → Privacy & Security → Open Anyway** only if you trust the download. See [Apple’s guidance](https://support.apple.com/102445).

## Use

- **Browse events:** scroll up for later events or down for earlier ones. The arrow keys work too while the card is open and notes are collapsed.
- **Open or join:** click the event title to open it in Calendar, or click **Join** to open its meeting link.
- **See the details:** organizer, location, participant count, and your invitation response appear when available. Expand **Notes** to read the agenda; scrolling inside that area scrolls the text.
- **Get a quiet reminder:** a blue-to-green highlight appears during the five minutes before a meeting, unless another meeting is in progress. Toggle **Upcoming meeting highlight** in **Settings → General**.
- **Try a preview:** click **Load Demo Meeting** in **Settings → Calendars**. Your calendar returns when the preview closes.

Notchpop reads events locally; it never edits or uploads them. All-day and declined events stay hidden. Choose which calendars to show in Settings, or use **Disconnect Calendar** in General to stop loading events.

## Build and install from source

Install Apple’s Command Line Tools if needed:

```sh
xcode-select --install
```

Then run:

```sh
git clone https://github.com/Mamdasn/Notchpop.git
cd Notchpop
bash build-app.sh
```

The script builds for your Mac, replaces any existing installation in `/Applications`, and opens Notchpop. It requires write access to `/Applications`. Run it again to install source updates.

To run the checks after building:

```sh
.build/release/Notchpop --self-test
```

## Uninstall

Turn off **Launch at login**, quit Notchpop from its menu-bar menu, and move **Notchpop.app** from Applications to Trash.

## License

[GPL-3.0](LICENSE).
