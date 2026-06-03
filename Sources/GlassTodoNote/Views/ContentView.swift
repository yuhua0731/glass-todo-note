import AppKit
import GlassTodoNoteCore
import SwiftUI

struct ContentView: View {
    @Bindable var store: TodoStore
    var onWindowDragStart: () -> Void = {}
    @State private var newTitle = ""
    @AppStorage("window.opacity") private var windowOpacity = 0.86
    @AppStorage("window.floatsAboveWindows") private var floatsAboveWindows = true
    @AppStorage("window.backgroundMode") private var backgroundMode = BackgroundMode.preset.rawValue
    @AppStorage("window.backgroundAppearance") private var backgroundAppearance = BackgroundAppearance.glass.rawValue
    @AppStorage("window.backgroundColorHex") private var backgroundColorHex = StoredBackgroundColor.defaultHex
    @AppStorage("window.backgroundImagePath") private var backgroundImagePath = ""
    @AppStorage("window.backgroundImageRevision") private var backgroundImageRevision = ""
    @AppStorage("window.zoom") private var windowZoom = WindowZoom.reset
    @State private var shatteringIDs: Set<TodoItem.ID> = []
    @State private var bubbleBursts: [BubbleBurst] = []
    private let completionTiming = CompletionAnimationTiming()

    var body: some View {
        ZStack(alignment: .topLeading) {
            noteBackground
            zoomedContent
        }
        .frame(
            width: WindowZoom.contentWidth(for: windowZoom),
            height: WindowZoom.contentHeight(todoCount: store.todos.count, for: windowZoom),
            alignment: .topLeading
        )
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
        return VStack(alignment: .leading, spacing: metric(14)) {
            header
            addRow
            todoList
        }
        .padding(metric(20))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    @ViewBuilder
    private var noteBackground: some View {
        switch currentBackgroundMode {
        case .preset:
            presetBackground
        case .solidColor:
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(storedHex: backgroundColorHex).opacity(backgroundOpacity))
        case .image:
            imageBackground
        }
    }

    private var header: some View {
        HStack(spacing: metric(10)) {
            ZStack(alignment: .leading) {
                WindowDragHandle(onDragStart: onWindowDragStart)
                Text("Glass Todo")
                    .font(.system(size: metric(16), weight: .semibold))
                    .allowsHitTesting(false)
            }
            .frame(maxWidth: .infinity, minHeight: metric(28), alignment: .leading)
            SettingsLink {
                Image(systemName: "gearshape")
                    .font(.system(size: metric(16), weight: .medium))
            }
            .buttonStyle(.borderless)
            .help("Settings")
        }
    }

    private var addRow: some View {
        HStack(spacing: metric(8)) {
            TextField("New task", text: $newTitle)
                .textFieldStyle(.plain)
                .font(.system(size: metric(14)))
                .padding(.horizontal, metric(8))
                .frame(height: metric(28))
                .background(.quaternary.opacity(0.35), in: RoundedRectangle(cornerRadius: 5, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .stroke(.quaternary, lineWidth: 1)
                }
                .onSubmit(addTodo)
            Button(action: addTodo) {
                Image(systemName: "plus")
                    .font(.system(size: metric(14), weight: .medium))
                    .frame(width: metric(28), height: metric(28))
                    .background(.tint.opacity(0.72), in: RoundedRectangle(cornerRadius: 5, style: .continuous))
            }
            .buttonStyle(.plain)
            .foregroundStyle(.white)
            .disabled(newTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .opacity(newTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.45 : 1)
            .help("Add task")
        }
    }

    private var todoList: some View {
        ScrollView {
            LazyVStack(spacing: metric(10)) {
                ForEach(store.todos) { todo in
                    TodoRowView(
                        todo: todo,
                        isCompleting: store.completingIDs.contains(todo.id),
                        isShattering: shatteringIDs.contains(todo.id),
                        zoom: WindowZoom.contentScale(for: windowZoom),
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
                        .font(.system(size: metric(13)))
                        .frame(maxWidth: .infinity, minHeight: metric(180))
                }
            }
        }
        .frame(height: CGFloat(WindowZoom.listHeight(todoCount: store.todos.count, for: windowZoom)))
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

    private var presetBackground: some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .fill(backgroundStyle.material)
            .opacity(backgroundOpacity)
            .overlay {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(backgroundStyle.tint)
                    .opacity(backgroundOpacity)
            }
    }

    @ViewBuilder
    private var imageBackground: some View {
        if let backgroundImage {
            Image(nsImage: backgroundImage)
                .resizable()
                .scaledToFill()
                .opacity(backgroundOpacity)
                .id(backgroundImageRevision)
        } else {
            presetBackground
        }
    }

    private var backgroundImage: NSImage? {
        guard currentBackgroundMode == .image,
              !backgroundImagePath.isEmpty else {
            return nil
        }
        _ = backgroundImageRevision
        return NSImage(contentsOf: URL(fileURLWithPath: backgroundImagePath))
    }

    private var currentBackgroundMode: BackgroundMode {
        BackgroundMode(rawValue: backgroundMode) ?? .preset
    }

    private var backgroundOpacity: Double {
        WindowPreferences(opacity: windowOpacity).opacity
    }

    private func metric(_ baseValue: Double) -> CGFloat {
        CGFloat(WindowZoom.metric(baseValue, for: windowZoom))
    }
}

private struct BubbleBurst: Identifiable, Equatable {
    let id = UUID()
    let seed = Int.random(in: 0..<10_000)
}
