import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusBarController: StatusBarController?
    let store = ScratchpadStore()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        statusBarController = StatusBarController(store: store)
    }

    func applicationWillTerminate(_ notification: Notification) {
        store.stopClipboardMonitoring()
    }
}
