import AppKit

class MacBridgeStatusItem {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private var lastConfiguration: MacBridgeStatusItemConfiguration?

    init() {

    }

    func configure(using configuration: MacBridgeStatusItemConfiguration) {
        lastConfiguration = configuration

        statusItem.isVisible = configuration.isVisible
        statusItem.button?.setAccessibilityLabel(configuration.accessibilityLabel)

        let image = NSImage(cgImage: configuration.image, size: configuration.imageSize)
        image.isTemplate = true
        statusItem.button?.image = image

        statusItem.menu = menu(for: configuration.items)
    }

    private func modifierKeys(for uglyMask: Int) -> NSEvent.ModifierFlags {
        var modifierMask: NSEvent.ModifierFlags = []
        let pairings: [(MacBridgeStatusModifierMask, NSEvent.ModifierFlags)] = [
            (.capsLock, .capsLock),
            (.shift, .shift),
            (.control, .control),
            (.option, .option),
            (.command, .command),
            (.numericPad, .numericPad),
            (.help, .help),
            (.function, .function)
        ]

        for (ugly, good) in pairings where uglyMask & ugly.rawValue != 0 {
            modifierMask.insert(good)
        }

        return modifierMask
    }

    private func menu(for items: [MacBridgeStatusItemMenuItem]) -> NSMenu {
        let menu = NSMenu()

        for item in items {
            guard !item.isSeparator else {
                menu.addItem(.separator())
                continue
            }

            let menuItem = NSMenuItem(
                title: item.name,
                action: #selector(actionTapped(_:)),
                keyEquivalent: item.keyEquivalent
            )
            menu.addItem(menuItem)

            menuItem.keyEquivalentModifierMask = modifierKeys(for: item.keyEquivalentModifierMask)
            menuItem.target = self
            menuItem.representedObject = item

            if let image = item.image, case let imageSize = item.imageSize, imageSize != .zero {
                menuItem.image = NSImage(cgImage: image, size: imageSize)
            }

            if !item.subitems.isEmpty {
                menuItem.submenu = self.menu(for: item.subitems)
            }
        }

        return menu
    }

    @objc private func actionTapped(_ sender: NSMenuItem) {
        guard let representedObject = sender.representedObject as? MacBridgeStatusItemMenuItem else { return }
        representedObject.primaryActionHandler(MacBridgeStatusItemCallbackInfoImpl(sender: sender))
    }
}

class MacBridgeStatusItemCallbackInfoImpl: MacBridgeStatusItemCallbackInfo {
    let sender: Any?

    init(sender: Any?) {
        self.sender = sender
    }

    var isActive: Bool {
        NSApp.isActive
    }

    func activate() {
        NSApp.activate(ignoringOtherApps: true)
    }

    func deactivate() {
        NSApp.hide(sender)
    }

    func terminate() {
        NSApp.terminate(sender)
    }
}
