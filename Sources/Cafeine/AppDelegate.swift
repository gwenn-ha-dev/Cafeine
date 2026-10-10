import AppKit
import ServiceManagement

/// L'icône de la barre des menus et son menu.
/// Clic gauche : active / désactive. Clic droit (ou ⌥-clic) : menu.
///
/// Clés de lancement (`open -a Cafeine --args …`) :
///   `-activate <secondes>`  active au lancement, `0` pour sans limite ;
///   `-showMenu YES`         ouvre le menu au lancement (captures du README) ;
///   `-showAbout YES`        ouvre « À propos » au lancement (idem).
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    private let menu = NSMenu()
    private let keepAwake = KeepAwake()

    private var allowDisplaySleep: Bool {
        get { UserDefaults.standard.bool(forKey: "allowDisplaySleep") }
        set { UserDefaults.standard.set(newValue, forKey: "allowDisplaySleep") }
    }

    static let durations: [TimeInterval] = [15 * 60, 3600, 2 * 3600, 4 * 3600, 8 * 3600]

    func applicationDidFinishLaunching(_ notification: Notification) {
        if let button = statusItem.button {
            button.target = self
            button.action = #selector(statusItemClicked)
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        menu.delegate = self
        keepAwake.onChange = { [weak self] in self?.updateIcon() }
        updateIcon()

        let defaults = UserDefaults.standard
        if defaults.object(forKey: "activate") != nil {
            let seconds = defaults.double(forKey: "activate")
            keepAwake.activate(for: seconds > 0 ? seconds : nil, allowDisplaySleep: allowDisplaySleep)
        }
        if defaults.bool(forKey: "showMenu") {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { self.openMenu() }
        }
        if defaults.bool(forKey: "showAbout") {
            showAbout()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        keepAwake.deactivate()
    }

    // MARK: - Status item

    private func updateIcon() {
        let name = keepAwake.isActive ? "cup.and.saucer.fill" : "cup.and.saucer"
        let image = NSImage(systemSymbolName: name, accessibilityDescription: String(localized: "app.name"))
        image?.isTemplate = true
        statusItem.button?.image = image
        statusItem.button?.toolTip = statusText
    }

    private var statusText: String {
        guard keepAwake.isActive else { return String(localized: "status.inactive") }
        guard let expiry = keepAwake.expiry else { return String(localized: "status.indefinite") }
        let remaining = Self.format(max(60, expiry.timeIntervalSinceNow), width: .abbreviated)
        return String(format: String(localized: "status.remaining"), remaining)
    }

    nonisolated static func format(_ seconds: TimeInterval, width: Duration.UnitsFormatStyle.UnitWidth) -> String {
        Duration.seconds(seconds).formatted(.units(allowed: [.hours, .minutes], width: width,
                                                    fractionalPart: .hide(rounded: .down)))
    }

    @objc private func statusItemClicked() {
        guard let event = NSApp.currentEvent else { return }
        if event.type == .rightMouseUp || event.modifierFlags.contains(.option) {
            openMenu()
        } else if keepAwake.isActive {
            keepAwake.deactivate()
        } else {
            activate(for: nil)
        }
    }

    private func openMenu() {
        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil   // sinon le clic gauche ouvrirait aussi le menu
    }

    private func activate(for duration: TimeInterval?) {
        if !keepAwake.activate(for: duration, allowDisplaySleep: allowDisplaySleep) {
            NSSound.beep()
        }
    }

    // MARK: - Menu

    // Le menu est reconstruit à chaque ouverture : rien n'est gardé en mémoire entre-temps.
    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()

        menu.addItem(label(statusText))
        if keepAwake.isActive {
            menu.addItem(item(String(localized: "menu.deactivate"), #selector(deactivateClicked)))
        }
        menu.addItem(.separator())

        menu.addItem(label(String(localized: "menu.activateFor")))
        let indefinite = item(String(localized: "menu.indefinitely"), #selector(durationClicked(_:)))
        indefinite.tag = -1
        indefinite.indentationLevel = 1
        menu.addItem(indefinite)
        for (index, duration) in Self.durations.enumerated() {
            let i = item(Self.format(duration, width: .wide), #selector(durationClicked(_:)))
            i.tag = index
            i.indentationLevel = 1
            menu.addItem(i)
        }
        menu.addItem(.separator())

        let display = item(String(localized: "menu.allowDisplaySleep"), #selector(toggleDisplaySleep))
        display.state = allowDisplaySleep ? .on : .off
        menu.addItem(display)

        let login = item(String(localized: "menu.launchAtLogin"), #selector(toggleLaunchAtLogin))
        login.state = SMAppService.mainApp.status == .enabled ? .on : .off
        menu.addItem(login)

        menu.addItem(.separator())
        menu.addItem(item(String(localized: "menu.about"), #selector(showAbout)))
        let quit = item(String(localized: "menu.quit"), #selector(NSApplication.terminate(_:)), key: "q")
        quit.target = NSApp
        menu.addItem(quit)
    }

    private func label(_ title: String) -> NSMenuItem {
        let i = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        i.isEnabled = false
        return i
    }

    private func item(_ title: String, _ action: Selector, key: String = "") -> NSMenuItem {
        let i = NSMenuItem(title: title, action: action, keyEquivalent: key)
        i.target = self
        return i
    }

    @objc private func deactivateClicked() { keepAwake.deactivate() }

    @objc private func durationClicked(_ sender: NSMenuItem) {
        activate(for: sender.tag < 0 ? nil : Self.durations[sender.tag])
    }

    @objc private func toggleDisplaySleep() {
        allowDisplaySleep.toggle()
        // Réapplique l'assertion avec le nouveau type, en conservant le temps restant.
        if keepAwake.isActive {
            activate(for: keepAwake.expiry.map { max(1, $0.timeIntervalSinceNow) })
        }
    }

    @objc private func toggleLaunchAtLogin() {
        do {
            if SMAppService.mainApp.status == .enabled {
                try SMAppService.mainApp.unregister()
            } else {
                try SMAppService.mainApp.register()
            }
        } catch {
            NSApp.activate(ignoringOtherApps: true)
            NSAlert(error: error).runModal()
        }
    }

    @objc private func showAbout() {
        NSApp.activate(ignoringOtherApps: true)
        NSApp.orderFrontStandardAboutPanel(nil)
    }
}
