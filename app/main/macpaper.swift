// macpaper.swift

import SwiftUI
import AppKit

@main
struct macpaper: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup("Settings") {
            SettingsView()
                .environmentObject(macpaperService())
                .frame(minWidth: 550, idealWidth: 600, minHeight: 500, idealHeight: 550)
        }
        .windowStyle(DefaultWindowStyle())
    }
}


class AppDelegate: NSObject, NSApplicationDelegate {
    var status_item: NSStatusItem?
    var _mwin: NSWindow?
    var _mwin_open = false
    @AppStorage("checkForUpdates") private var checkForUpdates = true
    var updater = Updater()
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        NSApp.windows.forEach { $0.close() }
        make_paper_sb_item()
        start_launchAgent()
        
        if checkForUpdates {
            updater.checkForUpdates()
        }
    }
    
    func start_launchAgent() {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let launchAgent = home.appendingPathComponent("Library/LaunchAgents/com.naomisphere.macpaper.wallpaper.plist")
        
        if FileManager.default.fileExists(atPath: launchAgent.path) {
            let service = macpaperService()
            service.wp_doPersist(true)
        }
    }
    
    func applicationShouldHandleReopen(_ app: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        return false
    }
    
    func make_paper_sb_item() {
        status_item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = status_item?.button {
            if let resourcePath = Bundle.main.path(forResource: "StatusBarIcon", ofType: "png"),
               let iconImage = NSImage(contentsOfFile: resourcePath) {
                iconImage.size = NSSize(width: 18, height: 18)
                iconImage.isTemplate = false
                button.image = iconImage
            } else {
                button.image = NSImage(systemSymbolName: "drop.fill", accessibilityDescription: "macpaper")
            }
        }
        
        status_item?.menu = sb_item_menu()
    }
    
    func remove_sb_item() {
        if let status_item = status_item {
            NSStatusBar.system.removeStatusItem(status_item)
        }
        status_item = nil
    }
    
    @objc func show_manager() {
    if _mwin == nil {
        let contentView = ContentView()
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1200, height: 800),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        window.isReleasedWhenClosed = false
        window.center()
        window.title = "macpaper"
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isOpaque = false
        window.hasShadow = true
        
        if #available(macOS 26.0, *) {
            window.backgroundColor = .clear

            let glassManager = glassObj()
            window.contentView = NSHostingView(rootView: glassManager)

            window.contentView?.wantsLayer = true
            window.contentView?.layer?.cornerRadius = 20
            window.contentView?.layer?.masksToBounds = true
            
        } else {
            window.backgroundColor = NSColor(calibratedRed: 0.162, green: 0.389, blue: 1, alpha: 0.35)
            window.contentView = NSHostingView(rootView: contentView)
            window.contentView?.wantsLayer = true
            window.contentView?.layer?.cornerRadius = 0
            window.contentView?.layer?.masksToBounds = false
        }
        
        window.minSize = NSSize(width: 900, height: 600)
        window.delegate = self
        _mwin = window
    }

    _mwin?.makeKeyAndOrderFront(nil)
    NSApp.setActivationPolicy(.regular)
    NSApp.activate(ignoringOtherApps: true)
    _mwin_open = true
}

