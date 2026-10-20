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
        let divider = NSBezierPath()
        divider.move(to: NSPoint(x: rect.minX + 6 * unit, y: rect.maxY - 27 * unit))
        divider.line(to: NSPoint(x: rect.maxX - 6 * unit, y: rect.maxY - 27 * unit))
        divider.lineWidth = 5 * unit
        divider.stroke()
        accent.setFill()
        NSBezierPath(roundedRect: NSRect(x: rect.midX - 14 * unit, y: rect.minY + 14 * unit, width: 28 * unit, height: 17 * unit), xRadius: 4 * unit, yRadius: 4 * unit).fill()
    }

    static var menuImage: NSImage {
        let image = NSImage(size: NSSize(width: 20, height: 18), flipped: false) { _ in
            // Native vector rendition of Downloads/event-svgrepo-com.svg.
            // Crop its empty margins so the 56 × 60 mark stays legible at 16 pt.
            let transform = NSAffineTransform()
            transform.translateX(by: 10, yBy: 9)
            transform.scaleX(by: 16 / 60, yBy: -16 / 60)
            transform.translateX(by: -50, yBy: -50)
            transform.concat()
            NSColor.black.setFill()
            let body = NSBezierPath()
            body.move(to: NSPoint(x: 76, y: 42))
            body.line(to: NSPoint(x: 24, y: 42))
            body.curve(to: NSPoint(x: 22, y: 44), controlPoint1: NSPoint(x: 22.9, y: 42), controlPoint2: NSPoint(x: 22, y: 42.9))
            body.line(to: NSPoint(x: 22, y: 74))
            body.curve(to: NSPoint(x: 28, y: 80), controlPoint1: NSPoint(x: 22, y: 77.3), controlPoint2: NSPoint(x: 24.7, y: 80))
            body.line(to: NSPoint(x: 72, y: 80))
            body.curve(to: NSPoint(x: 78, y: 74), controlPoint1: NSPoint(x: 75.3, y: 80), controlPoint2: NSPoint(x: 78, y: 77.3))
            body.line(to: NSPoint(x: 78, y: 44))
            body.curve(to: NSPoint(x: 76, y: 42), controlPoint1: NSPoint(x: 78, y: 42.9), controlPoint2: NSPoint(x: 77.1, y: 42))
            body.close()
            body.windingRule = .evenOdd
            for y in [50, 64] {
                for x in [32, 46, 60] {
                    body.append(NSBezierPath(roundedRect: NSRect(x: x, y: y, width: 8, height: 8), xRadius: 2, yRadius: 2))
                }
            }
            body.fill()
            let header = NSBezierPath(roundedRect: NSRect(x: 22, y: 26, width: 56, height: 10), xRadius: 6, yRadius: 6)
            header.fill()
            for x in [33, 59] {
                NSBezierPath(roundedRect: NSRect(x: x, y: 20, width: 8, height: 16), xRadius: 4, yRadius: 4).fill()
            }
            return true
        }
        image.isTemplate = true
        image.accessibilityDescription = "Notchpop"
        return image
    }

    static func drawAppIcon(size: CGFloat) {
        let scale = size / 1024
        let transform = NSAffineTransform()
        transform.scale(by: scale)
        transform.concat()
        let tile = NSBezierPath(roundedRect: NSRect(x: 80, y: 80, width: 864, height: 864), xRadius: 194, yRadius: 194)
        let gradient = NSGradient(colors: [NSColor(srgbRed: 0.13, green: 0.18, blue: 0.22, alpha: 1), NSColor(srgbRed: 0.025, green: 0.04, blue: 0.065, alpha: 1)])!
        gradient.draw(in: tile, angle: -75)
        NSColor.white.withAlphaComponent(0.13).setStroke()
        tile.lineWidth = 2
        tile.stroke()
        // A luminous opening above the floating calendar.
        NSGraphicsContext.saveGraphicsState()
        let glow = NSShadow()
        glow.shadowColor = NSColor(srgbRed: 0.3, green: 1, blue: 0.8, alpha: 0.7)
        glow.shadowBlurRadius = 48
        glow.shadowOffset = .zero
        glow.set()
        NSColor(srgbRed: 0.55, green: 1, blue: 0.85, alpha: 1).setFill()
        NSBezierPath(roundedRect: NSRect(x: 348, y: 778, width: 328, height: 62), xRadius: 31, yRadius: 31).fill()
        NSGraphicsContext.restoreGraphicsState()
        NSColor(srgbRed: 0.025, green: 0.045, blue: 0.06, alpha: 1).setFill()
        NSBezierPath(roundedRect: NSRect(x: 344, y: 794, width: 336, height: 78), xRadius: 30, yRadius: 30).fill()

        NSGraphicsContext.saveGraphicsState()
        let tilt = NSAffineTransform()
        tilt.translateX(by: 512, yBy: 490)
        tilt.rotate(byDegrees: -8)
        tilt.translateX(by: -512, yBy: -530)
        tilt.concat()
        NSGraphicsContext.saveGraphicsState()
        let shadow = NSShadow()
        shadow.shadowColor = NSColor.black.withAlphaComponent(0.4)
        shadow.shadowBlurRadius = 40
        shadow.shadowOffset = NSSize(width: 14, height: -28)
        shadow.set()
        let paper = NSBezierPath(roundedRect: NSRect(x: 226, y: 220, width: 572, height: 584), xRadius: 76, yRadius: 76)
        NSGradient(colors: [NSColor(srgbRed: 0.25, green: 0.35, blue: 0.39, alpha: 1), NSColor(srgbRed: 0.10, green: 0.16, blue: 0.21, alpha: 1)])!.draw(in: paper, angle: -90)
        NSGraphicsContext.restoreGraphicsState()
        NSColor(srgbRed: 0.68, green: 1, blue: 0.88, alpha: 0.55).setStroke()
        paper.lineWidth = 3
        paper.stroke()

        // Calendar header with the central silhouette of a Mac notch.
        NSGraphicsContext.saveGraphicsState()
        paper.addClip()
        NSGradient(colors: [NSColor(srgbRed: 0.72, green: 1, blue: 0.82, alpha: 1), NSColor(srgbRed: 0.24, green: 0.83, blue: 0.77, alpha: 1)])!
            .draw(in: NSRect(x: 226, y: 644, width: 572, height: 160), angle: -90)
        NSGraphicsContext.restoreGraphicsState()
        NSColor(srgbRed: 0.12, green: 0.27, blue: 0.28, alpha: 1).setFill()
        for x in [342, 638] {
            NSBezierPath(roundedRect: NSRect(x: x, y: 730, width: 32, height: 100), xRadius: 16, yRadius: 16).fill()
        }

        // A lifted event tile is the “pop”; muted cells supply calendar context.
        NSColor(srgbRed: 0.65, green: 0.82, blue: 0.81, alpha: 0.55).setFill()
        for x in [300, 452, 604] {
            NSBezierPath(roundedRect: NSRect(x: x, y: 548, width: 108, height: 26), xRadius: 13, yRadius: 13).fill()
        }
        NSGraphicsContext.saveGraphicsState()
        let eventShadow = NSShadow()
        eventShadow.shadowColor = NSColor.black.withAlphaComponent(0.20)
        eventShadow.shadowBlurRadius = 20
        eventShadow.shadowOffset = NSSize(width: 0, height: -10)
        eventShadow.set()
        let event = NSBezierPath(roundedRect: NSRect(x: 292, y: 302, width: 440, height: 184), xRadius: 42, yRadius: 42)
        NSColor(srgbRed: 0.91, green: 0.99, blue: 0.96, alpha: 1).setFill()
        event.fill()
        NSGraphicsContext.restoreGraphicsState()
        NSColor(srgbRed: 0.08, green: 0.64, blue: 0.49, alpha: 1).setFill()
        NSBezierPath(roundedRect: NSRect(x: 324, y: 342, width: 10, height: 104), xRadius: 5, yRadius: 5).fill()
        NSColor(srgbRed: 0.10, green: 0.24, blue: 0.26, alpha: 1).setFill()
        NSBezierPath(roundedRect: NSRect(x: 366, y: 410, width: 244, height: 20), xRadius: 10, yRadius: 10).fill()
        NSColor(srgbRed: 0.40, green: 0.55, blue: 0.54, alpha: 1).setFill()
        NSBezierPath(roundedRect: NSRect(x: 366, y: 362, width: 154, height: 16), xRadius: 8, yRadius: 8).fill()
        NSGraphicsContext.restoreGraphicsState()
    }
}
