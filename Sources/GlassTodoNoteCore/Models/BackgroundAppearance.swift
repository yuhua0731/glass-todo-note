import Foundation

public enum BackgroundAppearance: String, CaseIterable, Identifiable, Sendable {
    case glass
    case graphite
    case meadow
    case blush

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .glass: "Glass"
        case .graphite: "Graphite"
        case .meadow: "Meadow"
        case .blush: "Blush"
        }
    }
}
