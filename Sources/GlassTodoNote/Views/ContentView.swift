import GlassTodoNoteCore
import SwiftUI

struct ContentView: View {
    @Bindable var store: TodoStore

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Glass Todo")
                .font(.headline)
            Text("Scaffold ready")
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(20)
        .background(.regularMaterial)
    }
}
