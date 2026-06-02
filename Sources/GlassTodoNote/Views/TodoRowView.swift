import GlassTodoNoteCore
import SwiftUI

struct TodoRowView: View {
    let todo: TodoItem
    let isCompleting: Bool
    let isShattering: Bool
    let zoom: Double
    var onTitleChange: (String) -> Void
    var onProgressChange: (Double) -> Void
    var onDelete: () -> Void

    init(
        todo: TodoItem,
        isCompleting: Bool,
        isShattering: Bool,
        zoom: Double,
        onTitleChange: @escaping (String) -> Void,
        onProgressChange: @escaping (Double) -> Void,
        onDelete: @escaping () -> Void
    ) {
        self.todo = todo
        self.isCompleting = isCompleting
        self.isShattering = isShattering
        self.zoom = zoom
        self.onTitleChange = onTitleChange
        self.onProgressChange = onProgressChange
        self.onDelete = onDelete
    }

    var body: some View {
        VStack(alignment: .leading, spacing: metric(8)) {
            HStack(spacing: metric(8)) {
                TextField(
                    "Task",
                    text: Binding(
                        get: { todo.title },
                        set: { onTitleChange($0) }
                    )
                )
                    .textFieldStyle(.plain)
                    .font(.system(size: metric(14), weight: .medium))
                    .disabled(isCompleting)

                Text("\(Int(todo.progress.rounded()))%")
                    .font(.system(size: metric(11), design: .monospaced))
                    .foregroundStyle(.secondary)
                    .frame(width: metric(44), alignment: .trailing)

                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: metric(14), weight: .medium))
                }
                .buttonStyle(.borderless)
                .disabled(isCompleting)
                .help("Delete task")
            }

            ProgressDragView(progress: todo.progress, zoom: zoom) { progress in
                onProgressChange(progress)
            }
            .frame(height: metric(16))
            .disabled(isCompleting)
        }
        .padding(metric(12))
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .opacity(isShattering ? 0 : (isCompleting ? 0.55 : 1))
        .scaleEffect(y: isShattering ? 0.7 : 1, anchor: .top)
        .animation(.easeInOut(duration: 0.45), value: isShattering)
    }

    private func metric(_ baseValue: Double) -> CGFloat {
        CGFloat(WindowZoom.metric(baseValue, for: zoom))
    }
}
