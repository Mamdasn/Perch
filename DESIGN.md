# Notchpop design update

SwiftUI handles content and native material; AppKit handles the nonactivating overlay and menu bar. This keeps focus in the user's current application while preserving native Calendar permissions and settings.

The idle overlay has no visible content. A 350 ms hover reveals a 360 × 242 pt meeting card; leaving dismisses it after a 250 ms grace period. Demo commands only select sample data, and do not reveal the card. Launch no longer opens settings automatically.

The cream surface, cartoon mascot, heavy outlines, tilted layout, and persistent badge have been removed. The new surface uses dark native material, a subtle one-point border, system typography, a single primary action, and green only to indicate an ongoing event. Reduce Transparency uses an opaque system background; Reduce Motion uses a brief fade. The icon is a shared original vector mark rendered as a template menu icon and a full-resolution macOS app icon.

Files: `Sources/Notchpop/main.swift` (overlay), `Meetings.swift` (content), `BrandIcon.swift` (identity), `scripts/RenderIcon.swift` (icon assets). Build with `bash build-app.sh`; check behavior with `.build/release/Notchpop --self-test`.

This is intentionally a notch utility rather than a general-purpose window. Remaining validation: VoiceOver, keyboard-only overlay operation, full-screen Spaces, multiple displays, high contrast and account-specific Calendar behavior. Those are not certified by the automated checks.
