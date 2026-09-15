import AppKit

@MainActor enum AppBrand {
    /// A small, original hinge mark: two glass panels joined by a quiet seam.
    /// It is drawn at runtime so this personal fork carries no upstream artwork.
    static let mark: NSImage = {
        let size = NSSize(width: 128, height: 128)
        let image = NSImage(size: size)
        image.lockFocus()
        let inset: CGFloat = 13
        let top = NSRect(x: inset, y: 64, width: 102, height: 48)
        let base = NSRect(x: inset, y: 18, width: 102, height: 37)
        let panel = NSBezierPath(roundedRect: top, xRadius: 18, yRadius: 18)
        NSColor.controlAccentColor.withAlphaComponent(0.82).setFill()
        panel.fill()
        NSColor.white.withAlphaComponent(0.52).setStroke()
        panel.lineWidth = 3
        panel.stroke()
        let lower = NSBezierPath(roundedRect: base, xRadius: 15, yRadius: 15)
        NSColor.labelColor.withAlphaComponent(0.88).setFill()
        lower.fill()
        NSColor.white.withAlphaComponent(0.2).setStroke()
        lower.lineWidth = 2
        lower.stroke()
        let hinge = NSBezierPath()
        hinge.move(to: NSPoint(x: 30, y: 59))
        hinge.line(to: NSPoint(x: 98, y: 59))
        hinge.lineWidth = 5
        NSColor.white.withAlphaComponent(0.85).setStroke()
        hinge.stroke()
        image.unlockFocus()
        image.isTemplate = false
        image.accessibilityDescription = "AthiDuo"
        return image
    }()

    static var menuBarMark: NSImage {
        let image = NSImage(systemSymbolName: "rectangle.inset.filled", accessibilityDescription: "AthiDuo") ?? mark.copy() as! NSImage
        image.size = NSSize(width: 18, height: 18)
        image.isTemplate = true
        return image
    }
}
