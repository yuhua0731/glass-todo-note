import GlassTodoNoteCore
import SwiftUI

struct ContentView: View {
    @Bindable var store: TodoStore
    @State private var newTitle = ""
    @AppStorage("window.floatsAboveWindows") private var floatsAboveWindows = true
    @AppStorage("window.backgroundAppearance") private var backgroundAppearance = BackgroundAppearance.glass.rawValue
    @AppStorage("window.zoom") private var windowZoom = WindowZoom.reset
    @State private var shatteringIDs: Set<TodoItem.ID> = []
    @State private var bubbleBursts: [BubbleBurst] = []
    private let completionTiming = CompletionAnimationTiming()

    var body: some View {
        ZStack(alignment: .topLeading) {
            noteBackground
            zoomedContent
        }
        .frame(minWidth: WindowZoom.windowSize.width, minHeight: WindowZoom.windowSize.height)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(.quaternary, lineWidth: 1)
        }
        .overlay(alignment: .top) {
            ForEach(bubbleBursts) { burst in
                BubbleCelebrationView(seed: burst.seed)
                    .allowsHitTesting(false)
            }
        }
    }

    private var zoomedContent: some View {
        let scale = WindowZoom.contentScale(for: windowZoom)
        return VStack(alignment: .leading, spacing: 14) {
            header
            addRow
            todoList
        }
        .padding(20)
        .frame(
            width: WindowZoom.contentLayoutSize(for: windowZoom).width,
            height: WindowZoom.contentLayoutSize(for: windowZoom).height,
            alignment: .topLeading
        )
        .scaleEffect(scale, anchor: .topLeading)
    }

    private var noteBackground: some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .fill(backgroundStyle.material)
            .overlay {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(backgroundStyle.tint)
            }
    }

    private var header: some View {
        HStack(spacing: 10) {
            Text("Glass Todo")
                .font(.headline)
            Spacer()
            SettingsLink {
                Image(systemName: "gearshape")
            }
            .buttonStyle(.borderless)
            .help("Settings")
        }
    }

    private var addRow: some View {
        HStack(spacing: 8) {
            TextField("New task", text: $newTitle)
                .textFieldStyle(.roundedBorder)
                .onSubmit(addTodo)
            Button(action: addTodo) {
                Image(systemName: "plus")
            }
            .buttonStyle(.borderedProminent)
            .disabled(newTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .help("Add task")
        }
    }

    private var todoList: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                ForEach(store.todos) { todo in
                    TodoRowView(
                        todo: todo,
                        isCompleting: store.completingIDs.contains(todo.id),
                        isShattering: shatteringIDs.contains(todo.id),
                        onTitleChange: { title in
                            store.updateTitle(id: todo.id, title: title)
                        },
                        onProgressChange: { progress in
                            store.updateProgress(id: todo.id, progress: progress)
                        },
                        onDelete: {
                            store.deleteTodo(id: todo.id)
                        }
                    )
                    .overlay {
                        if shatteringIDs.contains(todo.id) {
                            GlassShatterView()
                        }
                    }
                    .animation(.easeInOut(duration: 0.2), value: shatteringIDs)
                }
                if store.todos.isEmpty {
                    ContentUnavailableView("No Tasks", systemImage: "checkmark.circle")
                        .frame(maxWidth: .infinity, minHeight: 180)
                }
            }
        }
        .scrollIndicators(.hidden)
        .onChange(of: store.pendingCompletionIDs) { _, _ in
            consumeCompletions()
        }
    }

    private func addTodo() {
        let title = newTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return }
        store.addTodo(title: title)
        newTitle = ""
    }

    private func consumeCompletions() {
        let ids = store.consumePendingCompletionIDs()
        guard !ids.isEmpty else { return }
        shatteringIDs.formUnion(ids)
        let burst = BubbleBurst()
        bubbleBursts.append(burst)

        for id in ids {
            Task {
                try? await Task.sleep(for: completionTiming.rowRemovalDelay)
                await MainActor.run {
                    shatteringIDs.remove(id)
                    store.finishCompletion(id: id)
                }
            }
        }

        Task {
            try? await Task.sleep(for: completionTiming.bubbleLifetime)
            await MainActor.run {
                bubbleBursts.removeAll { $0.id == burst.id }
            }
        }
    }

    private var backgroundStyle: (material: Material, tint: Color) {
        switch BackgroundAppearance(rawValue: backgroundAppearance) ?? .glass {
        case .glass:
            (.regularMaterial, .clear)
        case .graphite:
            (.regularMaterial, .gray.opacity(0.18))
        case .meadow:
            (.regularMaterial, .green.opacity(0.14))
        case .blush:
            (.regularMaterial, .pink.opacity(0.13))
        }
    }
}

private struct BubbleBurst: Identifiable, Equatable {
    let id = UUID()
    let seed = Int.random(in: 0..<10_000)
}
