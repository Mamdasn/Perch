import AppKit
import SwiftUI

enum Mood { case hidden, peek, open }

final class NotchState: ObservableObject {
    @Published var mood: Mood = .hidden
    @Published var topInset: CGFloat = 32
    @Published var notchWidth: CGFloat = 190
    @Published var hoverProgress: CGFloat = 0
    var enteredAt: Date?
    var leftAt: Date?

    static func dwellProgress(elapsed: TimeInterval) -> CGFloat {
        CGFloat(min(1, max(0, elapsed / 0.35)))
    }

    func tick(now: Date, near: Bool, inside: Bool) {
        if near || (inside && mood == .open) {
            leftAt = nil
            if enteredAt == nil { enteredAt = now }
            let progress = Self.dwellProgress(elapsed: now.timeIntervalSince(enteredAt!))
            if hoverProgress != progress { hoverProgress = progress }
            let next: Mood = now.timeIntervalSince(enteredAt!) >= 0.35 ? .open : .peek
            if mood != next { mood = next }
        } else {
            enteredAt = nil
            if hoverProgress != 0 { hoverProgress = 0 }
            if mood == .peek { mood = .hidden }
            if leftAt == nil { leftAt = now }
            if now.timeIntervalSince(leftAt!) >= 0.25 && mood != .hidden { mood = .hidden }
        }
    }

}

final class OverlayPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    let state = NotchState()
    let meetings = MeetingStore()
    var panel: OverlayPanel!
    var statusItem: NSStatusItem!
    var pulse: Timer?
    var notchRect = NSRect.zero
    var settings: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        panel = OverlayPanel(contentRect: .zero, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = false
        panel.hidesOnDeactivate = false
        panel.level = .statusBar
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isReleasedWhenClosed = false
        panel.contentView = NSHostingView(rootView: NotchView(state: state, meetings: meetings, openSettings: { [weak self] in self?.showSettings() }))
        positionPanel()
        panel.orderFrontRegardless()

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem.button?.image = BrandIcon.menuImage
        let menu = NSMenu()
        for (title, action) in [("Settings…", #selector(showSettings)), ("Preview next meeting", #selector(demo)), ("Preview current meeting", #selector(demoCurrent)), ("Back to my calendar", #selector(endDemo)), ("Quit Notchpop", #selector(quit))] {
            let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
            item.target = self
            menu.addItem(item)
        }
        statusItem.menu = menu
        NotificationCenter.default.addObserver(self, selector: #selector(positionPanel), name: NSApplication.didChangeScreenParametersNotification, object: nil)
        pulse = Timer(timeInterval: 1.0 / 30, repeats: true) { [weak self] _ in self?.update() }
        RunLoop.main.add(pulse!, forMode: .common)
        meetings.start()
        if CommandLine.arguments.contains("--preview-meeting") {
            demoCurrent()
        }
    }

    @objc func positionPanel() {
        guard let screen = NSScreen.screens.first(where: { $0.safeAreaInsets.top > 0 }) ?? NSScreen.main else { return }
        let top = screen.frame.maxY
        if let left = screen.auxiliaryTopLeftArea, let right = screen.auxiliaryTopRightArea {
            notchRect = NSRect(x: left.maxX, y: top - screen.safeAreaInsets.top, width: right.minX - left.maxX, height: screen.safeAreaInsets.top)
        } else {
            notchRect = NSRect(x: screen.frame.midX - 95, y: top - 28, width: 190, height: 28)
        }
        state.topInset = notchRect.height
        state.notchWidth = notchRect.width
        panel.setFrame(NSRect(x: notchRect.midX - 230, y: top - 340, width: 460, height: 340), display: true)
    }

    func update() {
        let mouse = NSEvent.mouseLocation
        let near = notchRect.insetBy(dx: -8, dy: -8).contains(mouse)
        // Only the visible card receives clicks; the menu bar and transparent margins pass through.
        let cardRect = NSRect(x: notchRect.midX - 168, y: notchRect.minY - 252, width: 336, height: 252)
        let inside = cardRect.contains(mouse)
        let wasOpen = state.mood == .open
        state.tick(now: Date(), near: near, inside: inside)
        if state.mood == .open && !wasOpen {
            panel.makeKey()
        } else if state.mood != .open && wasOpen && panel.isKeyWindow {
            panel.resignKey()
        }
        panel.ignoresMouseEvents = !(inside && state.mood == .open)
    }

    @objc func demo() { meetings.demo(current: false) }
    @objc func demoCurrent() { meetings.demo(current: true) }
    @objc func endDemo() { meetings.endDemo() }
    @objc func quit() { NSApp.terminate(nil) }
    @objc func showSettings() {
        if settings == nil {
            let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 440, height: 480), styleMask: [.titled, .closable], backing: .buffered, defer: false)
            window.title = "Notchpop"
            window.isReleasedWhenClosed = false
            window.contentView = NSHostingView(rootView: SettingsView(store: meetings, preview: { [weak self] in self?.demo() }))
            window.center()
            settings = window
        }
        NSApp.activate(ignoringOtherApps: true)
        settings?.makeKeyAndOrderFront(nil)
    }
}

