// macpaperService.swift

import Foundation
import Combine

class macpaperService: NSObject, ObservableObject {
    @Published var wallpapers: [endup_wp] = []
    @Published var isLoading = false
    @Published var current_wp: String?
    @Published var volume: Double = 0.5
    @Published var wp_is_agent: Bool = false
    @Published var ap_is_enabled: Bool = false
    
    private let wrapped_obj: String
    private let wp_storage_dir = FileManager.default.homeDirectoryForCurrentUser
    .appendingPathComponent(".local/share/paper/wallpaper")
    private let settings_file = FileManager.default.homeDirectoryForCurrentUser
    .appendingPathComponent(".local/share/macpaper/settings.json")
    
    override init() {
        let app_path = Bundle.main.bundlePath
        wrapped_obj = "\(app_path)/Contents/MacOS/macpaper-bin"
        super.init()
        loadSettings()
    }

    func _ap_enabled(_ enabled: Bool) {
        ap_is_enabled = enabled
        saveSettings()
        
        DistributedNotificationCenter.default().postNotificationName(
            Notification.Name("com.naomisphere.macpaper.autoPauseChanged"),
            object: nil,
            userInfo: ["ap_is_enabled": enabled],
            deliverImmediately: true
        )
    }
    
    private func loadSettings() {
        do {
            if FileManager.default.fileExists(atPath: settings_file.path) {
                let data = try Data(contentsOf: settings_file)
                let settings = try JSONDecoder().decode([String: Bool].self, from: data)
                ap_is_enabled = settings["ap_is_enabled"] ?? false
            }
        } catch {
            print("while loading settings: \(error)")
        }
    }
    
    private func saveSettings() {
        do {
            let settings: [String: Bool] = ["ap_is_enabled": ap_is_enabled]
            let data = try JSONEncoder().encode(settings)
            try FileManager.default.createDirectory(at: settings_file.deletingLastPathComponent(), 
                                                  withIntermediateDirectories: true)
            try data.write(to: settings_file)
        } catch {
            print("while writing settings: \(error)")
        }
    }
    
    func chvol(_ new_vol: Double) {
        volume = new_vol
        let volumeFloat = Float(new_vol)

        DistributedNotificationCenter.default().postNotificationName(
            Notification.Name("com.naomisphere.macpaper.volumeChanged"),
            object: nil,
            userInfo: ["volume": volumeFloat],
            deliverImmediately: true
        )
        
        print("volume notif sent! - \(volumeFloat)")

        let vol_in_percentage = Int(new_vol * 100)
        _exec([wrapped_obj, "--volume", "\(vol_in_percentage)"]) { success in
        }
    }

    func fetch_wallpapers() {
        isLoading = true
        
        try? FileManager.default.createDirectory(at: wp_storage_dir, withIntermediateDirectories: true)
        
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self else { return }
            do {
                let files = try FileManager.default.contentsOfDirectory(at: self.wp_storage_dir, includingPropertiesForKeys: [.creationDateKey, .fileSizeKey])
                
                let possible_wp_obj = files.filter { url in
                    let ext = url.pathExtension.lowercased()
                    return ["mov", "mp4", "gif"].contains(ext)
                }
                
                let items = possible_wp_obj.compactMap { url -> endup_wp? in
                    guard let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
                        let createdDate = attributes[.creationDate] as? Date,
                        let fileSize = attributes[.size] as? Int64 else {
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
                }
                
                DispatchQueue.main.async {
                    self.wallpapers = items.sorted { $0.createdDate > $1.createdDate }
                    self.isLoading = false
                }
            } catch {
                print(error)
                DispatchQueue.main.async {
                    self.isLoading = false
                }
            }
        }
    }
    
    func set_wp(_ wallpaper: endup_wp) {
        if current_wp != nil {
            _unset_wp { [weak self] in
                self?.set_wp_after_unset(wallpaper)
            }
        } else {
            set_wp_after_unset(wallpaper)
        }
    }
    
    private func set_wp_after_unset(_ wallpaper: endup_wp) {
        _exec([wrapped_obj, "--set", wallpaper.path]) { [weak self] success in
            if success {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self?.current_wp = wallpaper.path
                }
            } else {
                self?.current_wp = nil
            }
        }
    }

    private func _unset_wp(completion: @escaping () -> Void) {
        current_wp = nil
        wp_is_agent = false
        
        _exec([wrapped_obj, "--unset"]) { [weak self] success in
            if !success {
                print("error: couldn't unset wallpaper")
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                completion()
            }
        }
    }
    
    func unset_wp() {
        _unset_wp {
        }
    }
    
    func wp_doPersist(_ enabled: Bool) {
        wp_is_agent = enabled
        
        if enabled {
            _exec([wrapped_obj, "--persist"]) { [weak self] success in
                DispatchQueue.main.async {
                    self?.wp_is_agent = success
                }
            }
        } else {
            let home = FileManager.default.homeDirectoryForCurrentUser
            let launchAgent = home.appendingPathComponent("Library/LaunchAgents/com.naomisphere.macpaper.wallpaper.plist")
            
            do {
                let unloadTask = Process()
                unloadTask.launchPath = "/bin/launchctl"
                unloadTask.arguments = ["unload", launchAgent.path]
                unloadTask.launch()
                unloadTask.waitUntilExit()

                if FileManager.default.fileExists(atPath: launchAgent.path) {
                    try FileManager.default.removeItem(at: launchAgent)
                    print("persistence disabled - LaunchAgent removed")
                }
                
                DispatchQueue.main.async { [weak self] in
                    self?.wp_is_agent = false
                }
            } catch {
                print(error)
                DispatchQueue.main.async { [weak self] in
                    self?.wp_is_agent = true
                }
            }
        }
    }
     
    private func _exec(_ arguments: [String], completion: @escaping (Bool) -> Void) {
        DispatchQueue.global(qos: .background).async {
            let task = Process()
            task.launchPath = arguments[0]
            task.arguments = Array(arguments.dropFirst())
            
            let pipe = Pipe()
            task.standardOutput = pipe
            task.standardError = pipe
            
            task.launch()
            task.waitUntilExit()
            
            DispatchQueue.main.async {
                completion(task.terminationStatus == 0)
            }
        }
    }
}

struct endup_wp: Identifiable {
    let id: UUID
    let name: String
    let path: String
    let preview: String?
    let createdDate: Date
    let fileSize: Int64
}