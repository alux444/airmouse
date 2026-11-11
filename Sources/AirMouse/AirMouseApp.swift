import SwiftUI

@main
struct AirMouseApp: App {
    @StateObject private var controller = MouseController()
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate

    var body: some Scene {
        Window("AirMouse", id: "main") {
            ContentView(controller: controller)
                .onAppear { delegate.configure(controller: controller) }
        }
        .windowResizability(.contentSize)
        .defaultPosition(.center)

        MenuBarExtra("AirMouse", systemImage: controller.isTracking ? "cursorarrow.rays" : "cursorarrow") {
            Button(controller.isTracking ? "Pause AirMouse" : "Start AirMouse") { controller.toggleTracking() }
            Divider()
            Button("Open AirMouse") { NSApp.activate(ignoringOtherApps: true); openMainWindow() }
            Button("Quit AirMouse") { NSApp.terminate(nil) }
        }
    }

    @Environment(\.openWindow) private var openWindow

    private func openMainWindow() {
        openWindow(id: "main")
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var hotKey: HotKey?

    @MainActor func configure(controller: MouseController) {
        guard hotKey == nil else { return }
        hotKey = HotKey { [weak controller] in
            Task { @MainActor in controller?.toggleTracking() }
        }
    }
}
