import Testing
@testable import GlassTodoNoteCore

struct CompletionAnimationTimingTests {
    @Test func defaultTimingKeepsRowLongEnoughForShatterBeforeRemoval() {
        let timing = CompletionAnimationTiming()

        #expect(timing.rowRemovalDelay == .milliseconds(900))
        #expect(timing.bubbleLifetime == .seconds(2))
    }
}
