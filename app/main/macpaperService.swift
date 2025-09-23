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
    @Published var showVideos: Bool = true
    @Published var showImages: Bool = true
    @Published var selected_wp: endup_wp? = nil
    
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

    func select_wp(_ wallpaper: endup_wp?) {
        selected_wp = wallpaper
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
                showVideos = settings["showVideos"] ?? true
                showImages = settings["showImages"] ?? true
            }
        } catch {
            print("while loading settings: \(error)")
        }
    }
    
    func saveSettings() {
        do {
            let settings: [String: Bool] = [
                "ap_is_enabled": ap_is_enabled,
                "showVideos": showVideos,
                "showImages": showImages
            ]
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
                return ["mov", "mp4", "gif", "jpg", "jpeg", "png"].contains(ext)
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
                    var filteredItems = items
                    
                    if !self.showVideos {
                        filteredItems = filteredItems.filter { wp in
                            let ext = (wp.path as NSString).pathExtension.lowercased()
                            return !["mov", "mp4", "gif"].contains(ext)
                        }
                    }
                    
                    if !self.showImages {
                        filteredItems = filteredItems.filter { wp in
                            let ext = (wp.path as NSString).pathExtension.lowercased()
                            return !["jpg", "jpeg", "png"].contains(ext)
                        }
                    }
                    
                    self.wallpapers = filteredItems.sorted { $0.createdDate > $1.createdDate }
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

    // for still wallpapers, we just use osascript.
    // i may need to work further on still wallpaper handling later
    func set_still_wp(_ wallpaper: endup_wp) {
    let task = Process()
    task.launchPath = "/usr/bin/osascript"
    
    let script = """
    tell application "System Events"
        tell every desktop
            set picture to POSIX file "\(wallpaper.path)"
        end tell
    end tell
    """
    
    task.arguments = ["-e", script]
    
    do {
        try task.run()
        task.waitUntilExit()
        
        if task.terminationStatus == 0 {
            let home = FileManager.default.homeDirectoryForCurrentUser
            let current_wp_file = home.appendingPathComponent(".local/share/macpaper/current_wallpaper")
            
            try? FileManager.default.createDirectory(at: current_wp_file.deletingLastPathComponent(), 
                                                   withIntermediateDirectories: true)
            try? wallpaper.path.write(to: current_wp_file, atomically: true, encoding: .utf8)
            
            DispatchQueue.main.async {
                self.current_wp = wallpaper.path
            }
        }
    } catch {
        print("while setting still wallpaper: \(error)")
    }
}

    
    func set_wp(_ wallpaper: endup_wp) {
    let ext = (wallpaper.path as NSString).pathExtension.lowercased()
    let isMovingWallpaper = ["mov", "mp4", "gif"].contains(ext)
    let isStillWallpaper = ["jpg", "jpeg", "png"].contains(ext)
    
    guard isMovingWallpaper || isStillWallpaper else {
        print("unsupported file format: \(ext)")
        return
    }

    DispatchQueue.main.async {
        self.selected_wp = wallpaper
    }
    
    if current_wp != nil {
        _unset_wp { [weak self] in
            if isMovingWallpaper {
                self?.set_wp_after_unset(wallpaper)
            } else {
                self?.set_still_wp(wallpaper)
            }
        }
    } else {
        if isMovingWallpaper {
            set_wp_after_unset(wallpaper)
        } else {
            set_still_wp(wallpaper)
        }
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
    DispatchQueue.main.async {
        self.selected_wp = nil
    }

    current_wp = nil
    wp_is_agent = false
    
    // check if current wallpaper is a still iamge
    if let currentPath = current_wp {
        let ext = (currentPath as NSString).pathExtension.lowercased()
        if ["jpg", "jpeg", "png"].contains(ext) {
            // if it is, we don't need to use macpaper-bin to unset
            let home = FileManager.default.homeDirectoryForCurrentUser
            let current_wp_file = home.appendingPathComponent(".local/share/macpaper/current_wallpaper")
            
            if FileManager.default.fileExists(atPath: current_wp_file.path) {
                try? FileManager.default.removeItem(at: current_wp_file)
            }
            
            completion()
            return
        }
    }
    
    // for moving wallpapers, use macpaper-bin
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
        selected_wp = nil
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

struct endup_wp: Identifiable, Equatable {
    let id: UUID
    let name: String
    let path: String
    let preview: String?
    let createdDate: Date
    let fileSize: Int64
}