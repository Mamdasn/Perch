import SwiftUI

/// A finite, hand-shaped liquid bridge; it disappears once the rim has settled.
struct LiquidBridge: Shape {
    var progress: CGFloat
    var reveal: CGFloat
    var inset: CGFloat
    var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get { AnimatablePair(progress, reveal) }
        set { progress = newValue.first; reveal = newValue.second }
    }

    func path(in rect: CGRect) -> Path {
        let p = min(1, max(0, progress * 1.8))
        // Drain toward the card: the upper contact recedes first, while the
        // receiving meniscus stays wider. Stretch thins the connecting neck.
        let rootRadius = 0.2 + 3.6 * pow(1 - p, 1.5)
        let footRadius = 0.5 + 5.5 * pow(1 - p, 0.85)
        let top = inset - 1
        let bottom = max(inset + 2, inset + 18 - 252 * (1 - reveal))
        let length = bottom - top
        let stretch = sqrt(8 / max(8, length))
        let waist = (0.15 + 1.6 * pow(1 - p, 2)) * stretch
        let center = rect.midX
        let middle = top + length * 0.38
        var path = Path()
        path.move(to: CGPoint(x: center - rootRadius, y: top))
        path.addCurve(to: CGPoint(x: center - waist, y: middle),
                      control1: CGPoint(x: center - rootRadius, y: top + length * 0.18),
                      control2: CGPoint(x: center - waist, y: top + length * 0.28))
        path.addCurve(to: CGPoint(x: center - footRadius, y: bottom + 0.5),
                      control1: CGPoint(x: center - waist, y: top + length * 0.82),
                      control2: CGPoint(x: center - footRadius, y: bottom - length * 0.08))
        path.addLine(to: CGPoint(x: center + footRadius, y: bottom + 0.5))
        path.addCurve(to: CGPoint(x: center + waist, y: middle),
                      control1: CGPoint(x: center + footRadius, y: bottom - length * 0.08),
                      control2: CGPoint(x: center + waist, y: top + length * 0.82))
        path.addCurve(to: CGPoint(x: center + rootRadius, y: top),
                      control1: CGPoint(x: center + waist, y: top + length * 0.28),
                      control2: CGPoint(x: center + rootRadius, y: top + length * 0.18))
        path.closeSubpath()
        return path
    }
}

/// Two rounded rectangles form a film that stretches behind the card and settles.
struct DisplacedMilk: Shape {
    var progress: CGFloat
    var reveal: CGFloat
    var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get { AnimatablePair(progress, reveal) }
        set { progress = newValue.first; reveal = newValue.second }
    }

    func path(in rect: CGRect) -> Path {
        let p = min(1, max(0, progress))
        let lag = max(0, reveal - p)
        let thickness = 0.8 + 5 * lag
        // Extend upward without moving the inner cutout off the card.
        let outer = rect.insetBy(dx: -thickness, dy: -thickness)
            .insetBy(dx: 0, dy: -4 * lag).offsetBy(dx: 0, dy: -4 * lag)
        var film = Path()
        film.addRoundedRect(in: outer, cornerSize: CGSize(width: 22 + thickness, height: 22 + thickness))
        film.addRoundedRect(in: rect.insetBy(dx: 0.6, dy: 0.6), cornerSize: CGSize(width: 22, height: 22))
        return film
    }
}

struct MilkRim: View {
    var progress: CGFloat
    var reveal: CGFloat
    var reducedTransparency: Bool

    var body: some View {
        let milk = Color(red: 0.87, green: 0.95, blue: 0.97)
        DisplacedMilk(progress: progress, reveal: reveal)
            .fill(milk.opacity(0.08), style: FillStyle(eoFill: true))
            .shadow(color: milk.opacity(reducedTransparency ? 0 : 0.02), radius: 2)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}