struct NotchView: View {
    @ObservedObject var state: NotchState
    @ObservedObject var meetings: MeetingStore
    var openSettings: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorSchemeContrast) private var contrast
    @State private var liquidProgress: CGFloat = 0
    @State private var milkProgress: CGFloat = 0
    private let edgeColor = Color(red: 0.83, green: 0.94, blue: 0.96)

    private func highlightEdge(radius: CGFloat, intensity: Double) -> some View {
        RoundedRectangle(cornerRadius: radius, style: .continuous)
            .strokeBorder(edgeColor.opacity(intensity), lineWidth: 1)
            .shadow(color: edgeColor.opacity(reduceTransparency ? 0 : intensity * 0.22), radius: 3)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }

    var body: some View {
        ZStack(alignment: .top) {
            if state.mood == .open {
                TimelineView(.periodic(from: .now, by: 1)) { timeline in
                    MeetingPager(store: meetings, now: timeline.date, openSettings: openSettings)
                }
                .padding(18)
                .frame(width: 336, height: 234, alignment: .topLeading)
                .background {
                    if reduceTransparency {
                        RoundedRectangle(cornerRadius: 22, style: .continuous).fill(Color(nsColor: .windowBackgroundColor))
                    } else {
                        NotchMaterial().clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                    }
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .strokeBorder(.white.opacity(contrast == .increased ? 0.18 : 0.035), lineWidth: 1)
                }
                .overlay { MilkRim(progress: reduceMotion ? 1 : milkProgress, reveal: reduceMotion ? 1 : liquidProgress, reducedTransparency: reduceTransparency) }
                .shadow(color: .black.opacity(0.28), radius: 18, y: 10)
                // Clip at the screen edge, not at the card's resting position.
                .offset(y: state.topInset + 18 - (reduceMotion ? 0 : (state.topInset + 292) * (1 - liquidProgress)))
                .transition(reduceMotion ? .opacity : .asymmetric(insertion: .identity, removal: .offset(y: -(state.topInset + 292))))
            }
        }
        .frame(width: 460, height: 340, alignment: .top)
        .clipped()
        .overlay(alignment: .top) {
            if state.mood == .peek {
                highlightEdge(radius: 10, intensity: 0.025 + Double(state.hoverProgress) * 0.055)
                    .frame(width: state.notchWidth + 4, height: state.topInset + 2)
            } else if state.mood == .open && !reduceMotion {
                LiquidBridge(progress: milkProgress, reveal: liquidProgress, inset: state.topInset)
                    .fill(edgeColor.opacity(0.09))
                    .blur(radius: reduceTransparency ? 0 : 0.7)
                    .opacity(max(0, 1 - milkProgress * 1.8))
                    .allowsHitTesting(false).accessibilityHidden(true)
            }
        }
        .environment(\.colorScheme, .dark)
        .animation(.easeInOut(duration: reduceMotion ? 0.12 : 0.32), value: state.mood)
        .task(id: state.mood) {
            if state.mood == .open {
                withAnimation(reduceMotion ? nil : .timingCurve(0.22, 0.55, 0.25, 1, duration: 0.32)) {
                    liquidProgress = 1
                }
                withAnimation(reduceMotion ? nil : .linear(duration: 0.48)) {
                    milkProgress = 1
                }
            } else if state.mood == .peek {
                var transaction = Transaction()
                transaction.disablesAnimations = true
                withTransaction(transaction) { liquidProgress = 0; milkProgress = 0 }
            }
        }
    }
}

struct NotchMaterial: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = .hudWindow
        view.blendingMode = .behindWindow
        view.state = .active
        view.appearance = NSAppearance(named: .darkAqua)
        return view
    }
    func updateNSView(_ view: NSVisualEffectView, context: Context) {}
}

struct PillStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.system(size: 12, weight: .semibold))
            .padding(.horizontal, 14).padding(.vertical, 9)
            .foregroundStyle(.primary)
            .background(.primary.opacity(configuration.isPressed ? 0.2 : 0.1), in: RoundedRectangle(cornerRadius: 9))
            .contentShape(RoundedRectangle(cornerRadius: 9))
    }
}
struct SettingsView: View {
    @ObservedObject var store: MeetingStore
    var preview: () -> Void
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Your day. At a glance.").font(.system(size: 23, weight: .semibold))
            Text("Your current meeting comes first. Otherwise, Notchpop finds the next event in the coming 7 days.").foregroundStyle(.secondary)
            LoginSettings()
            Divider()
            if store.connected {
                Text("Show events from").font(.headline)
                ScrollView {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(store.calendars) { calendar in
                            Toggle(calendar.title, isOn: Binding(get: { !store.excluded.contains(calendar.id) }, set: { store.setEnabled($0, id: calendar.id) }))
                        }
                        if store.calendars.isEmpty { Text("Add an account in the macOS Calendar app, then refresh.").foregroundStyle(.secondary) }
                    }.frame(maxWidth: .infinity, alignment: .leading)
                }
                Button("Refresh calendars") { store.endDemo() }
            } else {
                Text(store.needsSettings ? "Enable full Calendar access for Notchpop in System Settings, then click Refresh." : "Connect the calendars already synced to this Mac, including Google and Outlook accounts.")
                if store.needsSettings {
                    HStack { Button("Open System Settings") { store.openPrivacySettings() }; Button("Refresh") { store.refresh() } }
                } else {
                    Button(store.requesting ? "Connecting…" : "Connect Calendar") { store.connect() }.disabled(store.requesting)
                }
                if let error = store.error { Text(error).foregroundStyle(.red).font(.caption) }
                Text("macOS calls this Full Access. Notchpop only reads events; it does not edit them or upload them.").font(.caption).foregroundStyle(.secondary)
                Spacer()
            }
            HStack {
                Button(store.isDemo ? "Use my calendar" : "Load demo meeting") {
                    if store.isDemo { store.endDemo() } else { preview() }
                }
                .help(store.isDemo ? "Return to your calendar events." : "Then hover over the notch to preview.")
                Spacer()
                Text("All-day events stay out of the way.").font(.caption).foregroundStyle(.secondary)
            }
        }.padding(28).frame(width: 440, height: 480)
    }
}

