import GlassTodoNoteCore
import SwiftUI

struct TodoRowView: View {
    let todo: TodoItem
    let isCompleting: Bool
    var onTitleChange: (String) -> Void
    var onProgressChange: (Double) -> Void
    var onDelete: () -> Void

    init(
        todo: TodoItem,
        isCompleting: Bool,
        onTitleChange: @escaping (String) -> Void,
        onProgressChange: @escaping (Double) -> Void,
        onDelete: @escaping () -> Void
    ) {
        self.todo = todo
        self.isCompleting = isCompleting
        self.onTitleChange = onTitleChange
        self.onProgressChange = onProgressChange
        self.onDelete = onDelete
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                TextField(
                    "Task",
                    text: Binding(
                        get: { todo.title },
                        set: { onTitleChange($0) }
                    )
                )
                    .textFieldStyle(.plain)
                    .font(.body.weight(.medium))
                    .disabled(isCompleting)

                Text("\(Int(todo.progress.rounded()))%")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .frame(width: 44, alignment: .trailing)

                Button(action: onDelete) {
                    Image(systemName: "trash")
                }
                .buttonStyle(.borderless)
                .disabled(isCompleting)
                .help("Delete task")
            }

            ProgressDragView(progress: todo.progress) { progress in
                onProgressChange(progress)
            }
            .frame(height: 16)
            .disabled(isCompleting)
        }
        .padding(12)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .opacity(isCompleting ? 0.55 : 1)
    }
}
