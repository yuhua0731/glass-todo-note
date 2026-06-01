import Foundation

public struct WindowPreferences: Equatable, Sendable {
    public var opacity: Double
    public var floatsAboveWindows: Bool
    public var reminderShakeEnabled: Bool
    public var cornerRadius: Double

    public init(
        opacity: Double = 0.86,
        floatsAboveWindows: Bool = true,
        reminderShakeEnabled: Bool = true,
        cornerRadius: Double = 24
    ) {
        self.opacity = min(1, max(0.2, opacity))
        self.floatsAboveWindows = floatsAboveWindows
        self.reminderShakeEnabled = reminderShakeEnabled
        self.cornerRadius = max(8, cornerRadius)
    }
}
