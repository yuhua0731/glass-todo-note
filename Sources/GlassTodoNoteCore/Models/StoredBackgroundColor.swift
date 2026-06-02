import Foundation

public enum StoredBackgroundColor {
    public static let defaultHex = "#315A3A"

    public static func normalizedHex(_ value: String) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        let raw = trimmed.hasPrefix("#") ? String(trimmed.dropFirst()) : trimmed
        guard raw.count == 6,
              raw.allSatisfy(\.isHexDigit) else {
            return defaultHex
        }
        return "#\(raw.uppercased())"
    }
}
