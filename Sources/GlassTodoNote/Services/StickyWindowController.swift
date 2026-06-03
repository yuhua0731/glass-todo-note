import AppKit
import GlassTodoNoteCore

@MainActor
final class StickyWindowController {
    private var activeShakeTask: Task<Void, Never>?
    private weak var activeShakeWindow: NSWindow?
    private var isApplyingShakeFrame = false

    func configure(_ window: NSWindow, preferences: WindowPreferences) {
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = true
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = false
        window.styleMask.insert(.titled)
        window.styleMask.remove(.fullSizeContentView)
        window.isMovable = true
        window.isMovableByWindowBackground = true
        window.level = preferences.floatsAboveWindows ? .floating : .normal
        window.alphaValue = 1
        window.contentView?.wantsLayer = true
        window.contentView?.layer?.cornerRadius = preferences.cornerRadius
        window.contentView?.layer?.masksToBounds = true
        installMoveDelegate(on: window)
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
        cancelShake(restoringOrigin: true)

        let origin = window.frame.origin
        activeShakeWindow = window
        objc_setAssociatedObject(window, &Self.shakeOriginKey, NSValue(point: origin), .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        activeShakeTask = Task {
            let delay = UInt64(1_000_000_000 / UInt64(plan.stepsPerSecond))
            for (index, offset) in plan.offsets.enumerated() {
                guard !Task.isCancelled else { return }
                isApplyingShakeFrame = true
                window.setFrameOrigin(NSPoint(x: origin.x + offset, y: origin.y))
                isApplyingShakeFrame = false
                if index < plan.offsets.indices.last! {
                    try? await Task.sleep(nanoseconds: delay)
                }
            }
            isApplyingShakeFrame = true
            window.setFrameOrigin(origin)
            isApplyingShakeFrame = false
            self.activeShakeWindow = nil
            objc_setAssociatedObject(window, &Self.shakeOriginKey, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    private func installMoveDelegate(on window: NSWindow) {
        if let delegate = objc_getAssociatedObject(window, &Self.moveDelegateKey) as? StickyWindowMoveDelegate {
            if window.delegate !== delegate {
                delegate.forwardingDelegate = window.delegate
                window.delegate = delegate
            }
            return
        }

        let delegate = StickyWindowMoveDelegate(
            forwardingDelegate: window.delegate,
            onWillMove: { [weak self] in
                guard let self, !isApplyingShakeFrame else { return }
                cancelShake(restoringOrigin: false)
            }
        )
        window.delegate = delegate
        objc_setAssociatedObject(window, &Self.moveDelegateKey, delegate, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }

    private func cancelShake(restoringOrigin: Bool) {
        guard let task = activeShakeTask else { return }
        task.cancel()
        activeShakeTask = nil
        isApplyingShakeFrame = false

        if let activeShakeWindow {
            if restoringOrigin,
               let origin = objc_getAssociatedObject(activeShakeWindow, &Self.shakeOriginKey) as? NSValue {
                activeShakeWindow.setFrameOrigin(origin.pointValue)
            }
            objc_setAssociatedObject(activeShakeWindow, &Self.shakeOriginKey, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        activeShakeWindow = nil
    }

    @MainActor private static var shakeOriginKey: UInt8 = 0
    @MainActor private static var moveDelegateKey: UInt8 = 0
}

@MainActor
private final class StickyWindowMoveDelegate: NSObject, NSWindowDelegate {
    weak var forwardingDelegate: NSWindowDelegate?
    private let onWillMove: () -> Void

    init(forwardingDelegate: NSWindowDelegate?, onWillMove: @escaping () -> Void) {
        self.forwardingDelegate = forwardingDelegate
        self.onWillMove = onWillMove
    }

    func windowWillMove(_ notification: Notification) {
        onWillMove()
        forwardingDelegate?.windowWillMove?(notification)
    }
}
