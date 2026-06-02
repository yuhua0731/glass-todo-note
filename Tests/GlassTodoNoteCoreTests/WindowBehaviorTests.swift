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
        #expect(WindowZoom.clamp(0.3) == 0.6)
        #expect(WindowZoom.clamp(2.5) == 1.8)
        #expect(WindowZoom.zoomIn(from: 1.0) == 1.1)
        #expect(WindowZoom.zoomOut(from: 1.0) == 0.9)
        #expect(WindowZoom.reset == 1.0)
        #expect(WindowZoom.contentScale(for: 1.5) == 1.5)
    }

    @Test func contentZoomDoesNotChangeWindowBaseSize() {
        #expect(WindowZoom.windowSize.width == 360)
        #expect(WindowZoom.windowSize.height == 420)
    }

    @Test func zoomedContentLayoutSizeStaysAtWindowSize() {
        #expect(WindowZoom.contentLayoutSize(for: 0.6).width == 360)
        #expect(WindowZoom.contentLayoutSize(for: 1.8).height == 420)
    }
}
