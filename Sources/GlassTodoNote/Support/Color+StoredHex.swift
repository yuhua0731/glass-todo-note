import AppKit
import GlassTodoNoteCore
import SwiftUI

extension Color {
    init(storedHex: String) {
        let hex = StoredBackgroundColor.normalizedHex(storedHex)
        let raw = String(hex.dropFirst())
        let value = Int(raw, radix: 16) ?? 0
        self.init(
            red: Double((value >> 16) & 0xFF) / 255,
            green: Double((value >> 8) & 0xFF) / 255,
            blue: Double(value & 0xFF) / 255
        )
    }

    func storedHexString() -> String {
        guard let color = NSColor(self).usingColorSpace(.sRGB) else {
            return StoredBackgroundColor.defaultHex
        }
        return String(
            format: "#%02X%02X%02X",
            Int((color.redComponent * 255).rounded()),
            Int((color.greenComponent * 255).rounded()),
            Int((color.blueComponent * 255).rounded())
        )
    }
}
