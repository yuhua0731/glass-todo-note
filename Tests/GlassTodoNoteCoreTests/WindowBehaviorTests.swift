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

    @Test func windowZoomClampsAndStepsPredictably() {
        #expect(WindowZoom.zoomIn(from: 1.0) == 1.1)
        #expect(WindowZoom.zoomIn(from: -2.0) == 1.1)
        #expect(abs(WindowZoom.zoomOut(from: 1.0) - 0.909) < 0.001)
        #expect(WindowZoom.zoomOut(from: 0.5) < 0.5)
        #expect(WindowZoom.contentScale(for: -2.0) == 1.0)
        #expect(WindowZoom.sanitizedStoredValue(-2.0) == 1.0)
        #expect(WindowZoom.reset == 1.0)
        #expect(WindowZoom.contentScale(for: 1.5) == 1.5)
        #expect(WindowZoom.metric(20, for: 1.5) == 30)
    }

    @Test func contentWidthScalesWithZoom() {
        #expect(WindowZoom.contentWidth(for: 0.6) == 216)
        #expect(WindowZoom.contentWidth(for: 1.0) == 360)
        #expect(WindowZoom.contentWidth(for: 1.8) == 648)
    }

    @Test func windowContentHeightAdaptsToTaskCount() {
        #expect(WindowZoom.contentHeight(todoCount: 0, for: 1.0) == 304)
        #expect(WindowZoom.contentHeight(todoCount: 2, for: 1.0) == 278)
        #expect(WindowZoom.contentHeight(todoCount: 10, for: 1.0) == 544)
        #expect(WindowZoom.contentHeight(todoCount: 2, for: 1.5) == 417)
        #expect(WindowZoom.listHeight(todoCount: 10, for: 10) == 420)
    }
}
