import AppKit
import SwiftUI

/// Manages the NSStatusItem, NSPopover, and right-click context menu.
///
/// Owning AppModel here (rather than in SkillSuiteApp) lets us share a single
/// instance across the popover and the context menu actions without going through
/// the SwiftUI environment from the scene level.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {

    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    let appModel = AppModel()

    // MARK: - Launch

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        setupStatusItem()
        setupPopover()
    }

    // MARK: - Status Item

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        guard let button = statusItem.button else { return }
        button.image = NSImage(systemSymbolName: "doc.text.magnifyingglass",
                               accessibilityDescription: "SkillSuite")
        button.action = #selector(handleClick(_:))
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        button.target = self
    }

    @objc private func handleClick(_ sender: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else { return }
        if event.type == .rightMouseUp {
            showContextMenu()
        } else {
            togglePopover()
        }
    }

    // MARK: - Context Menu

    private func showContextMenu() {
        let menu = NSMenu()

        let addItem = NSMenuItem(title: "Add Directory",
                                 action: #selector(addDirectory),
                                 keyEquivalent: "")
        addItem.target = self
        menu.addItem(addItem)

        let quitItem = NSMenuItem(title: "Quit SkillSuite",
                                  action: #selector(quitApp),
                                  keyEquivalent: "")
        quitItem.target = self
        menu.addItem(quitItem)

        // Temporarily assign menu so NSStatusItem renders it, then clear to
        // restore normal left-click → popover behaviour.
        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
    }

    @objc private func addDirectory() {
        appModel.presentFolderPicker()
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }

    // MARK: - Popover

    private func setupPopover() {
        popover = NSPopover()
        popover.contentSize = NSSize(width: 700, height: 500)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(
            rootView: PopoverRootView().environment(appModel)
        )
    }

    private func togglePopover() {
        if popover.isShown {
            popover.performClose(nil)
        } else if let button = statusItem.button {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }
}
