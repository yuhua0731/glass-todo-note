import AppKit
import GlassTodoNoteCore
import SwiftUI

@main
struct GlassTodoNoteApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @Environment(\.scenePhase) private var scenePhase
    @State private var todoStore = TodoStore()
    @State private var windowController = StickyWindowController()
    @State private var stickyWindow: NSWindow?
    @State private var lastReminderFiredAt: Date?
    @AppStorage("window.opacity") private var windowOpacity = 0.86
    @AppStorage("window.floatsAboveWindows") private var floatsAboveWindows = true
    @AppStorage("window.reminderShakeEnabled") private var reminderShakeEnabled = true
    @AppStorage("window.zoom") private var windowZoom = WindowZoom.reset

    var body: some Scene {
        WindowGroup("Glass Todo Note") {
            ContentView(store: todoStore)
                .frame(minWidth: WindowZoom.windowSize.width, minHeight: WindowZoom.windowSize.height)
                .background {
                    WindowAccessor { window in
                        stickyWindow = window
                        configureStickyWindow(window)
                    }
                }
                .task {
                    await todoStore.loadFromPersistence()
                }
                .task {
                    await runReminderLoop()
                }
                .onAppear {
                    appDelegate.flushPendingSaves = {
                        await todoStore.flushPendingSaves()
                    }
                }
                .onChange(of: scenePhase) { _, phase in
                    guard phase == .background else { return }
                    Task {
                        await todoStore.flushPendingSaves()
                    }
                }
                .onChange(of: windowOpacity) { _, _ in
                    configureStickyWindow(stickyWindow)
                }
                .onChange(of: floatsAboveWindows) { _, _ in
                    configureStickyWindow(stickyWindow)
                }
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandMenu("View") {
                Button("Zoom In") {
                    windowZoom = WindowZoom.zoomIn(from: windowZoom)
                }
                .keyboardShortcut("+", modifiers: .command)

                Button("Zoom Out") {
                    windowZoom = WindowZoom.zoomOut(from: windowZoom)
                }
                .keyboardShortcut("-", modifiers: .command)

                Button("Actual Size") {
                    windowZoom = WindowZoom.reset
                }
                .keyboardShortcut("0", modifiers: .command)
            }
        }

        Settings {
            SettingsView()
        }
    }

    @MainActor
    private func configureStickyWindow(_ window: NSWindow?) {
        guard let window else { return }
        windowController.configure(
            window,
            preferences: WindowPreferences(
                opacity: windowOpacity,
                floatsAboveWindows: floatsAboveWindows,
                reminderShakeEnabled: reminderShakeEnabled
            )
        )
    }

    @MainActor
    private func runReminderLoop() async {
        let scheduler = ReminderScheduler()
        while !Task.isCancelled {
            let now = Date()
            if reminderShakeEnabled,
               scheduler.shouldShake(
                   at: now,
                   hasIncompleteTodos: todoStore.hasIncompleteTodos,
                   lastFiredAt: lastReminderFiredAt
               ),
               let window = stickyWindow {
                windowController.shake(window)
                lastReminderFiredAt = scheduler.reminderSlot(containing: now)
            }
            try? await Task.sleep(for: .seconds(1))
        }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    var flushPendingSaves: (() async -> Void)?
    private var isTerminating = false

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        guard !isTerminating else { return .terminateNow }
        isTerminating = true

        Task {
            await flushPendingSaves?()
            sender.reply(toApplicationShouldTerminate: true)
        }

        return .terminateLater
    }
}
