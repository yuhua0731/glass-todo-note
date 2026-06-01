import AppKit
import GlassTodoNoteCore
import SwiftUI

@main
struct GlassTodoNoteApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @Environment(\.scenePhase) private var scenePhase
    @State private var todoStore = TodoStore()

    var body: some Scene {
        WindowGroup("Glass Todo Note") {
            ContentView(store: todoStore)
                .frame(minWidth: 360, minHeight: 420)
                .task {
                    await todoStore.loadFromPersistence()
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
