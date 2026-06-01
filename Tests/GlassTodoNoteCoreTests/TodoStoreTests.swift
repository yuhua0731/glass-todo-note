import Foundation
import os
import Testing
@testable import GlassTodoNoteCore

@Suite(.serialized)
@MainActor
struct TodoStoreTests {
    @Test func progressIsClampedToValidRange() {
        var negative = TodoItem(title: "A", progress: -20)
        #expect(negative.progress == 0)

        negative.setProgress(120)
        #expect(negative.progress == 100)
    }

    @Test func reachingFullProgressMarksOnlyThatTodoAsCompleting() throws {
        let persistence = MemoryTodoPersistence()
        let store = TodoStore(persistence: persistence)
        let first = store.addTodo(title: "First")
        let second = store.addTodo(title: "Second")

        store.updateProgress(id: first.id, progress: 100)

        #expect(store.completingIDs == [first.id])
        #expect(store.todos.map(\.id) == [first.id, second.id])
        #expect(store.hasIncompleteTodos)
    }

    @Test func completingTodoIgnoresLaterProgressChanges() {
        let store = TodoStore(persistence: MemoryTodoPersistence())
        let todo = store.addTodo(title: "Complete")

        store.updateProgress(id: todo.id, progress: 100)
        store.updateProgress(id: todo.id, progress: 50)

        #expect(store.todos.first?.progress == 100)
        #expect(store.completingIDs == [todo.id])
    }

    @Test func completingTodoIsPendingForAnimationConsumption() {
        let store = TodoStore(persistence: MemoryTodoPersistence())
        let todo = store.addTodo(title: "Animate")

        store.updateProgress(id: todo.id, progress: 100)

        #expect(store.consumePendingCompletionIDs() == [todo.id])
        #expect(store.pendingCompletionIDs.isEmpty)
    }

    @Test func addTodoDoesNotCreateAlreadyCompletingTodo() {
        let store = TodoStore(persistence: MemoryTodoPersistence())

        let todo = store.addTodo(title: "New", progress: 100)

        #expect(todo.progress == 99)
        #expect(store.completingIDs.isEmpty)
        #expect(store.hasIncompleteTodos)
    }

    @Test func addTodoUsesUntitledFallbackForBlankTitle() {
        let store = TodoStore(persistence: MemoryTodoPersistence())

        let todo = store.addTodo(title: "  ")

        #expect(todo.title == "Untitled Task")
    }

    @Test func finishCompletionRemovesCompletedTodo() {
        let store = TodoStore(persistence: MemoryTodoPersistence())
        let todo = store.addTodo(title: "Finish")

        store.updateProgress(id: todo.id, progress: 100)
        store.finishCompletion(id: todo.id)

        #expect(store.todos.isEmpty)
        #expect(store.completingIDs.isEmpty)
        #expect(!store.hasIncompleteTodos)
    }

    @Test func todoStorePersistsAndReloadsTodos() async {
        let persistence = MemoryTodoPersistence()
        let firstStore = TodoStore(persistence: persistence)
        let todo = firstStore.addTodo(title: "Persist me", progress: 40)
        await firstStore.flushPendingSaves()

        let reloadedStore = TodoStore(persistence: persistence)
        await reloadedStore.loadFromPersistence()

        #expect(reloadedStore.todos == [todo])
        #expect(reloadedStore.completingIDs.isEmpty)
    }

    @Test func reloadingStoreWithCompleteTodoRemovesItAsAlreadyDone() async {
        let persistence = MemoryTodoPersistence()
        let firstStore = TodoStore(persistence: persistence)
        let todo = firstStore.addTodo(title: "Complete me")

        firstStore.updateProgress(id: todo.id, progress: 100)
        await firstStore.flushPendingSaves()
        let reloadedStore = TodoStore(persistence: persistence)
        await reloadedStore.loadFromPersistence()

        #expect(reloadedStore.todos.isEmpty)
        #expect(reloadedStore.completingIDs.isEmpty)
        #expect(reloadedStore.consumePendingCompletionIDs().isEmpty)
        #expect(reloadedStore.pendingCompletionIDs.isEmpty)
        #expect(!reloadedStore.hasIncompleteTodos)
    }

    @Test func persistenceFailureSetsVisibleError() async {
        let store = TodoStore(persistence: FailingSavePersistence())

        store.addTodo(title: "Cannot save")
        await store.flushPendingSaves()

        #expect(store.lastPersistenceError == "save failed")
        #expect(store.todos.count == 1)
    }

    @Test func loadFailureStartsEmptyAndExposesError() async {
        let store = TodoStore(persistence: FailingLoadPersistence())
        await store.loadFromPersistence()

        #expect(store.todos.isEmpty)
        #expect(store.lastPersistenceError == "load failed")
        #expect(store.hasLoaded)
        #expect(!store.canPersist)
    }

