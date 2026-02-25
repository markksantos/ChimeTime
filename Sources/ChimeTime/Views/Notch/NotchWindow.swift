import AppKit

final class NotchWindow: NSWindow {

    init(size: NotificationSize) {
        let windowWidth = size.windowWidth
        let windowHeight: CGFloat = 150

        // Position: horizontally centered, flush with top of screen
        let screen = NSScreen.main ?? NSScreen.screens[0]
        let screenFrame = screen.frame
        let originX = screenFrame.midX - (windowWidth / 2)
        let originY = screenFrame.maxY - windowHeight

        let contentRect = NSRect(x: originX, y: originY, width: windowWidth, height: windowHeight)

        super.init(
            contentRect: contentRect,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )

        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        ignoresMouseEvents = false
        level = NSWindow.Level(rawValue: NSWindow.Level.statusBar.rawValue + 1)
        collectionBehavior = [.transient, .ignoresCycle]
        isReleasedWhenClosed = false
    }

    // Dismiss callback — set by NotchAnimator
    var onDismiss: (() -> Void)?

    override func mouseDown(with event: NSEvent) {
        onDismiss?()
    }
}
