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
    var spread: CGFloat = 0
    func path(in rect: CGRect) -> Path {
        let left = rect.minX + 1 - spread
        let right = rect.maxX - 1 + spread
        let bottom = rect.maxY - 1 + spread
        let radius = min(10, rect.height / 2) + spread
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
                ZStack {
                    if !reduceTransparency {
                        // Thin outward bands fade to zero over six points.
                        ForEach(1..<13) { step in
                            NotchOutline(spread: CGFloat(step) * 0.5)
                                .stroke(color.opacity(0.12 * pow(1 - Double(step) / 12, 2)), lineWidth: 1)
                        }
                    }
                    NotchOutline()
                        .stroke(gradient, lineWidth: contrast == .increased ? 1.5 : 0.75)
                }
                .frame(width: width + 4, height: height + 2)
            } else {
                ZStack(alignment: .top) {
                    if !reduceTransparency {
                        Rectangle()
                            .fill(LinearGradient(colors: [color.opacity(0.18), .clear],
                                                 startPoint: .top, endPoint: .bottom))
                            .frame(width: 72, height: 6)
                            .mask(LinearGradient(colors: [.clear, .white, .white, .clear],
                                                 startPoint: .leading, endPoint: .trailing))
                    }
                    Capsule().fill(gradient).frame(width: 72, height: contrast == .increased ? 1.5 : 0.75)
                }.padding(.top, 1)
            }
        }
        .opacity(contrast == .increased ? 1 : 0.75)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
