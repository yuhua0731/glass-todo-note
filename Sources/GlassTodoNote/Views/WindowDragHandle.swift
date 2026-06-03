import AppKit
import SwiftUI

struct WindowDragHandle: NSViewRepresentable {
    var onDragStart: () -> Void

    func makeNSView(context: Context) -> DragHandleView {
        let view = DragHandleView()
        view.onDragStart = onDragStart
        return view
    }

    func updateNSView(_ view: DragHandleView, context: Context) {
        view.onDragStart = onDragStart
    }
}

final class DragHandleView: NSView {
    var onDragStart: () -> Void = {}

    override var mouseDownCanMoveWindow: Bool {
        true
    }

    override func mouseDown(with event: NSEvent) {
        onDragStart()
        window?.performDrag(with: event)
    }
}
