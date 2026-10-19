import AppKit
import EventKit
import SwiftUI

struct Meeting: Identifiable, Equatable {
    let id: String
    let title: String
    let start: Date
    let end: Date
    let calendar: String
    var joinURL: URL? = nil
    var calendarItemIdentifier: String? = nil

    // Calendar's event deep link includes the occurrence date for recurring events.
    var calendarURL: URL? {
        guard let identifier = calendarItemIdentifier, !identifier.isEmpty else { return nil }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyyMMdd'T'HHmmss'Z'"
        guard let encoded = identifier.addingPercentEncoding(withAllowedCharacters: .alphanumerics) else { return nil }
        return URL(string: "ical://ekevent/\(formatter.string(from: start))/\(encoded)?method=show&options=more")
    }

    func isCurrent(at now: Date) -> Bool { start <= now && now < end }
    func progress(at now: Date) -> Double {
        min(1, max(0, now.timeIntervalSince(start) / max(1, end.timeIntervalSince(start))))
    }
    static func featured(in meetings: [Meeting], at now: Date) -> Meeting? {
        let valid = meetings.filter { $0.end > now && $0.end > $0.start }
        return valid.filter { $0.isCurrent(at: now) }.sorted { $0.start == $1.start ? $0.id < $1.id : $0.start > $1.start }.first
            ?? valid.filter { $0.start > now }.sorted { $0.start == $1.start ? $0.id < $1.id : $0.start < $1.start }.first
    }

    // Only recognized HTTPS conference links become Join buttons, never arbitrary event URLs.
    static func conferenceURL(in text: String) -> URL? {
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) else { return nil }
        return detector.matches(in: text, range: NSRange(text.startIndex..., in: text)).compactMap(\.url).first { url in
            guard url.scheme?.lowercased() == "https", let host = url.host?.lowercased() else { return false }
            return ["meet.google.com", "zoom.us", "teams.microsoft.com", "teams.live.com", "webex.com"].contains { host == $0 || host.hasSuffix("." + $0) }
        }
    }
}

struct CalendarChoice: Identifiable {
    let id: String
    let title: String
}

final class MeetingStore: ObservableObject {
    @Published private(set) var meetings: [Meeting] = []
    @Published private(set) var calendars: [CalendarChoice] = []
    @Published private(set) var access = EKEventStore.authorizationStatus(for: .event)
    @Published private(set) var isDemo = false
    @Published private(set) var requesting = false
    @Published private(set) var error: String?
    @Published private(set) var excluded = Set(UserDefaults.standard.stringArray(forKey: "excludedCalendars") ?? [])
    private lazy var store = EKEventStore()
    private var refreshTimer: Timer?
    private var observer: NSObjectProtocol?
    private var wakeObserver: NSObjectProtocol?

    var connected: Bool { access == .fullAccess }
    var needsSettings: Bool { access == .denied || access == .restricted || access == .writeOnly }

    func start() {
        refresh()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in self?.refresh() }
        observer = NotificationCenter.default.addObserver(forName: .EKEventStoreChanged, object: nil, queue: .main) { [weak self] _ in self?.refresh() }
        wakeObserver = NSWorkspace.shared.notificationCenter.addObserver(forName: NSWorkspace.didWakeNotification, object: nil, queue: .main) { [weak self] _ in self?.refresh() }
    }

    func connect() {
        guard !requesting else { return }
        requesting = true
        error = nil
        store.requestFullAccessToEvents { [weak self] _, error in
            DispatchQueue.main.async {
                guard let self else { return }
                self.requesting = false
                self.error = error == nil ? nil : "Calendar access could not be completed. Please try again."
                self.isDemo = false
                self.refresh()
            }
        }
    }

    func setEnabled(_ enabled: Bool, id: String) {
        if enabled { excluded.remove(id) } else { excluded.insert(id) }
        UserDefaults.standard.set(Array(excluded), forKey: "excludedCalendars")
        refresh()
    }

    func refresh() {
        access = EKEventStore.authorizationStatus(for: .event)
        guard !isDemo else { return }
        guard connected else { meetings = []; calendars = []; return }
        let available = store.calendars(for: .event)
        calendars = available.map { CalendarChoice(id: $0.calendarIdentifier, title: "\($0.title) · \($0.source.title)") }.sorted { $0.title < $1.title }
        let selected = available.filter { !excluded.contains($0.calendarIdentifier) }
        guard !selected.isEmpty else { meetings = []; return }
        let now = Date()
        let earliest = now.addingTimeInterval(-7 * 86400)
        let predicate = store.predicateForEvents(withStart: earliest, end: now.addingTimeInterval(7 * 86400), calendars: selected)
        meetings = store.events(matching: predicate).compactMap { event in
            guard !event.isAllDay, event.status != .canceled, event.endDate > earliest,
                  !(event.attendees ?? []).contains(where: { $0.isCurrentUser && $0.participantStatus == .declined }) else { return nil }
            let links = [event.url?.absoluteString, event.location, event.notes].compactMap { $0 }.joined(separator: "\n")
            return Meeting(id: "\(event.calendarItemIdentifier)-\(event.startDate.timeIntervalSince1970)",
                           title: event.title?.isEmpty == false ? event.title : "Untitled meeting",
                           start: event.startDate, end: event.endDate, calendar: event.calendar.title,
                           joinURL: Meeting.conferenceURL(in: links), calendarItemIdentifier: event.calendarItemIdentifier)
        }
    }

    func demo(current: Bool) {
        let now = Date()
        isDemo = true
        meetings = [Meeting(id: "demo", title: "Design review", start: now.addingTimeInterval(current ? -600 : 180), end: now.addingTimeInterval(current ? 1200 : 1980), calendar: "Work · Demo calendar")]
        meetings += [
            Meeting(id: "demo-before", title: "Morning catch-up", start: now.addingTimeInterval(-7200), end: now.addingTimeInterval(-5400), calendar: "Work · Demo calendar"),
            Meeting(id: "demo-next", title: "Product direction", start: now.addingTimeInterval(3600), end: now.addingTimeInterval(5400), calendar: "Work · Demo calendar"),
            Meeting(id: "demo-later", title: "Team sync", start: now.addingTimeInterval(7200), end: now.addingTimeInterval(9000), calendar: "Work · Demo calendar")
        ]
    }

    func endDemo() { isDemo = false; refresh() }
    func openInCalendar(_ meeting: Meeting) {
        guard let url = meeting.calendarURL else { return }
        if !NSWorkspace.shared.open(url) {
            error = "Calendar couldn’t open this event. Refresh your calendars and try again."
        }
    }
    func openPrivacySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Calendars") { NSWorkspace.shared.open(url) }
    }
}

