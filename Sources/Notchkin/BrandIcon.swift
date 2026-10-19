import AppKit

enum BrandIcon {
    static func mark(in rect: NSRect, color: NSColor, accent: NSColor) {
        let unit = rect.width / 100
        let body = NSBezierPath(roundedRect: rect, xRadius: 19 * unit, yRadius: 19 * unit)
        color.setStroke()
        body.lineWidth = 6 * unit
        body.stroke()
        let notch = NSBezierPath(roundedRect: NSRect(x: rect.midX - 20 * unit, y: rect.maxY - 20 * unit, width: 40 * unit, height: 23 * unit), xRadius: 7 * unit, yRadius: 7 * unit)
        color.setFill()
        notch.fill()
        for index in 0..<3 {
            (index == 2 ? accent : color.withAlphaComponent(0.4)).setFill()
            NSBezierPath(ovalIn: NSRect(x: rect.minX + CGFloat(22 + index * 22) * unit, y: rect.minY + 20 * unit, width: 10 * unit, height: 10 * unit)).fill()
        }
    }

    static var menuImage: NSImage {
        let image = NSImage(size: NSSize(width: 20, height: 18), flipped: false) { _ in
            mark(in: NSRect(x: 2, y: 3, width: 16, height: 12), color: .black, accent: .black)
            return true
        }
        image.isTemplate = true
        image.accessibilityDescription = "Notchkin"
        return image
    }

    static func drawAppIcon(size: CGFloat) {
        let scale = size / 1024
        let transform = NSAffineTransform()
        transform.scale(by: scale)
        transform.concat()
        let tile = NSBezierPath(roundedRect: NSRect(x: 80, y: 80, width: 864, height: 864), xRadius: 194, yRadius: 194)
        let gradient = NSGradient(colors: [NSColor(srgbRed: 0.20, green: 0.25, blue: 0.32, alpha: 1), NSColor(srgbRed: 0.055, green: 0.07, blue: 0.10, alpha: 1)])!
        gradient.draw(in: tile, angle: -75)
        NSColor.white.withAlphaComponent(0.13).setStroke()
        tile.lineWidth = 2
        tile.stroke()
        NSGraphicsContext.saveGraphicsState()
        let shadow = NSShadow()
        shadow.shadowColor = NSColor.black.withAlphaComponent(0.4)
        shadow.shadowBlurRadius = 22
        shadow.shadowOffset = NSSize(width: 0, height: -12)
        shadow.set()
        mark(in: NSRect(x: 258, y: 332, width: 508, height: 380), color: NSColor(srgbRed: 0.92, green: 0.95, blue: 0.98, alpha: 1), accent: NSColor(srgbRed: 0.52, green: 0.88, blue: 0.76, alpha: 1))
        NSGraphicsContext.restoreGraphicsState()
    }
}