@available(macOS 26.0, *)
struct glassObj: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(NSColor(calibratedRed: 0.162, green: 0.389, blue: 1, alpha: 0.35)),
                            Color(NSColor(calibratedRed: 0.162, green: 0.389, blue: 1, alpha: 0.2))
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .glassEffect(in: .rect(cornerRadius: 28))
                .ignoresSafeArea()
            ContentView()
        }
    }
}
    
    func close_manager() {
        _mwin?.close()
        _mwin_open = false
        NSApp.setActivationPolicy(.accessory)
    }

    func show_mwin() {
        show_manager()
    }
    
    func sb_item_menu() -> NSMenu {
        let menu = NSMenu()
        let service = macpaperService()
        
        let home = FileManager.default.homeDirectoryForCurrentUser
        let current_wp = home.appendingPathComponent(".local/share/macpaper/current_wallpaper")
        var wallpaper_is_set = false
        var _wp: String?
        
        if FileManager.default.fileExists(atPath: current_wp.path) {
            if let currentPath = try? String(contentsOf: current_wp).trimmingCharacters(in: .whitespacesAndNewlines) {
                wallpaper_is_set = FileManager.default.fileExists(atPath: currentPath)
                _wp = currentPath
            }
        }
        
        let wp_storage_dir = home.appendingPathComponent(".local/share/paper/wallpaper")
        var wallpapers: [endup_wp] = []
        
        if FileManager.default.fileExists(atPath: wp_storage_dir.path) {
            do {
                let files = try FileManager.default.contentsOfDirectory(at: wp_storage_dir, includingPropertiesForKeys: [.contentModificationDateKey, .fileSizeKey])
                
                let filteredFiles = files.filter { url in
                    let ext = url.pathExtension.lowercased()
                    return ["mov", "mp4", "gif", "jpg", "jpeg", "png"].contains(ext)
                }
                
                wallpapers = filteredFiles.compactMap { url -> endup_wp? in
                    let resourceValues = try? url.resourceValues(forKeys: [.contentModificationDateKey, .fileSizeKey])
                    
                    let modificationDate: Date?
                    if let date = resourceValues?.contentModificationDate {
                        modificationDate = date
                    } else if let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
                              let date = attrs[.modificationDate] as? Date {
                        modificationDate = date
                    } else {
                        modificationDate = nil
                    }
                    
                    let fileSize: Int64?
                    if let size = resourceValues?.fileSize {
                        fileSize = Int64(size)
                    } else if let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
                              let size = attrs[.size] as? Int64 {
                        fileSize = size
                    } else {
                        fileSize = nil
                    }
                    
                    guard let modificationDate = modificationDate, let fileSize = fileSize else {
                        return nil
                    }
                    
                    return endup_wp(
                        id: UUID(),
                        name: url.deletingPathExtension().lastPathComponent,
                        path: url.path,
                        preview: nil,
                        createdDate: modificationDate,
                        fileSize: fileSize
                    )
                }.sorted { $0.createdDate > $1.createdDate }
            } catch {
                print(error)
            }
        }
        
        let openItem = NSMenuItem(
            title: NSLocalizedString("sb_open_mgr", comment: "Open Manager"),
            action: #selector(show_manager),
            keyEquivalent: "o"
        )
        openItem.target = self
        menu.addItem(openItem)
        
        menu.addItem(NSMenuItem.separator())
        
        if !wallpapers.isEmpty {
            let wpSubmenu = NSMenu()
            
            for wallpaper in wallpapers.prefix(8) {
                let item = NSMenuItem(
                    title: wallpaper.name,
                    action: #selector(apply_wp(_:)),
                    keyEquivalent: ""
                )
                item.representedObject = wallpaper
                item.target = self
                
                if let currentPath = _wp, currentPath == wallpaper.path {
                    item.state = .on
                }
                
                wpSubmenu.addItem(item)
            }
            
            if wallpapers.count > 8 {
                wpSubmenu.addItem(NSMenuItem.separator())
                let showAllItem = NSMenuItem(
                    title: NSLocalizedString("sb_show_all", comment: "Show All..."),
                    action: #selector(open_manager),
                    keyEquivalent: ""
                )
                showAllItem.target = self
                wpSubmenu.addItem(showAllItem)
            }
            
            let wpMenuItem = NSMenuItem(
                title: NSLocalizedString("sb_wallpapers", comment: "Wallpapers"),
                action: nil,
                keyEquivalent: ""
            )
            wpMenuItem.submenu = wpSubmenu
            menu.addItem(wpMenuItem)
        } else {
            let noWpItem = NSMenuItem(
                title: NSLocalizedString("sb_no_wallpapers", comment: "No wallpapers found"),
                action: nil,
                keyEquivalent: ""
            )
            noWpItem.isEnabled = false
            menu.addItem(noWpItem)
        }
        
        menu.addItem(NSMenuItem.separator())
        
        let volumeItem = NSMenuItem()
        let volumeView = NSHostingView(rootView: MiniVolumeSlider(volume: service.volume))
        volumeView.frame = NSRect(x: 0, y: 0, width: 200, height: 30)
        volumeItem.view = volumeView
        menu.addItem(volumeItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let launchAgent = home.appendingPathComponent("Library/LaunchAgents/com.naomisphere.macpaper.wallpaper.plist")
        let is_agent_enabled = FileManager.default.fileExists(atPath: launchAgent.path)
        
        let persistItem = NSMenuItem(
            title: NSLocalizedString("sb_perst_tooltip", comment: "Auto-start wallpaper"),
            action: #selector(toggle_launchAgent),
            keyEquivalent: ""
        )
        persistItem.target = self
        persistItem.state = is_agent_enabled ? .on : .off
        menu.addItem(persistItem)
        
        if wallpaper_is_set {
            let unsetItem = NSMenuItem(
                title: NSLocalizedString("sb_unset_wp", comment: "Unset Wallpaper"),
                action: #selector(unset_wp),
                keyEquivalent: ""
            )
            unsetItem.target = self
            menu.addItem(unsetItem)
        }
        
        menu.addItem(NSMenuItem.separator())
        
        let settingsItem = NSMenuItem(
            title: NSLocalizedString("sb_settings", comment: "Settings"),
            action: #selector(show_settings),
            keyEquivalent: ","
        )
        settingsItem.target = self
        menu.addItem(settingsItem)
        
        let aboutItem = NSMenuItem(
            title: NSLocalizedString("sb_about", comment: "About macpaper"),
            action: #selector(show_about),
            keyEquivalent: ""
        )
        aboutItem.target = self
        menu.addItem(aboutItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let quitItem = NSMenuItem(
            title: NSLocalizedString("sb_quit", comment: "Quit macpaper"),
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )
        menu.addItem(quitItem)
        
        return menu
    }
    
    @objc func apply_wp(_ sender: NSMenuItem) {
        guard let wallpaper = sender.representedObject as? endup_wp else { return }
        let service = macpaperService()
        service.set_wp(wallpaper)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.status_item?.menu = self.sb_item_menu()
        }
    }
    
    @objc func toggle_launchAgent() {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let launchAgent = home.appendingPathComponent("Library/LaunchAgents/com.naomisphere.macpaper.wallpaper.plist")
        let is_agent_enabled = FileManager.default.fileExists(atPath: launchAgent.path)
        
        let service = macpaperService()
        service.wp_doPersist(!is_agent_enabled)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.status_item?.menu = self.sb_item_menu()
        }
    }
    
    @objc func unset_wp() {
        let service = macpaperService()
        service.unset_wp()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.status_item?.menu = self.sb_item_menu()
        }
    }
    
    @objc func open_manager() {
        show_mwin()
    }
    
    @objc func show_settings() {
        let settingsView = SettingsView()
            .environmentObject(macpaperService())
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 500),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        
        if let managerWindow = _mwin {
            let managerFrame = managerWindow.frame
            let settingsSize = window.frame.size
            
            let x = managerFrame.midX - settingsSize.width / 2
            let y = managerFrame.midY - settingsSize.height / 2
            
            window.setFrameOrigin(NSPoint(x: x, y: y))
        } else {
            window.center()
        }
        
        window.title = NSLocalizedString("settings", comment: "Settings")
        window.titleVisibility = .hidden
        window.contentView = NSHostingView(rootView: settingsView)
        window.isReleasedWhenClosed = false
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @objc func refresh_wallpapers() {
        let service = macpaperService()
        service.fetch_wallpapers()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.status_item?.menu = self.sb_item_menu()
        }
    }
    
    @objc func show_about() {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "unknown"
        
        let alert = NSAlert()
        alert.messageText = "macpaper"
        alert.informativeText = String(format: NSLocalizedString("sb_about_text", comment: "Version %@ (%@)\n\nThe Wallpaper Manager for macOS"), version, build)
        alert.alertStyle = .informational
        alert.addButton(withTitle: NSLocalizedString("sb_about_github", comment: "GitHub"))
        alert.addButton(withTitle: NSLocalizedString("sb_about_kofi", comment: "Support on Ko-fi"))
        alert.addButton(withTitle: NSLocalizedString("browse_cancel", comment: "OK"))
        
        let response = alert.runModal()
        
        if response == .alertFirstButtonReturn {
            if let url = URL(string: "https://github.com/naomisphere/macpaper") {
                NSWorkspace.shared.open(url)
            }
        } else if response == .alertSecondButtonReturn {
            if let url = URL(string: "https://ko-fi.com/naomisphere") {
                NSWorkspace.shared.open(url)
            }
        }
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
}

extension AppDelegate: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        if let closingWindow = notification.object as? NSWindow, closingWindow == _mwin {
            _mwin_open = false
            NSApp.setActivationPolicy(.accessory)
        }
    }
    
    func windowWillResize(_ sender: NSWindow, to frameSize: NSSize) -> NSSize {
        if sender == _mwin {
            let minWidth: CGFloat = 900
            let minHeight: CGFloat = 600
            
            let constrainedWidth = max(frameSize.width, minWidth)
            let constrainedHeight = max(frameSize.height, minHeight)
            
            return NSSize(width: constrainedWidth, height: constrainedHeight)
        }
        return frameSize
    }
}

struct MiniVolumeSlider: View {
    @State var volume: Double
    
    var body: some View {
        HStack {
            Image(systemName: volume == 0 ? "speaker.slash" : "speaker.wave.2")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
            
            Slider(value: $volume, in: 0...1)
                .frame(width: 120)
                .onChange(of: volume) { newValue in
                    let service = macpaperService()
                    service.chvol(newValue)
                }
            
            Text("\(Int(volume * 100))%")
                .font(.system(size: 10))
                .foregroundColor(.secondary)
                .frame(width: 30, alignment: .trailing)
        }
        .padding(.horizontal, 8)
    }
}