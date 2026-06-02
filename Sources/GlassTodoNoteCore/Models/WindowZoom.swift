import Foundation

public enum WindowZoom {
    public static let baseWidth = 360.0
    public static let step = 0.1
    public static let reset = 1.0

    public static func zoomIn(from value: Double) -> Double {
        positiveScale(value) * (1 + step)
    }

    public static func zoomOut(from value: Double) -> Double {
        positiveScale(value) / (1 + step)
    }

    public static func contentLayoutSize(for value: Double) -> (width: Double, height: Double) {
        (contentWidth(for: value), contentHeight(todoCount: 0, for: value))
    }

    public static func contentWidth(for value: Double) -> Double {
        metric(baseWidth, for: value)
    }

    public static func contentHeight(todoCount: Int, for value: Double) -> Double {
        metric(20, for: value) * 2
            + metric(24, for: value)
            + metric(14, for: value)
            + metric(32, for: value)
            + metric(14, for: value)
            + listHeight(todoCount: todoCount, for: value)
    }

    public static func listHeight(todoCount: Int, for value: Double) -> Double {
        guard todoCount > 0 else {
            return metric(180, for: value)
        }
        let rowHeight = metric(72, for: value)
        let gapHeight = metric(10, for: value) * Double(max(0, todoCount - 1))
        return min(420, rowHeight * Double(todoCount) + gapHeight)
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
