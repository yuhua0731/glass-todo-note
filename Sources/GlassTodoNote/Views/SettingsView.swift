import GlassTodoNoteCore
import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @AppStorage("window.opacity") private var windowOpacity = 0.86
    @AppStorage("window.floatsAboveWindows") private var floatsAboveWindows = true
    @AppStorage("window.reminderShakeEnabled") private var reminderShakeEnabled = true
    @AppStorage("window.backgroundMode") private var backgroundMode = BackgroundMode.preset.rawValue
    @AppStorage("window.backgroundAppearance") private var backgroundAppearance = BackgroundAppearance.glass.rawValue
    @AppStorage("window.backgroundColorHex") private var backgroundColorHex = StoredBackgroundColor.defaultHex
    @AppStorage("window.backgroundImagePath") private var backgroundImagePath = ""
    @AppStorage("window.backgroundImageRevision") private var backgroundImageRevision = ""
    @State private var backgroundError: String?
    private let backgroundImageStorage = BackgroundImageStorage.applicationSupport

    var body: some View {
        Form {
            Section("Window") {
                Picker("Background", selection: $backgroundMode) {
                    ForEach(BackgroundMode.allCases) { mode in
                        Text(mode.title).tag(mode.rawValue)
                    }
                }
                .pickerStyle(.segmented)

                switch currentBackgroundMode {
                case .preset:
                    presetPicker
                case .solidColor:
                    ColorPicker("Color", selection: backgroundColorBinding, supportsOpacity: false)
                case .image:
                    imageControls
                }

                Slider(value: $windowOpacity, in: 0.2...1) {
                    Text("Opacity")
                }
                Toggle("Float above other windows", isOn: $floatsAboveWindows)
            }

            Section("Reminders") {
                Toggle("Shake every 10 minutes", isOn: $reminderShakeEnabled)
            }
        }
        .padding()
        .frame(width: 420)
    }

    private var presetPicker: some View {
        Picker("Preset", selection: $backgroundAppearance) {
            ForEach(BackgroundAppearance.allCases) { appearance in
                Text(appearance.title).tag(appearance.rawValue)
            }
        }
        .pickerStyle(.segmented)
    }

    private var imageControls: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Button("Choose Image", action: chooseImage)
                Button("Clear", action: clearImage)
                    .disabled(backgroundImagePath.isEmpty)
            }
            if !backgroundImagePath.isEmpty {
                Text(URL(fileURLWithPath: backgroundImagePath).lastPathComponent)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            if let backgroundError {
                Text(backgroundError)
                    .foregroundStyle(.red)
                    .lineLimit(2)
            }
        }
    }

    private var currentBackgroundMode: BackgroundMode {
        BackgroundMode(rawValue: backgroundMode) ?? .preset
    }

    private var backgroundColorBinding: Binding<Color> {
        Binding {
            Color(storedHex: backgroundColorHex)
        } set: { color in
            backgroundColorHex = color.storedHexString()
        }
    }

    private func chooseImage() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.allowedContentTypes = [.png, .jpeg, .tiff, .heic, .gif]

        guard panel.runModal() == .OK,
              let url = panel.url else {
            return
        }

        do {
            let storedURL = try backgroundImageStorage.replaceImage(with: url)
            backgroundImagePath = storedURL.path
            backgroundImageRevision = UUID().uuidString
            backgroundMode = BackgroundMode.image.rawValue
            backgroundError = nil
        } catch {
            backgroundError = "Could not copy image."
        }
    }

    private func clearImage() {
        do {
            try backgroundImageStorage.clear()
            backgroundImagePath = ""
            backgroundImageRevision = UUID().uuidString
            backgroundError = nil
        } catch {
            backgroundError = "Could not clear image."
        }
    }
}
