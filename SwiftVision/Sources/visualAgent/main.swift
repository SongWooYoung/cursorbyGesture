import AppKit
import AppCore
import Config
import Foundation
import Support

@MainActor
final class VisualAgentAppDelegate: NSObject, NSApplicationDelegate {
    private var coordinator: AppCoordinator?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let configPath = ".env"
        let config = ConfigLoader.load(from: configPath)
        let coordinator = AppCoordinator(config: config, configPath: configPath)
        self.coordinator = coordinator

        do {
            try coordinator.start()
        } catch {
            Logger.error("Failed to start visualAgent: \(error.localizedDescription)")
            NSApp.terminate(nil)
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }
}

let application = NSApplication.shared
let delegate = VisualAgentAppDelegate()

application.delegate = delegate
application.setActivationPolicy(.accessory)
application.run()
