# Notchpop

An original macOS meeting companion, built from scratch in SwiftUI and AppKit, with a native dark material card and custom vector icon. No Boring Notch source or third-party artwork is used.

## Run

Requires macOS 14+ and the Swift command-line tools. Quit the running version from the Notchpop menu before rebuilding.

```sh
bash build-app.sh
open dist/Notchpop.app
```

Open Calendar settings from the Notchpop menu, click **Connect Calendar**, and allow access in the macOS prompt. macOS calls the required read permission **Full Access**; Notchpop only reads events and never creates, changes, or uploads them. It uses calendars already synced to the macOS Calendar app, including Google or Outlook accounts added there. Select calendars in settings. The renamed app has a new bundle identifier and may need Calendar permission again.

The notch stays completely clear until you hover over it for 0.35 seconds. An ongoing event takes priority; otherwise the next event within seven days is shown. The card shows its title, date/time, calendar, time remaining, and progress for an ongoing meeting. Recognized HTTPS Google Meet, Zoom, Teams, and Webex links in the event URL, location, or notes get a Join button. Otherwise Open launches Calendar. Moving away dismisses the card.

All-day, canceled, and personally declined events are omitted. Other timed events, including solo appointments, are included. Overlapping meetings show the most recently started event with an overlap notice. Event data refreshes every minute, on Calendar changes, and after wake; displayed timing updates every second. Dates follow the Mac’s locale and timezone.

Use **Preview next meeting** or **Preview current meeting** in the Notchpop menu for labeled sample data without granting Calendar permission, then hover over the notch. Select **Back to my calendar** to stop the demo. To load demo data after quitting:

```sh
open dist/Notchpop.app --args --preview-meeting
```

The app chooses a notched screen when available and otherwise uses the top center of the main screen. It needs no camera, screen recording, or accessibility access. Reduce Motion disables the reveal spring.

## Prototype scope

Scroll up over the card for the next event, or down for the previous event. Events are ordered chronologically across the previous and upcoming seven days. The footer shows your position and provides equivalent arrow buttons. Each trackpad gesture advances once; momentum is ignored. Reduce Motion substitutes a fade for the directional slide. Closing and reopening returns to the current/next event (or the latest past event when none are upcoming). Demo mode includes four events for browsing.

Click the meeting title/details or Open to reveal that event in macOS Calendar. Join remains a separate conference action. Event links use the Calendar item identifier and UTC occurrence date; demo events cannot open because they are not saved in Calendar. Calendar’s `ical://ekevent` routing is undocumented by Apple and needs live verification with your synced accounts, particularly recurring events.

The card uses a restrained spring reveal with native macOS material. Reduce Transparency provides an opaque fallback. The app and menu-bar icons share an original notch/calendar mark.

Run `.build/release/Notchpop --self-test` for 13 checks covering idle visibility, hover/dismissal, event priority and time boundaries, elapsed events, progress, and conference-link validation. Calendar authorization and account sync require testing with your Mac’s accounts. Permission is requested only when you click Connect Calendar. macOS may ask again after an ad-hoc rebuild.

The overlay passes through mouse input outside the revealed card. Test full-screen apps, Spaces, menu-bar auto-hide, display scaling, sleep/wake, and external-display changes on your target Macs. Secure system surfaces may cover the overlay. The local build is ad-hoc signed; public distribution needs signing and notarization.
