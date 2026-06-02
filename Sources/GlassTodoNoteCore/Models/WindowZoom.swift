import Foundation

public enum WindowZoom {
    public static let baseWidth = 360.0
    public static let baseHeight = 420.0
    public static let step = 0.1
    public static let reset = 1.0

    public static func zoomIn(from value: Double) -> Double {
        positiveScale(value) * (1 + step)
    }

    public static func zoomOut(from value: Double) -> Double {
        positiveScale(value) / (1 + step)
    }

    public static var windowSize: (width: Double, height: Double) {
        (baseWidth, baseHeight)
    }

    public static func contentLayoutSize(for value: Double) -> (width: Double, height: Double) {
        windowSize
    }

    public static func contentScale(for value: Double) -> Double {
        positiveScale(value)
    }

    public static func sanitizedStoredValue(_ value: Double) -> Double {
        positiveScale(value)
    }

    public static func metric(_ baseValue: Double, for value: Double) -> Double {
        (baseValue * contentScale(for: value) * 10).rounded() / 10
    }

    private static func positiveScale(_ value: Double) -> Double {
        value > 0 ? value : reset
    }

}
