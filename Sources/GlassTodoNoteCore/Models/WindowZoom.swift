import Foundation

public struct WindowFrame: Equatable, Sendable {
    public var x: Double
    public var y: Double
    public var width: Double
    public var height: Double

    public init(x: Double, y: Double, width: Double, height: Double) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
    }
}

public struct WindowZoomApplicationState: Equatable, Sendable {
    private var appliedWindowIDs: Set<String> = []

    public init() {}

    public mutating func shouldApplyInitialZoom(to windowID: String) -> Bool {
        appliedWindowIDs.insert(windowID).inserted
    }
}

public enum WindowZoom {
    public static let baseWidth = 360.0
    public static let baseHeight = 420.0
    public static let minimum = 0.6
    public static let maximum = 1.8
    public static let step = 0.1
    public static let reset = 1.0

    public static func clamp(_ value: Double) -> Double {
        min(maximum, max(minimum, value))
    }

    public static func zoomIn(from value: Double) -> Double {
        rounded(clamp(value + step))
    }

    public static func zoomOut(from value: Double) -> Double {
        rounded(clamp(value - step))
    }

    public static func size(for value: Double) -> (width: Double, height: Double) {
        let zoom = clamp(value)
        return (baseWidth * zoom, baseHeight * zoom)
    }

    public static func frame(for value: Double, currentFrame: WindowFrame) -> WindowFrame {
        let size = size(for: value)
        let currentTop = currentFrame.y + currentFrame.height
        return WindowFrame(
            x: currentFrame.x,
            y: currentTop - size.height,
            width: size.width,
            height: size.height
        )
    }

    private static func rounded(_ value: Double) -> Double {
        (value * 10).rounded() / 10
    }
}
