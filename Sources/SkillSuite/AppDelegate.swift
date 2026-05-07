import AppKit
import SwiftUI

/// Manages the NSStatusItem, panel window, and right-click context menu.
///
/// Uses a borderless NSPanel rather than NSPopover so that the panel has no
/// directional arrow and applies no extra material wrapping — matching the
/// original MenuBarExtra .window appearance exactly.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {

    private var statusItem: NSStatusItem!
    private var panel: NSPanel!
    private var eventMonitor: Any?
    let appModel = AppModel()

    // MARK: - Launch

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        setupStatusItem()
        setupPanel()
        appModel.presentFolderPicker = { [weak self] in self?.addDirectory() }
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
            togglePanel()
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

        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
    }

    @objc private func addDirectory() {
        closePanel()
        NSApp.activate(ignoringOtherApps: true)

        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = false
        openPanel.canChooseDirectories = true
        openPanel.allowsMultipleSelection = false
        openPanel.prompt = "Add Codebase"
        openPanel.message = "Select a project folder to scan for AI instruction files"

        guard openPanel.runModal() == .OK, let url = openPanel.url else { return }
        appModel.addCodebase(url)
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }

    // MARK: - Panel

    private func setupPanel() {
        panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 700, height: 500),
            styleMask: [.borderless, .nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: true
        )
        panel.level = .statusBar
        panel.isFloatingPanel = true
        panel.hidesOnDeactivate = false
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle]

        let hostingController = NSHostingController(
            rootView: PopoverRootView().environment(appModel)
        )
        // Clip the SwiftUI content to rounded corners matching native macOS panels.
        // cornerRadius on the view layer (not the window) lets the window shadow
        // render outside the clipping bounds as expected.
        hostingController.view.wantsLayer = true
        hostingController.view.layer?.cornerRadius = 12
        hostingController.view.layer?.cornerCurve = .continuous
        hostingController.view.layer?.masksToBounds = true
        panel.contentViewController = hostingController
    }

    private func togglePanel() {
        if panel.isVisible {
            closePanel()
        } else {
            openPanel()
        }
    }

    private func openPanel() {
        guard let button = statusItem.button,
              let buttonWindow = button.window else { return }

        let buttonRect = button.convert(button.bounds, to: nil)
        let screenRect = buttonWindow.convertToScreen(buttonRect)

        let panelWidth: CGFloat = 700
        let panelHeight: CGFloat = 500
        let x = screenRect.midX - panelWidth / 2
        let y = screenRect.minY - panelHeight

        panel.setFrameOrigin(NSPoint(x: x, y: y))
        panel.makeKeyAndOrderFront(nil)

        // Close when user clicks outside the panel
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            self?.closePanel()
        }
    }

    private func closePanel() {
        panel.orderOut(nil)
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }
}
