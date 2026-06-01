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

    func resize(_ window: NSWindow, zoom: Double, animate: Bool = true) {
        let currentFrame = window.frame
        let frame = WindowZoom.frame(
            for: zoom,
            currentFrame: WindowFrame(
                x: currentFrame.origin.x,
                y: currentFrame.origin.y,
                width: currentFrame.width,
                height: currentFrame.height
            )
        )
        window.setFrame(
            NSRect(x: frame.x, y: frame.y, width: frame.width, height: frame.height),
            display: true,
            animate: animate
        )
    }

    @MainActor private static var shakeOriginKey: UInt8 = 0
}
