import Foundation

public struct ReminderScheduler: Sendable {
    public static let reminderMinutes: Set<Int> = [0, 10, 20, 30, 40, 50]

    public var calendar: Calendar

    public init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    public func shouldShake(
        at date: Date,
        hasIncompleteTodos: Bool,
        lastFiredAt: Date? = nil
    ) -> Bool {
        guard hasIncompleteTodos, let slot = reminderSlot(containing: date) else {
            return false
        }
        guard let lastFiredAt else {
            return true
        }
        return reminderSlot(containing: lastFiredAt) != slot
    }

    public func reminderSlot(containing date: Date) -> Date? {
        let components = calendar.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: date
        )
        guard
            let minute = components.minute,
            let second = components.second,
            Self.reminderMinutes.contains(minute),
            (0..<5).contains(second)
        else {
            return nil
        }

        var slotComponents = components
        slotComponents.second = 0
        return calendar.date(from: slotComponents)
    }
}
