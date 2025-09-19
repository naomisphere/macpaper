// macpaper.swift

import SwiftUI
import AppKit

@main
struct macpaper: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var status_item: NSStatusItem?
    var _mwin: NSWindow?
    var _mwin_open = false
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        NSApp.windows.forEach { $0.close() }
        make_paper_sb_item()
        startLaunchAgentIfNeeded()
    }
    
    func startLaunchAgentIfNeeded() {
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
            button.image = NSImage(systemSymbolName: "photo.on.rectangle", accessibilityDescription: "macpaper")
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
            window.backgroundColor = NSColor(calibratedRed: 0.02, green: 0.1, blue: 0.08, alpha: 0.65)
            window.hasShadow = true
            window.contentView = NSHostingView(rootView: contentView)
            window.delegate = self
            
            _mwin = window
        }

        _mwin?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        _mwin_open = true
    }
    
    func close_manager() {
        _mwin?.close()
        _mwin_open = false
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
                let files = try FileManager.default.contentsOfDirectory(at: wp_storage_dir, includingPropertiesForKeys: [.creationDateKey, .fileSizeKey])
                
                wallpapers = files.filter { url in
                    let ext = url.pathExtension.lowercased()
                    return ["mov", "mp4", "gif"].contains(ext)
                }.compactMap { url -> endup_wp? in
                    guard let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
                          let createdDate = attrs[.creationDate] as? Date,
                          let fileSize = attrs[.size] as? Int64 else {
                        return nil
                    }
                    
                    return endup_wp(
                        id: UUID(),
                        name: url.deletingPathExtension().lastPathComponent,
                        path: url.path,
                        preview: nil,
                        createdDate: createdDate,
                        fileSize: fileSize
                    )
                }.sorted { $0.createdDate > $1.createdDate }
            } catch {
                print(error)
            }
        }
        
        if wallpapers.isEmpty {
            let __no_wp_item = NSMenuItem(
                title: NSLocalizedString("sb_no_wallpapers", comment: "No wallpapers found"),
                action: nil,
                keyEquivalent: ""
            )
            __no_wp_item.isEnabled = false
            menu.addItem(__no_wp_item)
        } else {
            let __wp_header = NSMenuItem(
                title: NSLocalizedString("sb_wallpapers", comment: "Wallpapers"),
                action: nil,
                keyEquivalent: ""
            )
            __wp_header.isEnabled = false
            menu.addItem(__wp_header)
            menu.addItem(NSMenuItem.separator())
            
            for wallpaper in wallpapers.prefix(10) {
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
                
                menu.addItem(item)
            }
            
            if wallpapers.count > 10 {
                let moreItem = NSMenuItem(
                    // title: "\(wallpapers.count - 10) more...",
                    title: String(format: NSLocalizedString("sb_large_count", comment: "more items count"), wallpapers.count - 10),
                    action: #selector(open_manager),
                    keyEquivalent: ""
                )
                moreItem.target = self
                menu.addItem(moreItem)
            }
        }
        
        menu.addItem(NSMenuItem.separator())
        
        let __volumeitem = NSMenuItem()
        let ___volume_view = NSHostingView(rootView: MiniVolumeSlider(volume: service.volume))
        ___volume_view.frame = NSRect(x: 0, y: 0, width: 200, height: 30)
        __volumeitem.view = ___volume_view
        menu.addItem(__volumeitem)
        
        menu.addItem(NSMenuItem.separator())
        
        let launchAgent = home.appendingPathComponent("Library/LaunchAgents/com.naomisphere.macpaper.wallpaper.plist")
        let is_agent_enabled = FileManager.default.fileExists(atPath: launchAgent.path)
        
        let __persist_item = NSMenuItem(
            title: is_agent_enabled ? NSLocalizedString("sb_perst_enabled", comment: "Persistence Enabled") : NSLocalizedString("sb_enable_perst", comment: "Enable Persistence"),
            action: #selector(toggle_launchAgent),
            keyEquivalent: "p"
        )
        __persist_item.target = self
        __persist_item.state = is_agent_enabled ? .on : .off
        menu.addItem(__persist_item)
        
        if wallpaper_is_set {
            let __unsetitem = NSMenuItem(
                title: NSLocalizedString("sb_unset_wp", comment: "Unset Wallpaper"),
                action: #selector(unset_wp),
                keyEquivalent: "u"
            )
            __unsetitem.target = self
            menu.addItem(__unsetitem)
        }
        
        menu.addItem(NSMenuItem.separator())
        
        let __openmanageritem = NSMenuItem(
            title: NSLocalizedString("sb_open_mgr", comment: "Open Manager"),
            action: #selector(show_manager),
            keyEquivalent: "o"
        )
        __openmanageritem.target = self
        menu.addItem(__openmanageritem)
        
        let __quititem = NSMenuItem(
            title: NSLocalizedString("sb_quit", comment: "Quit macpaper"),
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )
        menu.addItem(__quititem)
        
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
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
}

extension AppDelegate: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        if let closingWindow = notification.object as? NSWindow, closingWindow == _mwin {
            _mwin_open = false
        }
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
