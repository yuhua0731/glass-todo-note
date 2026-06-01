import AppKit
import GlassTodoNoteCore

@MainActor
final class StickyWindowController {
    private var activeShakeTask: Task<Void, Never>?
    private weak var activeShakeWindow: NSWindow?

    func configure(_ window: NSWindow, preferences: WindowPreferences) {
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = true
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.styleMask.insert(.fullSizeContentView)
        window.level = preferences.floatsAboveWindows ? .floating : .normal
        window.alphaValue = preferences.opacity
        window.contentView?.wantsLayer = true
        window.contentView?.layer?.cornerRadius = preferences.cornerRadius
        window.contentView?.layer?.masksToBounds = true
    }

    func shake(_ window: NSWindow, plan: WindowShakePlan = WindowShakePlan()) {
        if let task = activeShakeTask {
            task.cancel()
            self.activeShakeTask = nil
            if let activeShakeWindow,
               let origin = objc_getAssociatedObject(activeShakeWindow, &Self.shakeOriginKey) as? NSValue {
                activeShakeWindow.setFrameOrigin(origin.pointValue)
                objc_setAssociatedObject(activeShakeWindow, &Self.shakeOriginKey, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            }
        }

        let origin = window.frame.origin
        activeShakeWindow = window
        objc_setAssociatedObject(window, &Self.shakeOriginKey, NSValue(point: origin), .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        activeShakeTask = Task {
            let delay = UInt64(1_000_000_000 / UInt64(plan.stepsPerSecond))
            for (index, offset) in plan.offsets.enumerated() {
                guard !Task.isCancelled else { return }
                window.setFrameOrigin(NSPoint(x: origin.x + offset, y: origin.y))
                if index < plan.offsets.indices.last! {
                    try? await Task.sleep(nanoseconds: delay)
                }
            }
            window.setFrameOrigin(origin)
            self.activeShakeWindow = nil
            objc_setAssociatedObject(window, &Self.shakeOriginKey, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    func resize(_ window: NSWindow, zoom: Double) {
        let size = WindowZoom.size(for: zoom)
        let currentFrame = window.frame
        let newSize = NSSize(width: size.width, height: size.height)
        let newOrigin = NSPoint(
            x: currentFrame.midX - newSize.width / 2,
            y: currentFrame.midY - newSize.height / 2
        )
        window.setFrame(NSRect(origin: newOrigin, size: newSize), display: true, animate: true)
    }

    @MainActor private static var shakeOriginKey: UInt8 = 0
}
