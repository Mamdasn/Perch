import SwiftUI

enum MeetingReminder {
    static func previewProgress(elapsed: TimeInterval) -> Double {
        if elapsed <= 5 { return min(1, max(0, elapsed / 5)) }
        let t = min(1, (elapsed - 5) / 0.6)
        return 1 - t * t * (3 - 2 * t)
    }

    static func progress(in meetings: [Meeting], at now: Date) -> Double? {
        if meetings.contains(where: { $0.isCurrent(at: now) }) { return 1 }
        guard let start = meetings.filter({ $0.start > now && $0.end > $0.start })
            .map(\.start).min() else { return nil }
        let remaining = start.timeIntervalSince(now)
        guard remaining <= 300 else { return nil }
        return 1 - remaining / 300
    }
}

/// An open contour follows the hardware with soft shoulders at the display edge.
struct NotchContour: Shape {
    func path(in rect: CGRect) -> Path {
        let left = rect.minX - 1.5
        let right = rect.maxX + 1.5
        let bottom = rect.maxY + 1.5
        let radius = min(10, rect.height / 2)
        var path = Path()
        path.move(to: CGPoint(x: left - 7, y: rect.minY - 1))
        path.addQuadCurve(to: CGPoint(x: left, y: rect.minY + 7),
                          control: CGPoint(x: left, y: rect.minY))
        path.addLine(to: CGPoint(x: left, y: bottom - radius))
        path.addQuadCurve(to: CGPoint(x: left + radius, y: bottom),
                          control: CGPoint(x: left, y: bottom))
        path.addLine(to: CGPoint(x: right - radius, y: bottom))
        path.addQuadCurve(to: CGPoint(x: right, y: bottom - radius),
                          control: CGPoint(x: right, y: bottom))
        path.addLine(to: CGPoint(x: right, y: rect.minY + 7))
        path.addQuadCurve(to: CGPoint(x: right + 7, y: rect.minY - 1),
                          control: CGPoint(x: right, y: rect.minY))
        return path
    }
}

struct DisplayEdgeLine: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY + 1.5))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + 1.5))
        return path
    }
}

struct MeetingReminderEdge: View {
    let progress: Double
    let hasNotch: Bool
    let width: CGFloat
    let height: CGFloat
    var hoverProgress: CGFloat = 0
    var isHoverPreview = false
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorSchemeContrast) private var contrast

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 24,
                                paused: reduceMotion || reduceTransparency || contrast == .increased || isHoverPreview)) { timeline in
            let cycle = timeline.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 9)
            // One unhurried reflection followed by a quiet interval, without pulsing.
            let reflection = reduceMotion || reduceTransparency || contrast == .increased ? 0.5 : min(1.4, cycle / 3)
            highlight(reflection: isHoverPreview ? Double(hoverProgress) : reflection)
        }
    }

    @ViewBuilder private func highlight(reflection: Double) -> some View {
        let amount = min(1, max(0, progress))
        let reveal = isHoverPreview ? hoverProgress : CGFloat(0.15 + 0.85 * amount)
        let prominence = isHoverPreview ? 0.35 + 0.4 * Double(hoverProgress) : 0.7 + 0.3 * amount
        Group {
            if hasNotch {
                SilverContour(contour: NotchContour(), reveal: reveal,
                              prominence: prominence, reflection: reflection)
                    .frame(width: width, height: height)
            } else {
                SilverContour(contour: DisplayEdgeLine(), reveal: reveal,
                              prominence: prominence, reflection: reflection)
                    .frame(width: 72, height: 4)
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
