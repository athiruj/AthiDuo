import AppKit
import SwiftUI
import OSLog

@MainActor final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate, NSWindowDelegate {
    private var model: AppModel!
    private var window: NSWindow!
    private var statusItem: NSStatusItem!
    private var screenObserver: NSObjectProtocol?

    func applicationDidFinishLaunching(_ notification: Notification) {
        model = AppModel()
        let content = NSHostingView(rootView: Controls(model: model))
        content.sizingOptions = []

        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 600, height: 600),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "AthiDuo"
        window.titlebarAppearsTransparent = true
        window.backgroundColor = .windowBackgroundColor
        window.contentView = content
        window.isReleasedWhenClosed = false
        window.minSize = NSSize(width: 520, height: 560)
        window.center()

        model.showWindow = { [weak self] in self?.showSettings() }
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.image = AppBrand.menuBarMark
        statusItem.button?.toolTip = "AthiDuo — your desktop follows your lid"
        let menu = NSMenu()
        menu.delegate = self
        statusItem.menu = menu

        screenObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.constrainWindow() }
        }

        showSettings()
        model.configureFirstLaunch()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.model.activateWhenReady()
        }
    }

    @objc private func showSettings() {
        constrainWindow()
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
        model.wakePreview()
    }

    @objc private func toggleEffect() {
        model.enabled ? model.pause() : model.enable()
    }

    @objc private func calibrate() { model.calibrateReference() }

    @objc private func setIntensity(_ sender: NSMenuItem) {
        guard let intensity = Intensity(rawValue: sender.tag) else { return }
        model.perspective = intensity.perspective
    }

    @objc private func toggleHoldStill() { model.clearWhenStill.toggle() }

    @objc private func toggleLaunchAtLogin() { model.setLaunchAtLogin(!model.launchAtLogin) }

    private func constrainWindow() {
        let frame = (window.screen ?? NSScreen.main)?.visibleFrame ?? .zero
        guard !frame.isEmpty else { return }
        let max = frame.insetBy(dx: 32, dy: 32)
        window.maxSize = max.size
        if !max.contains(window.frame) {
            window.setFrame(NSRect(x: max.midX - min(window.frame.width, max.width) / 2,
                                   y: max.midY - min(window.frame.height, max.height) / 2,
                                   width: min(window.frame.width, max.width),
                                   height: min(window.frame.height, max.height)), display: true)
        }
    }

    func menuWillOpen(_ menu: NSMenu) {
        menu.removeAllItems()
        model.refreshLaunchAtLogin()
        let state = NSMenuItem(
            title: model.lidAngle.map { String(format: "Lid angle: %.0f°", $0) } ?? "Sensor unavailable",
            action: nil,
            keyEquivalent: ""
        )
        state.isEnabled = false
        menu.addItem(state)
        menu.addItem(.separator())
        let toggle = menu.addItem(withTitle: model.enabled ? "Pause AthiDuo" : "Activate AthiDuo", action: #selector(toggleEffect), keyEquivalent: "")
        toggle.target = self

        let intensity = NSMenuItem(title: "Intensity", action: nil, keyEquivalent: "")
        let intensityMenu = NSMenu(title: "Intensity")
        for option in Intensity.allCases {
            let item = intensityMenu.addItem(withTitle: option.label, action: #selector(setIntensity), keyEquivalent: "")
            item.target = self
            item.tag = option.rawValue
            item.state = Intensity.nearest(to: model.perspective) == option ? .on : .off
        }
        intensity.submenu = intensityMenu
        menu.addItem(intensity)

        let holdStill = menu.addItem(withTitle: "Hold image while still", action: #selector(toggleHoldStill), keyEquivalent: "")
        holdStill.target = self
        holdStill.state = model.clearWhenStill ? .off : .on

        let launchAtLogin = menu.addItem(withTitle: "Open at login", action: #selector(toggleLaunchAtLogin), keyEquivalent: "")
        launchAtLogin.target = self
        launchAtLogin.state = model.launchAtLogin ? .on : .off

        let calibrate = menu.addItem(withTitle: "Calibrate reference angle", action: #selector(calibrate), keyEquivalent: "")
        calibrate.target = self
        calibrate.isEnabled = model.lidAngle != nil
        let settings = menu.addItem(withTitle: "Open AthiDuo…", action: #selector(showSettings), keyEquivalent: ",")
        settings.target = self
        menu.addItem(.separator())
        menu.addItem(withTitle: "Quit AthiDuo", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool { showSettings(); return true }
    func applicationWillTerminate(_ notification: Notification) {
        if let screenObserver { NotificationCenter.default.removeObserver(screenObserver) }
        model.shutdown()
    }
}

MainActor.assumeIsolated {
    if CommandLine.arguments.contains("--core-check") {
        do { try CoreCheck.run(); exit(0) }
        catch { fputs("Core check failed: \(error.localizedDescription)\n", stderr); exit(1) }
    }
    if CommandLine.arguments.contains("--render-check") {
        do { try RenderCheck.run(); exit(0) }
        catch { fputs("Render check failed: \(error)\n", stderr); exit(1) }
    }
    let app = NSApplication.shared
    app.setActivationPolicy(.accessory)
    let delegate = AppDelegate()
    app.delegate = delegate
    app.run()
}
