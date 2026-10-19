import AppKit

@main
struct RenderIcon {
    static func main() throws {
        let folder = URL(fileURLWithPath: CommandLine.arguments[1])
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        for base in [16, 32, 128, 256, 512] {
            for multiple in [1, 2] {
                let pixels = base * multiple
                let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels, bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
                NSGraphicsContext.saveGraphicsState()
                NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
                BrandIcon.drawAppIcon(size: CGFloat(pixels))
                NSGraphicsContext.restoreGraphicsState()
                let suffix = multiple == 2 ? "@2x" : ""
                try bitmap.representation(using: .png, properties: [:])!.write(to: folder.appendingPathComponent("icon_\(base)x\(base)\(suffix).png"))
            }
        }
    }
}
