import AppKit
import SwiftUI

struct MeetingNavigation {
    static func ordered(_ items: [Meeting]) -> [Meeting] {
        items.sorted { $0.start == $1.start ? $0.id < $1.id : $0.start < $1.start }
    }
    static func target(index: Int, step: Int, count: Int) -> Int? {
        let next = index + step
        return next >= 0 && next < count ? next : nil
    }
}

struct MeetingPager: View {
    @ObservedObject var store: MeetingStore
    var now: Date
    var openSettings: () -> Void
    @State private var selectedID: String?
    @State private var direction = 1
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private var events: [Meeting] { MeetingNavigation.ordered(store.meetings) }
    private var selected: Meeting? { events.first { $0.id == selectedID } ?? Meeting.featured(in: events, at: now) ?? events.last }
    private var index: Int { events.firstIndex { $0.id == selected?.id } ?? 0 }

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                MeetingCard(store: store, now: now, openSettings: openSettings, displayedMeeting: selected)
                    .id(selected?.id ?? "empty")
                    .transition(reduceMotion ? .opacity : .asymmetric(
                        insertion: .offset(y: direction > 0 ? 20 : -20).combined(with: .opacity),
                        removal: .offset(y: direction > 0 ? -20 : 20).combined(with: .opacity)))
            }.frame(maxWidth: .infinity, maxHeight: .infinity).clipped()
            if !events.isEmpty {
                HStack(spacing: 10) {
                    Text("\(index + 1) of \(events.count)").monospacedDigit()
                    Spacer()
                    Button { move(-1) } label: { Image(systemName: "chevron.down").frame(width: 24, height: 20) }
                        .disabled(index == 0).help("Previous event · scroll down or ↓").accessibilityLabel("Previous event")
                    Button { move(1) } label: { Image(systemName: "chevron.up").frame(width: 24, height: 20) }
                        .disabled(index == events.count - 1).help("Next event · scroll up or ↑").accessibilityLabel("Next event")
                }.buttonStyle(.plain).font(.system(size: 10, weight: .medium)).foregroundStyle(.secondary)
            }
        }.background(ScrollCapture(onStep: move))
    }
    private func move(_ step: Int) {
        guard let target = MeetingNavigation.target(index: index, step: step, count: events.count) else { return }
        direction = step
        withAnimation(reduceMotion ? .easeOut(duration: 0.12) : .spring(response: 0.3, dampingFraction: 0.9)) {
            selectedID = events[target].id
        }
    }
}

// Observe this card's scrolling and arrow keys without obstructing buttons.
struct ScrollCapture: NSViewRepresentable {
    var onStep: (Int) -> Void
    func makeNSView(context: Context) -> CaptureView { CaptureView() }
    func updateNSView(_ view: CaptureView, context: Context) { view.onStep = onStep }
    static func dismantleNSView(_ view: CaptureView, coordinator: ()) { view.stop() }
    final class CaptureView: NSView {
        var onStep: (Int) -> Void = { _ in }
        private var monitor: Any?
        private var amount: CGFloat = 0
        private var fired = false
        private var lastTime: TimeInterval = 0
        private var lastFire: TimeInterval = 0
        override func viewDidMoveToWindow() {
            stop()
            guard window != nil else { return }
            monitor = NSEvent.addLocalMonitorForEvents(matching: [.scrollWheel, .keyDown]) { [weak self] event in
                guard let self, event.window === self.window else { return event }
                if event.type == .keyDown {
                    guard self.window?.isKeyWindow == true,
                          event.modifierFlags.intersection([.command, .control, .option, .shift]).isEmpty,
                          event.keyCode == 126 || event.keyCode == 125 else { return event }
                    self.onStep(event.keyCode == 126 ? 1 : -1)
                    return nil
                }
                guard
                      self.bounds.contains(self.convert(event.locationInWindow, from: nil)) else { return event }
                guard event.momentumPhase.isEmpty else { return nil }
                if event.phase.contains(.began) || event.timestamp - self.lastTime > 0.2 {
                    self.amount = 0; self.fired = false
                }
                self.lastTime = event.timestamp
                let delta = event.scrollingDeltaY
                guard abs(delta) > abs(event.scrollingDeltaX) else { return nil }
                if !event.hasPreciseScrollingDeltas {
                    if event.timestamp - self.lastFire > 0.25 && delta != 0 {
                        self.lastFire = event.timestamp
                        self.onStep(delta > 0 ? 1 : -1)
                    }
                } else if !self.fired {
                    if self.amount * delta < 0 { self.amount = 0 }
                    self.amount += delta
                    if abs(self.amount) >= 18 {
                        self.fired = true
                        self.onStep(self.amount > 0 ? 1 : -1)
                    }
                }
                return nil
            }
        }
        func stop() { if let monitor { NSEvent.removeMonitor(monitor) }; monitor = nil }
        deinit { stop() }
    }
}