struct MeetingCard: View {
    @ObservedObject var store: MeetingStore
    var now: Date
    var openSettings: () -> Void
    var displayedMeeting: Meeting? = nil
    private var meeting: Meeting? { displayedMeeting ?? Meeting.featured(in: store.meetings, at: now) }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 7) {
                Circle().fill(meeting?.isCurrent(at: now) == true ? Color.green : Color.secondary).frame(width: 5, height: 5)
                Text(meeting?.isCurrent(at: now) == true ? "In progress" : ((meeting?.end ?? .distantFuture) <= now ? "Earlier" : "Up next"))
                    .font(.system(size: 11, weight: .medium)).foregroundStyle(.secondary)
                if store.isDemo { Text("DEMO").font(.system(size: 8, weight: .semibold)).foregroundStyle(.secondary).padding(4).background(.white.opacity(0.08), in: Capsule()) }
                Spacer()
                Button(action: openSettings) { Image(systemName: "ellipsis").frame(width: 22, height: 20) }
                    .buttonStyle(.plain).foregroundStyle(.secondary).help("Settings")
                    .accessibilityLabel("Settings")
            }
            if let meeting {
                let current = meeting.isCurrent(at: now)
                Button { store.openInCalendar(meeting) } label: {
                VStack(alignment: .leading, spacing: 0) {
                Text(meeting.title).font(.system(size: 22, weight: .semibold))
                    .tracking(-0.5).lineLimit(2).fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 13)
                Text("\(meeting.start.formatted(.dateTime.weekday(.abbreviated).hour().minute())) – \(meeting.end.formatted(date: .omitted, time: .shortened))")
                    .font(.system(size: 12)).foregroundStyle(.secondary).padding(.top, 7)
                Spacer(minLength: 12)
                if current {
                    ProgressView(value: meeting.progress(at: now)).tint(.green)
                        .accessibilityLabel("Meeting elapsed").padding(.bottom, 13)
                } else {
                    Divider().padding(.bottom, 13)
                }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(meeting.calendarURL == nil)
                .help(meeting.calendarURL == nil ? "Demo event — not saved in Calendar" : "Show this event in Calendar")
                .accessibilityLabel("Show \(meeting.title) in Calendar")
                HStack(alignment: .center) {
                    Button { store.openInCalendar(meeting) } label: {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(current ? "\(max(1, Int(ceil(meeting.end.timeIntervalSince(now) / 60)))) min remaining" : upcomingLabel(meeting))
                            .font(.system(size: 13, weight: .medium)).monospacedDigit()
                        Text(store.meetings.filter({ $0.isCurrent(at: now) }).count > 1 ? "Overlapping events · check Calendar" : meeting.calendar)
                            .font(.system(size: 10)).foregroundStyle(.secondary).lineLimit(1)
                    }
                    }.buttonStyle(.plain).disabled(meeting.calendarURL == nil)
                    Spacer(minLength: 8)
                    if let url = meeting.joinURL {
                        Button { NSWorkspace.shared.open(url) } label: { Label("Join", systemImage: "arrow.up.right") }
                            .buttonStyle(.borderedProminent).tint(.white).foregroundStyle(.black).controlSize(.regular)
                    } else {
                        Button { store.openInCalendar(meeting) } label: { Label("Open", systemImage: "arrow.up.right") }
                            .buttonStyle(PillStyle()).disabled(meeting.calendarURL == nil)
                            .help(meeting.calendarURL == nil ? "Demo event — not saved in Calendar" : "Show this event in Calendar")
                    }
                }
            } else {
                Image(systemName: store.connected ? "calendar.badge.checkmark" : "calendar")
                    .font(.system(size: 25, weight: .light)).foregroundStyle(.secondary).padding(.top, 20)
                Text(store.connected ? "A little breathing room." : "Your day. At a glance.")
                    .font(.system(size: 21, weight: .semibold)).tracking(-0.4).padding(.top, 10)
                Text(store.connected ? "No events in the next seven days." : "Connect Calendar to see your next meeting.")
                    .font(.system(size: 12)).foregroundStyle(.secondary).padding(.top, 5)
                Spacer(minLength: 10)
                Button(store.connected ? "Choose calendars" : "Connect Calendar", action: openSettings).buttonStyle(PillStyle())
            }
        }
        .foregroundStyle(.primary)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func upcomingLabel(_ meeting: Meeting) -> String {
        if meeting.end <= now { return "Ended \(meeting.end.formatted(date: .omitted, time: .shortened))" }
        let minutes = max(1, Int(ceil(meeting.start.timeIntervalSince(now) / 60)))
        if minutes < 60 { return "Starts in \(minutes) min" }
        if minutes < 1440 { return "Starts in \(minutes / 60)h \(minutes % 60)m" }
        return "Starts in \(minutes / 1440)d"
    }
}