if CommandLine.arguments.contains("--self-test") {
    func check(_ condition: @autoclosure () -> Bool, _ label: String) {
        guard condition() else { fatalError("Failed: \(label)") }
        print("PASS: \(label)")
    }
    let model = NotchState()
    let now = Date()
    model.tick(now: now, near: false, inside: false)
    check(model.mood == .hidden, "Idle overlay stays completely hidden")
    model.tick(now: now, near: true, inside: false)
    check(model.mood == .peek, "Proximity peeks without opening immediately")
    model.tick(now: now.addingTimeInterval(0.61), near: true, inside: false)
    check(model.mood == .open, "Continuous dwell reveals card")
    model.tick(now: now.addingTimeInterval(1), near: false, inside: true)
    check(model.mood == .open, "Card stays open while interacting")
    model.tick(now: now.addingTimeInterval(2), near: false, inside: false)
    model.tick(now: now.addingTimeInterval(2.5), near: false, inside: false)
    check(model.mood == .hidden, "Leaving dismisses after grace period")
    let current = Meeting(id: "current", title: "Current", start: now.addingTimeInterval(-300), end: now.addingTimeInterval(300), calendar: "Test")
    let next = Meeting(id: "next", title: "Next", start: now.addingTimeInterval(300), end: now.addingTimeInterval(600), calendar: "Test")
    check(Meeting.featured(in: [next, current], at: now)?.id == "current", "Current meeting has priority")
    check(Meeting.featured(in: [next, current], at: now.addingTimeInterval(300))?.id == "next", "Exact end boundary advances to next meeting")
    check(Meeting.featured(in: [next, current], at: now.addingTimeInterval(700)) == nil, "Ended meetings disappear after sleep")
    check(Meeting.featured(in: [next], at: now)?.id == "next", "Upcoming event is shown")
    check(current.progress(at: now) == 0.5, "Meeting progress is based on dates")
    check(Meeting.conferenceURL(in: "Meet: https://meet.google.com/abc-defg-hij")?.host == "meet.google.com", "Conference URL is extracted")
    check(Meeting.conferenceURL(in: "https://zoom.us.evil.example/j/123") == nil, "Lookalike hosts do not become Join buttons")
    check(Meeting.conferenceURL(in: "file:///tmp/test") == nil, "Non-HTTPS links are excluded")
    let linked = Meeting(id: "local", title: "Test", start: Date(timeIntervalSince1970: 0), end: now, calendar: "Test", calendarItemIdentifier: "event/id?#")
    check(linked.calendarURL?.absoluteString == "ical://ekevent/19700101T000000Z/event%2Fid%3F%23?method=show&options=more", "Event link uses UTC occurrence date and safely encoded identifier")
    check(current.calendarURL == nil, "Demo events do not link to unrelated Calendar events")
    check(NotchState.dwellProgress(elapsed: -1) == 0 && NotchState.dwellProgress(elapsed: 2) == 1, "Highlight progress is clamped")
    check(abs(NotchState.dwellProgress(elapsed: 0.175) - 0.5) < 0.001, "Highlight builds throughout the hover delay")
    let hover = NotchState()
    hover.tick(now: now, near: true, inside: false)
    hover.tick(now: now.addingTimeInterval(0.15), near: true, inside: false)
    hover.tick(now: now.addingTimeInterval(0.2), near: false, inside: false)
    check(hover.mood == .hidden && hover.hoverProgress == 0, "Leaving during dwell removes the highlight immediately")
    check(MeetingNavigation.ordered([next, current]).map(\.id) == ["current", "next"], "Browsing orders meetings chronologically")
    check(MeetingNavigation.target(index: 0, step: 1, count: 2) == 1, "Scroll up selects the next meeting")
    check(MeetingNavigation.target(index: 1, step: -1, count: 2) == 0, "Scroll down selects the previous meeting")
    check(MeetingNavigation.target(index: 0, step: -1, count: 2) == nil && MeetingNavigation.target(index: 1, step: 1, count: 2) == nil, "Browsing stops at either end without wrapping")
    exit(0)
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
