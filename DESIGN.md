# Notchpop design

General includes “Upcoming meeting highlight,” enabled by default and persisted with AppStorage. Turning it off immediately hides the pre-meeting reminder without changing hover feedback or popup behavior.

When no meeting is in progress, the nearest upcoming meeting gets a subtle reminder during its final five minutes: a 0.75 pt gradient edge along the notch's sides and bottom, or a 72 × 0.75 pt top-center line without a notch. A faint glow fades outward to full transparency over 6 pt. Color progresses from blue to green with wall-clock time, without pulsing or opening the popup. The reminder disappears at the start time and ignores demo data. Reduce Transparency removes the glow; increased contrast strengthens the edge to 1.5 pt. `MeetingReminder.swift` contains timing and rendering.

Settings uses a 480 × 460 pt native tabbed window. Calendars contains a scrollable checkbox list, a refresh action, and a Preview group available before and after Calendar setup. Load demo meeting opens a temporary sample immediately and keeps the same label. It waits up to eight seconds for the pointer; once entered, normal hover dismissal applies. Closing the preview restores calendar data. General contains startup settings. Connected users see calendar controls rather than onboarding copy.

Launch at login is an opt-in setting backed by `SMAppService.mainApp` in `LoginSettings.swift`. It reflects macOS registration status, offers a System Settings link when approval is needed, and surfaces registration errors. No helper or LaunchAgent is required. Actual login after a restart remains a manual validation step.

SwiftUI handles content and native material; AppKit handles the nonactivating overlay and menu bar. The panel becomes key when the popup opens to receive arrow keys, and relinquishes key status when dismissed. Keyboard handling is local to the panel; modified arrow shortcuts pass through.

The idle overlay has no visible content. A 350 ms hover reveals a compact 336 × 234 pt meeting card with 18 pt padding and a two-line, 19 pt title; leaving dismisses it after a 250 ms grace period. Displays without a notch use the top center. Settings preview reveals the card automatically; menu-bar demo commands only select sample data. Launch does not open settings automatically.

The surface uses dark native material, a subtle one-point border, system typography, and green to indicate an ongoing event. The icon is a shared original vector mark rendered as a template menu icon and a full-resolution macOS app icon.

The current meeting takes priority, otherwise the next meeting is featured. Scroll up or press Up for later events; scroll down or press Down for earlier ones. Chevron buttons use the same navigation handler and boundaries, with no wrapping. Event changes use a short vertical slide and fade; scroll momentum is ignored. Clicking an event title opens its Calendar event; Join opens its conference link.

The popup rolls down from the display's top edge in 320 ms, settles 18 pt below the notch, and retreats above the display on dismissal. Clipping applies at the screen edge rather than below the notch. A delicate hover outline grows from 2.5% to 8% opacity. A single centered Bézier bridge stretches toward the card, thins, and fades. A ring made from two rounded rectangles expands upward with the lag between card and fluid progress, then settles over 480 ms. This is a simple visual approximation, without particles or sampled perimeter waves. Card and fluid timing are independent.

The trail uses 9% opacity before fading, the rim 8%, and its soft shadow 2%. These are layer opacities, not final composited pixel measurements. Reduce Motion removes the trail and uses a settled rim and brief fades. Reduce Transparency uses an opaque system background and disables fluid blur and glow. Increased contrast strengthens the base border. Decorative layers ignore pointer input and are hidden from accessibility.

Files under `Sources/Notchpop`: `main.swift` (overlay, focus, and settings), `Meetings.swift` (Calendar data and content), `MeetingPager.swift` (shared scrolling and keyboard navigation), `LiquidHighlight.swift` (bridge and rim), and `BrandIcon.swift` (identity). `scripts/RenderIcon.swift` renders icon assets; `scripts/InspectTrail.swift` previews trail geometry. Build with `bash build-app.sh`; check behavior with `.build/release/Notchpop --self-test`.

Calendar exclusions persist in UserDefaults. Calendar permission is managed by macOS and read at launch; it is not an app-owned connection flag. The default ad-hoc signature is tied to the executable's hash, so rebuilt installations can require fresh permission. `SIGNING_IDENTITY` allows builds to use a consistent installed signing certificate. See [Apple's signing requirements](https://developer.apple.com/documentation/technotes/tn3127-inside-code-signing-requirements).

The 22 automated checks cover hover state, event selection, links, and navigation boundaries. They do not verify rendered animation or keyboard focus delivery. Remaining manual validation: VoiceOver, keyboard interaction and focus restoration, full-screen Spaces, multiple displays, accessibility display settings, and account-specific Calendar behavior.
