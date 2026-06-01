import Foundation

public struct WindowShakePlan: Equatable, Sendable {
    public let duration: TimeInterval
    public let amplitude: Double
    public let stepsPerSecond: Int
    public let offsets: [Double]

    public init(duration: TimeInterval = 3, amplitude: Double = 8, stepsPerSecond: Int = 30) {
        self.duration = duration
        self.amplitude = amplitude
        self.stepsPerSecond = max(1, stepsPerSecond)

        let stepCount = Int((duration * Double(self.stepsPerSecond)).rounded())
        offsets = (0...stepCount).map { step in
            guard step != 0, step != stepCount else { return 0 }
            return step.isMultiple(of: 2) ? amplitude : -amplitude
        }
    }
}
