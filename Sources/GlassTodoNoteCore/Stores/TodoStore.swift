import Foundation
import Observation

@MainActor
@Observable
public final class TodoStore {
    public private(set) var todos: [TodoItem]
    public private(set) var completingIDs: Set<TodoItem.ID> = []
    public private(set) var pendingCompletionIDs: Set<TodoItem.ID> = []
    public private(set) var lastPersistenceError: String?
    public private(set) var hasLoaded = false
    public private(set) var canPersist = true

    @ObservationIgnored private let persistenceWriter: TodoPersistenceWriter
    @ObservationIgnored private var persistenceChain = Task<Void, Never> {}
    @ObservationIgnored private var debouncedPersistenceTask: Task<Void, Never>?

    public init(persistence: TodoPersisting = JSONTodoPersistence.applicationSupport) {
        self.persistenceWriter = TodoPersistenceWriter(persistence: persistence)
        todos = []
    }

    public func loadFromPersistence(force: Bool = false) async {
        guard force || !hasLoaded else { return }
        await flushPendingSaves()
        do {
            let loadedTodos = try await persistenceWriter.load()
            todos = loadedTodos.filter { !$0.isComplete }
            completingIDs = []
            pendingCompletionIDs = []
            lastPersistenceError = nil
            hasLoaded = true
            canPersist = true
            if todos.count != loadedTodos.count {
                enqueueSave(todos)
            }
        } catch {
            todos = []
            completingIDs = []
            pendingCompletionIDs = []
            lastPersistenceError = error.localizedDescription
            hasLoaded = true
            canPersist = false
        }
    }

    public var hasIncompleteTodos: Bool {
        todos.contains { !$0.isComplete && !completingIDs.contains($0.id) }
    }

    /// Adds a user-created todo. Initial progress is clamped to `0...99` so
    /// completion always enters through `updateProgress`.
    @discardableResult
    public func addTodo(title: String, progress: Double = 0, at date: Date = Date()) -> TodoItem {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let todo = TodoItem(
            title: trimmedTitle.isEmpty ? "Untitled Task" : trimmedTitle,
            // New rows should never skip the row-bounded completion animation path.
            progress: min(TodoItem.clamp(progress), 99),
            createdAt: date,
            updatedAt: date
        )
        todos.append(todo)
        persistImmediately()
        return todo
    }

    public func updateTitle(id: TodoItem.ID, title: String, at date: Date = Date()) {
        guard let index = todos.firstIndex(where: { $0.id == id }) else { return }
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        todos[index].title = trimmedTitle.isEmpty ? "Untitled Task" : trimmedTitle
        todos[index].updatedAt = date
        persistImmediately()
    }

    public func updateProgress(id: TodoItem.ID, progress: Double, at date: Date = Date()) {
        guard !completingIDs.contains(id) else { return }
        guard let index = todos.firstIndex(where: { $0.id == id }) else { return }
        todos[index].setProgress(progress, at: date)
        if todos[index].isComplete {
            completingIDs.insert(id)
            pendingCompletionIDs.insert(id)
            persistImmediately()
        } else {
            completingIDs.remove(id)
            pendingCompletionIDs.remove(id)
            persistDebounced()
        }
    }

    public func deleteTodo(id: TodoItem.ID) {
        todos.removeAll { $0.id == id }
        completingIDs.remove(id)
        pendingCompletionIDs.remove(id)
        persistImmediately()
    }

    public func finishCompletion(id: TodoItem.ID) {
        deleteTodo(id: id)
    }

    public func consumePendingCompletionIDs() -> Set<TodoItem.ID> {
        defer { pendingCompletionIDs = [] }
        return pendingCompletionIDs
    }

    public func flushPendingSaves() async {
        await debouncedPersistenceTask?.value
        await persistenceChain.value
    }

    private func persistImmediately() {
        guard canPersist else { return }
        debouncedPersistenceTask?.cancel()
        enqueueSave(todos)
    }

    private func persistDebounced() {
        guard canPersist else { return }
        let snapshot = todos
        debouncedPersistenceTask?.cancel()
        debouncedPersistenceTask = Task {
            do {
                try await Task.sleep(for: .milliseconds(300))
                try Task.checkCancellation()
                self.enqueueSave(snapshot)
            } catch is CancellationError {
            } catch {
                await MainActor.run {
                    self.lastPersistenceError = error.localizedDescription
                }
            }
        }
    }

    private func enqueueSave(_ snapshot: [TodoItem]) {
        let writer = persistenceWriter
        let previousSave = persistenceChain
        persistenceChain = Task { [weak self] in
            await previousSave.value
            do {
                try await writer.save(snapshot)
                await MainActor.run {
                    self?.lastPersistenceError = nil
                }
            } catch {
                await MainActor.run {
                    self?.lastPersistenceError = error.localizedDescription
                }
            }
        }
    }
}

private actor TodoPersistenceWriter {
    let persistence: TodoPersisting

    init(persistence: TodoPersisting) {
        self.persistence = persistence
    }

    func load() throws -> [TodoItem] {
        try persistence.load()
    }

    func save(_ todos: [TodoItem]) throws {
        try persistence.save(todos)
    }
}
