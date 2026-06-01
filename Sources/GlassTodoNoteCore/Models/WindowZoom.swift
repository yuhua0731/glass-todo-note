import Foundation

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

    private static func rounded(_ value: Double) -> Double {
        (value * 10).rounded() / 10
    }
}
