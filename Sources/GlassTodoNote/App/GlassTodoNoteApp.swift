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

    var body: some Scene {
        WindowGroup("Glass Todo Note") {
            ContentView(store: todoStore)
                .frame(minWidth: 360, minHeight: 420)
                .background {
                    WindowAccessor { window in
                        stickyWindow = window
                        windowController.configure(
                            window,
                            preferences: WindowPreferences(
                                opacity: windowOpacity,
                                floatsAboveWindows: floatsAboveWindows,
                                reminderShakeEnabled: reminderShakeEnabled
                            )
                        )
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
        }
        .windowStyle(.hiddenTitleBar)

        Settings {
            SettingsView()
        }
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
