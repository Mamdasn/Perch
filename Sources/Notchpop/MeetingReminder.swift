import SwiftUI

enum MeetingReminder {
    static func progress(in meetings: [Meeting], at now: Date) -> Double? {
        guard !meetings.contains(where: { $0.isCurrent(at: now) }) else { return nil }
        guard let start = meetings.filter({ $0.start > now && $0.end > $0.start })
            .map(\.start).min() else { return nil }
        let remaining = start.timeIntervalSince(now)
        guard remaining <= 300 else { return nil }
        return 1 - remaining / 300
    }
}

/// The notch meets the screen edge: only its sides and bottom are visible.
struct NotchOutline: Shape {
    func path(in rect: CGRect) -> Path {
        let left = rect.minX + 1
        let right = rect.maxX - 1
        let bottom = rect.maxY - 1
        let radius = min(10, rect.height / 2)
        var path = Path()
        path.move(to: CGPoint(x: left, y: rect.minY))
        path.addLine(to: CGPoint(x: left, y: bottom - radius))
        path.addQuadCurve(to: CGPoint(x: left + radius, y: bottom),
                          control: CGPoint(x: left, y: bottom))
        path.addLine(to: CGPoint(x: right - radius, y: bottom))
        path.addQuadCurve(to: CGPoint(x: right, y: bottom - radius),
                          control: CGPoint(x: right, y: bottom))
        path.addLine(to: CGPoint(x: right, y: rect.minY))
        return path
    }
}

struct MeetingReminderEdge: View {
    let progress: Double
    let hasNotch: Bool
    let width: CGFloat
    let height: CGFloat
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorSchemeContrast) private var contrast

    var body: some View {
        let color = Color(red: 0.20, green: 0.55 + 0.30 * progress, blue: 1 - 0.55 * progress)
        let gradient = LinearGradient(colors: [color.opacity(0.45), color, color.opacity(0.65)],
                                      startPoint: .leading, endPoint: .trailing)
        Group {
            if hasNotch {
                NotchOutline()
                    .stroke(gradient, lineWidth: contrast == .increased ? 2 : 1.5)
                    .frame(width: width + 4, height: height + 2)
            } else {
                Capsule().fill(gradient).frame(width: 72, height: 2).padding(.top, 1)
            }
        }
        .opacity(contrast == .increased ? 1 : 0.75)
        .shadow(color: color.opacity(reduceTransparency ? 0 : 0.15), radius: 3)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
