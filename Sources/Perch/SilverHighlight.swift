import SwiftUI

/// A shared silver material contour for the notch, hover feedback, and meeting card.
struct SilverContour<Contour: Shape>: View {
    var contour: Contour
    var reveal: CGFloat = 1
    var prominence: Double = 1
    var reflection: Double = 0.5
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorSchemeContrast) private var contrast

    var body: some View {
        let amount = min(1, max(0, reveal))
        let traced = contour.trim(from: 0.5 - amount / 2, to: 0.5 + amount / 2)
        ZStack {
            if reduceTransparency || contrast == .increased {
                contour.stroke(Color(white: 0.5), lineWidth: contrast == .increased ? 2 : 1)
                traced.stroke(Color(white: contrast == .increased ? 1 : 0.86),
                              style: StrokeStyle(lineWidth: contrast == .increased ? 2.5 : 1.5, lineCap: .round))
            } else {
                contour.stroke(.ultraThinMaterial, lineWidth: 2.5)
                contour.stroke(.white.opacity(0.12), lineWidth: 0.5)
                traced.stroke(
                    LinearGradient(stops: [
                        .init(color: .white.opacity(0.24), location: 0),
                        .init(color: .white.opacity(0.82), location: 0.2),
                        .init(color: .white.opacity(0.34), location: 0.5),
                        .init(color: .white.opacity(0.72), location: 0.8),
                        .init(color: .white.opacity(0.18), location: 1)
                    ], startPoint: .topLeading, endPoint: .bottomTrailing),
                    style: StrokeStyle(lineWidth: 1, lineCap: .round)
                )
                // The reflection passes over the contour, never over the content.
                traced.stroke(.white.opacity(0.75), lineWidth: 1.25)
                    .mask {
                        GeometryReader { geometry in
                            LinearGradient(colors: [.clear, .white, .clear],
                                           startPoint: .leading, endPoint: .trailing)
                                .frame(width: geometry.size.width * 0.3)
                                .offset(x: geometry.size.width * (reflection * 1.6 - 0.45))
                        }
                    }
            }
        }
        .opacity(contrast == .increased ? 1 : prominence)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// The card catches light once during its reveal, then holds a quiet bevel.
struct SilverCardRim: View {
    var reveal: CGFloat

    var body: some View {
        SilverContour(contour: RoundedRectangle(cornerRadius: 22, style: .continuous),
                      prominence: 0.35 + 0.2 * Double(reveal),
                      reflection: Double(reveal) * 1.25)
            .padding(0.5)
    }
}
