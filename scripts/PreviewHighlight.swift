import AppKit
import SwiftUI

@main struct PreviewHighlight {
    @MainActor static func main() throws {
        let renderer = ImageRenderer(content:
            VStack(alignment: .leading, spacing: 24) {
                Text("Perch · Silver contour").font(.system(size: 24, weight: .semibold))
                Text("A fine material edge, an outward trace, and a quiet reflected glint.")
                    .foregroundStyle(.secondary)
                HStack(spacing: 20) {
                    sample(title: "Hover begins", reveal: 0.2, card: false)
                    sample(title: "Hover settles", reveal: 0.85, card: false)
                    sample(title: "Meeting card", reveal: 1, card: true)
                }
                Text("Geometry preview · native material adapts to the desktop in the running app.")
                    .font(.system(size: 12)).foregroundStyle(.secondary)
            }
            .padding(28).background(Color(white: 0.055))
            .environment(\.colorScheme, .dark)
        )
        renderer.scale = 2
        guard let cg = renderer.cgImage else { fatalError("Render failed") }
        let bitmap = NSBitmapImageRep(cgImage: cg)
        try bitmap.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: CommandLine.arguments[1]))
    }

    static func sample(title: String, reveal: CGFloat, card: Bool) -> some View {
        VStack(spacing: 12) {
            Text(title).font(.system(size: 13, weight: .medium))
            ZStack(alignment: .top) {
                LinearGradient(colors: [Color(white: 0.18), Color(white: 0.08)],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
                RoundedRectangle(cornerRadius: 10).fill(.black)
                    .frame(width: 150, height: 50).offset(y: -20)
                if card {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("IN PROGRESS").font(.system(size: 9, weight: .medium)).foregroundStyle(.secondary)
                        Text("Design review").font(.system(size: 18, weight: .semibold))
                        Text("Your next meeting, quietly within reach.")
                            .font(.system(size: 12)).foregroundStyle(.secondary)
                        Spacer()
                        HStack {
                            Text("Perch").foregroundStyle(.secondary)
                            Spacer()
                            Text("Join").padding(.horizontal, 12).padding(.vertical, 5)
                                .background(.white.opacity(0.09), in: Capsule())
                        }.font(.system(size: 11))
                    }
                    .padding(18).frame(width: 248, height: 190, alignment: .topLeading)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22))
                    .overlay { SilverCardRim(reveal: reveal) }
                    .offset(y: 48)
                } else {
                    SilverContour(contour: NotchContour(), reveal: reveal,
                                  prominence: 0.8, reflection: Double(reveal))
                        .frame(width: 150, height: 30)
                }
            }
            .frame(width: 280, height: 260).clipped()
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
}

// The reminder timing helper compiles alongside this isolated rendering script.
struct Meeting {
    var start: Date
    var end: Date
    func isCurrent(at now: Date) -> Bool { start <= now && now < end }
}
