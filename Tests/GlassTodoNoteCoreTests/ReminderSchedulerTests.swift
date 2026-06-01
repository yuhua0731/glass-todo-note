import Foundation
import Testing
@testable import GlassTodoNoteCore

struct ReminderSchedulerTests {
    private let scheduler = ReminderScheduler(calendar: .stableGMT)

    @Test func firesOnTenMinuteWallClockBoundariesWhenTodosRemain() {
        #expect(scheduler.shouldShake(at: .stable("2026-06-01 10:00:00"), hasIncompleteTodos: true))
        #expect(scheduler.shouldShake(at: .stable("2026-06-01 10:10:00"), hasIncompleteTodos: true))
        #expect(scheduler.shouldShake(at: .stable("2026-06-01 10:50:00"), hasIncompleteTodos: true))
    }

    @Test func doesNotFireOutsideExactBoundarySecond() {
        #expect(!scheduler.shouldShake(at: .stable("2026-06-01 10:09:59"), hasIncompleteTodos: true))
        #expect(scheduler.shouldShake(at: .stable("2026-06-01 10:10:01"), hasIncompleteTodos: true))
        #expect(scheduler.shouldShake(at: .stable("2026-06-01 10:10:04"), hasIncompleteTodos: true))
        #expect(!scheduler.shouldShake(at: .stable("2026-06-01 10:10:05"), hasIncompleteTodos: true))
        #expect(!scheduler.shouldShake(at: .stable("2026-06-01 10:11:00"), hasIncompleteTodos: true))
    }

    @Test func doesNotFireWithoutIncompleteTodos() {
        #expect(!scheduler.shouldShake(at: .stable("2026-06-01 10:20:00"), hasIncompleteTodos: false))
    }

    @Test func doesNotFireTwiceForSameBoundarySlot() {
        let slot = Date.stable("2026-06-01 10:30:00")

        #expect(!scheduler.shouldShake(
            at: slot,
            hasIncompleteTodos: true,
            lastFiredAt: slot
        ))
    }

    @Test func firesAgainAtNextBoundarySlot() {
        #expect(scheduler.shouldShake(
            at: .stable("2026-06-01 10:40:00"),
            hasIncompleteTodos: true,
            lastFiredAt: .stable("2026-06-01 10:30:00")
        ))
    }
}

private extension Calendar {
    static var stableGMT: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }
}

private extension Date {
    static func stable(_ value: String) -> Date {
        DateFormatter.stable.date(from: value)!
    }
}

private extension DateFormatter {
    static let stable: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = .stableGMT
        formatter.timeZone = TimeZone(secondsFromGMT: 0)!
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter
    }()
}
