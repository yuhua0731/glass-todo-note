import GlassTodoNoteCore
import SwiftUI

struct SettingsView: View {
    @AppStorage("window.opacity") private var windowOpacity = 0.86
    @AppStorage("window.floatsAboveWindows") private var floatsAboveWindows = true
    @AppStorage("window.reminderShakeEnabled") private var reminderShakeEnabled = true
    @AppStorage("window.backgroundAppearance") private var backgroundAppearance = BackgroundAppearance.glass.rawValue
    @AppStorage("window.zoom") private var windowZoom = WindowZoom.reset

    var body: some View {
        Form {
            Section("Window") {
                Picker("Background", selection: $backgroundAppearance) {
                    ForEach(BackgroundAppearance.allCases) { appearance in
                        Text(appearance.title).tag(appearance.rawValue)
                    }
                }
                .pickerStyle(.segmented)
                Slider(value: $windowOpacity, in: 0.2...1) {
                    Text("Opacity")
                }
                Toggle("Float above other windows", isOn: $floatsAboveWindows)
                Slider(
                    value: Binding(
                        get: { WindowZoom.clamp(windowZoom) },
                        set: { windowZoom = WindowZoom.clamp($0) }
                    ),
                    in: WindowZoom.minimum...WindowZoom.maximum
                ) {
                    Text("Zoom")
                }
            }

            Section("Reminders") {
                Toggle("Shake every 10 minutes", isOn: $reminderShakeEnabled)
            }
        }
        .padding()
        .frame(width: 360)
    }
}