    @Test func loadFailurePreventsOverwritingExistingPersistence() async throws {
        let persistence = ToggleLoadFailurePersistence(todos: [TodoItem(title: "Existing")])
        let store = TodoStore(persistence: persistence)

        persistence.shouldFailLoad = true
        await store.loadFromPersistence()
        store.addTodo(title: "New")
        await store.flushPendingSaves()

        persistence.shouldFailLoad = false
        let savedTodos = try persistence.load()
        #expect(savedTodos.map(\.title) == ["Existing"])
    }

    @Test func loadFromPersistenceRunsOnlyOnceByDefault() async {
        let persistence = MemoryTodoPersistence()
        let store = TodoStore(persistence: persistence)

        store.addTodo(title: "Unsaved screen state")
        await store.loadFromPersistence()

        #expect(store.todos.map(\.title) == ["Unsaved screen state"])
    }

    @Test func rapidProgressUpdatesPersistOnlyFinalProgress() async throws {
        let persistence = CountingTodoPersistence()
        let store = TodoStore(persistence: persistence)
        let todo = store.addTodo(title: "Drag")
        await store.flushPendingSaves()

        for progress in stride(from: 5.0, through: 75.0, by: 5.0) {
            store.updateProgress(id: todo.id, progress: progress)
        }
        await store.flushPendingSaves()

        let savedTodo = try #require(persistence.savedTodos.first)
        #expect(savedTodo.progress == 75)
        #expect(persistence.saveCallCount == 2)
    }

    @Test func updateTitleUsesFallbackForBlankTitles() {
        let store = TodoStore(persistence: MemoryTodoPersistence())
        let initialDate = Date(timeIntervalSince1970: 1)
        let updatedDate = Date(timeIntervalSince1970: 2)
        let todo = store.addTodo(title: "Named", at: initialDate)

        store.updateTitle(id: todo.id, title: "  ", at: updatedDate)

        #expect(store.todos.first?.title == "Untitled Task")
        #expect(store.todos.first?.updatedAt == updatedDate)
    }

    @Test func deleteTodoRemovesTodoAndCompletionState() {
        let store = TodoStore(persistence: MemoryTodoPersistence())
        let todo = store.addTodo(title: "Delete")

        store.updateProgress(id: todo.id, progress: 100)
        store.deleteTodo(id: todo.id)

        #expect(store.todos.isEmpty)
        #expect(store.completingIDs.isEmpty)
    }
}

private final class MemoryTodoPersistence: TodoPersisting {
    private let todos = OSAllocatedUnfairLock(initialState: [TodoItem]())

    func load() throws -> [TodoItem] {
        todos.withLock { $0 }
    }

    func save(_ todos: [TodoItem]) throws {
        self.todos.withLock { $0 = todos }
    }
}

private final class CountingTodoPersistence: TodoPersisting {
    private let state = OSAllocatedUnfairLock(initialState: State())

    var savedTodos: [TodoItem] {
        state.withLock { $0.todos }
    }

    var saveCallCount: Int {
        state.withLock { $0.saveCallCount }
    }

    func load() throws -> [TodoItem] {
        state.withLock { $0.todos }
    }

    func save(_ todos: [TodoItem]) throws {
        state.withLock {
            $0.todos = todos
            $0.saveCallCount += 1
        }
    }

    private struct State {
        var todos: [TodoItem] = []
        var saveCallCount = 0
    }
}

private final class ToggleLoadFailurePersistence: TodoPersisting {
    private let state: OSAllocatedUnfairLock<State>

    var shouldFailLoad: Bool {
        get {
            state.withLock { $0.shouldFailLoad }
        }
        set {
            state.withLock { $0.shouldFailLoad = newValue }
        }
    }

    init(todos: [TodoItem]) {
        state = OSAllocatedUnfairLock(initialState: State(todos: todos))
    }

    func load() throws -> [TodoItem] {
        try state.withLock {
            if $0.shouldFailLoad {
                throw TestPersistenceError(message: "load failed")
            }
            return $0.todos
        }
    }

    func save(_ todos: [TodoItem]) throws {
        state.withLock {
            $0.todos = todos
        }
    }

    private struct State {
        var todos: [TodoItem]
        var shouldFailLoad = false
    }
}

private struct FailingSavePersistence: TodoPersisting {
    func load() throws -> [TodoItem] {
        []
    }

    func save(_ todos: [TodoItem]) throws {
        throw TestPersistenceError(message: "save failed")
    }
}

private struct FailingLoadPersistence: TodoPersisting {
    func load() throws -> [TodoItem] {
        throw TestPersistenceError(message: "load failed")
    }

    func save(_ todos: [TodoItem]) throws {}
}

private struct TestPersistenceError: LocalizedError {
    let message: String

    var errorDescription: String? {
        message
    }
}
