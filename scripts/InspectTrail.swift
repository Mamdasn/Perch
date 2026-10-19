import AppKit
import SwiftUI

@main struct InspectTrail {
    @MainActor static func main() throws {
        let renderer = ImageRenderer(content: HStack(spacing: 20) {
            ForEach([0.2, 0.4, 0.7], id: \.self) { phase in
                ZStack(alignment: .top) {
                    Color(white: 0.08)
                    RoundedRectangle(cornerRadius: 10).fill(.black).frame(width: 190, height: 32)
                    RoundedRectangle(cornerRadius: 22).fill(Color(white: 0.16)).frame(width: 360, height: 274).offset(y: 50)
                    LiquidBridge(progress: phase, reveal: 1, inset: 32).fill(Color.white.opacity(0.7))
                }.frame(width: 400, height: 340)
            }
        })
        renderer.scale = 2
        guard let cg = renderer.cgImage else { fatalError("Render failed") }
        let bitmap = NSBitmapImageRep(cgImage: cg)
        try bitmap.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: CommandLine.arguments[1]))
    }
}
