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
        window.alphaValue = 1
        window.contentView?.wantsLayer = true
        window.contentView?.layer?.cornerRadius = preferences.cornerRadius
        window.contentView?.layer?.masksToBounds = true
    }

    func fitToContent(_ window: NSWindow, width: Double, height: Double) {
        let contentSize = NSSize(width: width, height: height)
        let frameSize = window.frameRect(forContentRect: NSRect(origin: .zero, size: contentSize)).size
        let currentFrame = window.frame

        guard abs(currentFrame.width - frameSize.width) > 0.5
            || abs(currentFrame.height - frameSize.height) > 0.5 else {
            return
        }

        let newFrame = NSRect(
            x: currentFrame.minX,
            y: currentFrame.maxY - frameSize.height,
            width: frameSize.width,
            height: frameSize.height
        )
        window.setFrame(newFrame, display: true, animate: false)
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

    @MainActor private static var shakeOriginKey: UInt8 = 0
}
