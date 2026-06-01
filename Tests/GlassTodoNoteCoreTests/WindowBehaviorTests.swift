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
        #expect(WindowZoom.size(for: 1.5).width == 540)
        #expect(WindowZoom.size(for: 1.5).height == 630)
    }

    @Test func resizedFrameKeepsTopLeftPinned() {
        let frame = WindowZoom.frame(
            for: 1.5,
            currentFrame: WindowFrame(x: 100, y: 200, width: 360, height: 420)
        )

        #expect(frame.x == 100)
        #expect(frame.y == -10)
        #expect(frame.width == 540)
        #expect(frame.height == 630)
    }

    @Test func initialZoomAppliesOnlyOncePerWindow() {
        var state = WindowZoomApplicationState()
        let firstMain = state.shouldApplyInitialZoom(to: "main")
        let secondMain = state.shouldApplyInitialZoom(to: "main")
        let replacement = state.shouldApplyInitialZoom(to: "replacement")

        #expect(firstMain)
        #expect(!secondMain)
        #expect(replacement)
    }
}
