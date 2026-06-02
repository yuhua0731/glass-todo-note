import Foundation

public enum BackgroundMode: String, CaseIterable, Identifiable, Sendable {
    case preset
    case solidColor
    case image

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .preset: "Preset"
        case .solidColor: "Solid Color"
        case .image: "Local Image"
        }
    }
}
