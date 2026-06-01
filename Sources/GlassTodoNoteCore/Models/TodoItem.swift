import Foundation

public struct TodoItem: Codable, Equatable, Identifiable, Sendable {
    public let id: UUID
    public var title: String
    public private(set) var progress: Double
    public let createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        title: String,
        progress: Double = 0,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.progress = Self.clamp(progress)
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    public var isComplete: Bool {
        progress >= 100
    }

    public mutating func setProgress(_ value: Double, at date: Date = Date()) {
        progress = Self.clamp(value)
        updatedAt = date
    }

    public static func clamp(_ value: Double) -> Double {
        min(100, max(0, value))
    }
}
