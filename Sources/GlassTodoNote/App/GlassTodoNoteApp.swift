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
    @State private var pendingWindowFitTask: Task<Void, Never>?
    @State private var lastReminderFiredAt: Date?
    @AppStorage("window.opacity") private var windowOpacity = 0.86
    @AppStorage("window.floatsAboveWindows") private var floatsAboveWindows = true
    @AppStorage("window.reminderShakeEnabled") private var reminderShakeEnabled = true
    @AppStorage("window.zoom") private var windowZoom = WindowZoom.reset

    var body: some Scene {
        WindowGroup("Glass Todo Note") {
            ContentView(store: todoStore)
                .background {
                    WindowAccessor { window in
                        stickyWindow = window
                        configureStickyWindow(window)
                        scheduleStickyWindowFit()
                    }
                }
                .task {
                    await todoStore.loadFromPersistence()
                    scheduleStickyWindowFit()
                }
                .task {
                    await runReminderLoop()
                }
                .onAppear {
                    windowZoom = WindowZoom.sanitizedStoredValue(windowZoom)
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
                .onChange(of: windowZoom) { _, _ in
                    scheduleStickyWindowFit()
                }
                .onChange(of: todoStore.todos.count) { _, _ in
                    scheduleStickyWindowFit()
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
    private func scheduleStickyWindowFit() {
        pendingWindowFitTask?.cancel()
        pendingWindowFitTask = Task { @MainActor in
            await Task.yield()
            guard !Task.isCancelled else { return }
            fitStickyWindowToContent(stickyWindow)
        }
    }

    @MainActor
    private func fitStickyWindowToContent(_ window: NSWindow?) {
        guard let window else { return }
        windowController.fitToContent(
            window,
            width: WindowZoom.contentWidth(for: windowZoom),
            height: WindowZoom.contentHeight(todoCount: todoStore.todos.count, for: windowZoom)
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
