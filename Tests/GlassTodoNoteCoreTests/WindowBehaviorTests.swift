import Foundation
import Testing
@testable import GlassTodoNoteCore

struct WindowBehaviorTests {
    @Test func windowOpacityIsClampedToUsableRange() {
        #expect(WindowPreferences(opacity: -1).opacity == 0.2)
        #expect(WindowPreferences(opacity: 2).opacity == 1)
    }

    @Test func shakePlanRunsForThreeSecondsAndReturnsToOrigin() {
        let plan = WindowShakePlan(duration: 3, amplitude: 8, stepsPerSecond: 10)

        #expect(plan.duration == 3)
        #expect(plan.offsets.count == 31)
        #expect(plan.offsets.first == 0)
        #expect(plan.offsets.last == 0)
    }

    @Test func shakePlanIsDeterministic() {
        let first = WindowShakePlan(duration: 3, amplitude: 8, stepsPerSecond: 10)
        let second = WindowShakePlan(duration: 3, amplitude: 8, stepsPerSecond: 10)

        #expect(first.offsets == second.offsets)
        #expect(first.offsets.contains(8))
        #expect(first.offsets.contains(-8))
    }
}
