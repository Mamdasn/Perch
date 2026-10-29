import AppKit
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

/// An open band with pointed ends that flow into the display's top edge.
struct TaperedNotchEdge: Shape {
    var spread: CGFloat = 0
    var thickness: CGFloat

    func path(in rect: CGRect) -> Path {
        let left = rect.minX - spread
        let right = rect.maxX + spread
        let bottom = rect.maxY + spread
        let radius = min(10, rect.height / 2) + spread
        let half = thickness / 2
        let shoulder = rect.minY + min(9, rect.height / 3)
        let upperControl = rect.minY + 2
        let tipLeft = CGPoint(x: left - 12, y: rect.minY)
        let tipRight = CGPoint(x: right + 12, y: rect.minY)
        var path = Path()
        path.move(to: tipLeft)
        path.addCurve(to: CGPoint(x: left - half, y: shoulder),
                      control1: CGPoint(x: left - 3, y: rect.minY),
                      control2: CGPoint(x: left - half, y: upperControl))
        path.addLine(to: CGPoint(x: left - half, y: bottom - radius))
        path.addQuadCurve(to: CGPoint(x: left + radius, y: bottom + half),
                          control: CGPoint(x: left - half, y: bottom + half))
        path.addLine(to: CGPoint(x: right - radius, y: bottom + half))
        path.addQuadCurve(to: CGPoint(x: right + half, y: bottom - radius),
                          control: CGPoint(x: right + half, y: bottom + half))
        path.addLine(to: CGPoint(x: right + half, y: shoulder))
        path.addCurve(to: tipRight,
                      control1: CGPoint(x: right + half, y: upperControl),
                      control2: CGPoint(x: right + 3, y: rect.minY))
        path.addCurve(to: CGPoint(x: right - half, y: shoulder),
                      control1: CGPoint(x: right + 3, y: rect.minY),
                      control2: CGPoint(x: right - half, y: upperControl))
        path.addLine(to: CGPoint(x: right - half, y: bottom - radius))
        path.addQuadCurve(to: CGPoint(x: right - radius, y: bottom - half),
                          control: CGPoint(x: right - half, y: bottom - half))
        path.addLine(to: CGPoint(x: left + radius, y: bottom - half))
        path.addQuadCurve(to: CGPoint(x: left + half, y: bottom - radius),
                          control: CGPoint(x: left + half, y: bottom - half))
        path.addLine(to: CGPoint(x: left + half, y: shoulder))
        path.addCurve(to: tipLeft,
                      control1: CGPoint(x: left + half, y: upperControl),
                      control2: CGPoint(x: left - 3, y: rect.minY))
        path.closeSubpath()
        return path
    }
}

struct MeetingReminderEdge: View {
    let progress: Double
    let hasNotch: Bool
    let width: CGFloat
    let height: CGFloat
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorSchemeContrast) private var contrast

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30, paused: reduceMotion || contrast == .increased)) { timeline in
            let phase = timeline.date.timeIntervalSinceReferenceDate * .pi / 2
            let brightness = reduceMotion || contrast == .increased ? 1 : 0.90 + 0.10 * sin(phase)
            highlight.opacity(brightness)
        }
    }

    @ViewBuilder private var highlight: some View {
        let color = Color(nsColor: NSColor.systemBlue.blended(
            withFraction: min(1, max(0, progress)), of: .systemGreen) ?? .systemBlue)
        let edgeOpacity = reduceTransparency || contrast == .increased ? 1.0 : 0.9
        let gradient = LinearGradient(colors: [color.opacity(edgeOpacity), color, color.opacity(edgeOpacity)],
                                      startPoint: .leading, endPoint: .trailing)
        Group {
            if hasNotch {
                ZStack {
                    if !reduceTransparency && contrast != .increased {
                        // A compact, outward-only halo keeps the edge readable.
                        ForEach(1..<9) { step in
                            TaperedNotchEdge(spread: CGFloat(step) * 0.5, thickness: 1)
                                .fill(color.opacity(0.22 * pow(1 - Double(step) / 8, 2)))
                        }
                    }
                    TaperedNotchEdge(thickness: contrast == .increased ? 5 : 4)
                        .fill(gradient)
                }
                .frame(width: width, height: height)
            } else {
                ZStack(alignment: .top) {
                    if !reduceTransparency && contrast != .increased {
                        Rectangle()
                            .fill(LinearGradient(colors: [color.opacity(0.22), .clear],
                                                 startPoint: .top, endPoint: .bottom))
                            .frame(width: 72, height: 4)
                            .mask(LinearGradient(colors: [.clear, .white, .white, .clear],
                                                 startPoint: .leading, endPoint: .trailing))
                    }
                    Capsule().fill(gradient).frame(width: 72, height: contrast == .increased ? 3.5 : 2.5)
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
