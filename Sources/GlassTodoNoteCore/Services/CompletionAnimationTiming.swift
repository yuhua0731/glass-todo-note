import Foundation

public struct CompletionAnimationTiming: Equatable, Sendable {
    public let rowRemovalDelay: Duration
    public let bubbleLifetime: Duration

    public init(
        rowRemovalDelay: Duration = .milliseconds(900),
        bubbleLifetime: Duration = .seconds(2)
    ) {
        self.rowRemovalDelay = rowRemovalDelay
        self.bubbleLifetime = bubbleLifetime
    }
}
