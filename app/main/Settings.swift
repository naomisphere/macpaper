// Settings.swift

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var service: macpaperService
    @State private var selectedTab: SettingsTab = .general
    @State private var apiKey = ""
    @State private var showAPIKeyField = false
    @State private var isSaving = false
    @State private var saveSuccess = false
    @State private var apiKeyError: String?
    
    @AppStorage("checkForUpdates") private var checkForUpdates = true
    @AppStorage("autoStartEnabled") private var autoStartEnabled = false
    @AppStorage("exportFolderPath") private var exportFolderPath = ""
    @State private var ap_is_enabled: Bool = false
    @State private var showFolderPicker = false
    
    enum SettingsTab: CaseIterable, Identifiable, Hashable {
        case general, manager, playback
        
        var id: Self { self }
        
        var title: String {
            switch self {
            case .general: return NSLocalizedString("settings_general", comment: "General")
            case .manager: return NSLocalizedString("settings_manager", comment: "Manager")
            case .playback: return NSLocalizedString("settings_playback", comment: "Playback")
            }
        }
        
        var icon: String {
            switch self {
            case .general: return "gearshape"
            case .manager: return "macwindow"
            case .playback: return "play.circle"
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(.blue)
                
                Text(NSLocalizedString("settings", comment: "Settings"))
                    .font(.system(size: 22, weight: .bold))
                
                Spacer()
            }
            .padding(.horizontal, 28)
            .padding(.top, 24)
            .padding(.bottom, 20)
            
            HStack(spacing: 12) {
                ForEach(SettingsTab.allCases, id: \.self) { tab in
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            selectedTab = tab
                        }
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 13, weight: .medium))
                            Text(tab.title)
                                .font(.system(size: 13, weight: .medium))
                        }
                        .padding(.horizontal, 18)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(selectedTab == tab ? Color.blue : Color.clear)
                        )
                        .foregroundStyle(selectedTab == tab ? .white : .secondary)
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 16)
            
            Divider()
                .padding(.horizontal, 20)

            ScrollView(.vertical, showsIndicators: true) {
                VStack(spacing: 24) {
                    switch selectedTab {
                    case .general:
                        generalSettings
                    case .manager:
                        managerSettings
                    case .playback:
                        playbackSettings
                    }
                }
                .padding(.horizontal, 28)
                .padding(.vertical, 24)
            }
        }
        .frame(minWidth: 550, idealWidth: 600, minHeight: 500, idealHeight: 550)
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            loadAPIKey()
            ap_is_enabled = service.ap_is_enabled
            loadExportFolder()
            checkAutoStartStatus()
        }
    }
    
    private var generalSettings: some View {
        VStack(alignment: .leading, spacing: 20) {
            Section(title: NSLocalizedString("settings_startup", comment: "Startup")) {
                SToggle(
                    title: NSLocalizedString("settings_auto_start", comment: "Start at Login"),
                    description: NSLocalizedString("settings_auto_start_desc", comment: "Automatically start macpaper when you log in"),
                    isOn: $autoStartEnabled
                )
                .onChange(of: autoStartEnabled) { newValue in
                    toggleAutoStart(newValue)
                }
            }
            
            Section(title: NSLocalizedString("settings_updates", comment: "Updates")) {
                SToggle(
                    title: NSLocalizedString("settings_check_updates", comment: "Check for Updates"),
                    description: NSLocalizedString("settings_check_updates_desc", comment: "Check for Updates on startup"),
                    isOn: $checkForUpdates
                )
            }

            /* wallhaven start */
            Section(title: "Wallhaven") {
                VStack(alignment: .leading, spacing: 12) {
                    Text(NSLocalizedString("settings_api_key", comment: "API Key"))
                        .font(.system(size: 14, weight: .medium))
                    
                    Text(NSLocalizedString("settings_api_key_description", comment: "Experimental. Clear if it breaks."))
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    
                    if showAPIKeyField {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 12) {
                                SecureField(NSLocalizedString("settings_enter_api_key", comment: "Enter API Key"), text: $apiKey)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .onChange(of: apiKey) { newValue in
                                        validateAPIKey(newValue)
                                    }
                                
                                Button(action: saveAPIKey) {
                                    if isSaving {
                                        ProgressView()
                                            .controlSize(.small)
                                    } else if saveSuccess {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.green)
                                    } else {
                                        Text(NSLocalizedString("settings_save", comment: "Save"))
                                    }
                                }
                                .disabled(isSaving)
                                
                                Button(action: {
                                    showAPIKeyField = false
                                    apiKeyError = nil
                                }) {
                                    Text(NSLocalizedString("settings_cancel", comment: "Cancel"))
                                }
                            }
                            
                            if let error = apiKeyError {
                                Text(error)
                                    .font(.system(size: 11))
                                    .foregroundColor(.red)
                                    .padding(.leading, 4)
                            }
                        }
                    } else {
                        HStack(spacing: 12) {
                            Text(apiKey.isEmpty ? 
                                 NSLocalizedString("settings_no_api_key", comment: "No API key set") : 
                                 NSLocalizedString("settings_api_key_set", comment: "API key is set"))
                                .foregroundColor(apiKey.isEmpty ? .red : .green)
                            
                            Spacer()
                            
                            Button(action: {
                                showAPIKeyField = true
                                apiKeyError = nil
                            }) {
                                Text(apiKey.isEmpty ? 
                                     NSLocalizedString("settings_add_api_key", comment: "Add API Key") : 
                                     NSLocalizedString("settings_change_api_key", comment: "Change"))
                            }
                        }
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.primary.opacity(0.05))
                )
            }
        }
    }
    
    private var managerSettings: some View {
        VStack(alignment: .leading, spacing: 20) {
            Section(title: NSLocalizedString("settings_export", comment: "Export")) {
                VStack(alignment: .leading, spacing: 12) {
                    Text(NSLocalizedString("settings_export_folder", comment: "Export Folder"))
                        .font(.system(size: 14, weight: .medium))
                    
                    Text(NSLocalizedString("settings_export_folder_desc", comment: "Choose where exported wallpapers are saved"))
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 12) {
                        Text(exportFolderPath.isEmpty ? 
                             NSLocalizedString("settings_export_folder_default", comment: "Pictures folder") : 
                             (exportFolderPath as NSString).lastPathComponent)
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                        
                        Spacer()
                        
                        Button(action: {
                            showFolderPicker = true
                        }) {
                            Text(NSLocalizedString("settings_choose_folder", comment: "Choose Folder"))
                        }
                        
                        if !exportFolderPath.isEmpty {
                            Button(action: {
                                exportFolderPath = ""
                                saveExportFolder()
                            }) {
                                Text(NSLocalizedString("settings_reset_folder", comment: "Reset"))
                            }
                        }
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.primary.opacity(0.05))
                )
            }
        }
        .fileImporter(
            isPresented: $showFolderPicker,
            allowedContentTypes: [.folder],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    exportFolderPath = url.path
                    saveExportFolder()
                }
            case .failure(let error):
                print("folder selection error: \(error)")
            }
        }
    }
    
    private var playbackSettings: some View {
        /* playback settings start */
        /* smart playback start */
        VStack(alignment: .leading, spacing: 20) {
            Section(title: NSLocalizedString("settings_behavior", comment: "Behavior")) {
                SToggle(
                    title: NSLocalizedString("cfg_auto_pause", comment: "Smart Playback"),
                    description: NSLocalizedString("cfg_auto_pause_desc", comment: ""),
                    isOn: $ap_is_enabled
                )
                .onChange(of: ap_is_enabled) { newValue in
                    service._ap_enabled(newValue)
                }
            }
            
            /* volume section start */
            Section(title: NSLocalizedString("settings_volume", comment: "Volume")) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text(NSLocalizedString("settings_default_volume", comment: "Default Volume"))
                            .font(.system(size: 14, weight: .medium))
                        
                        Spacer()
                        
                        Text("\(Int(service.volume * 100))%")
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                    
                    Slider(value: $service.volume, in: 0...1, step: 0.05)
                        .onChange(of: service.volume) { newValue in
                            service.chvol(newValue)
                        }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.primary.opacity(0.05))
                )
            }
        }
    }
    
    private func validateAPIKey(_ key: String) {
        if key.isEmpty {
            apiKeyError = nil
            return
        }
        
        if key.count != 32 {
            apiKeyError = NSLocalizedString("settings_invalid_api_key", comment: "Invalid API key")
        } else {
            apiKeyError = nil
        }
    }
    
    private func loadAPIKey() {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let plainKey = home.appendingPathComponent(".local/share/macpaper/WH_API_KEY")
        
        if FileManager.default.fileExists(atPath: plainKey.path) {
            do {
                apiKey = try String(contentsOf: plainKey).trimmingCharacters(in: .whitespacesAndNewlines)
            } catch {
                print("while reading API key: \(error)")
            }
        }
    }
    
    private func saveAPIKey() {
        if !apiKey.isEmpty && apiKeyError != nil {
            return
        }
        
        isSaving = true
        saveSuccess = false
        
        let home = FileManager.default.homeDirectoryForCurrentUser
        let plainKey = home.appendingPathComponent(".local/share/macpaper/WH_API_KEY")
        
        do {
            try FileManager.default.createDirectory(at: plainKey.deletingLastPathComponent(), withIntermediateDirectories: true)
            
            if apiKey.isEmpty {
                if FileManager.default.fileExists(atPath: plainKey.path) {
                    try FileManager.default.removeItem(at: plainKey)
                }
            } else {
                try apiKey.write(to: plainKey, atomically: true, encoding: .utf8)
            }
            
            saveSuccess = true
            showAPIKeyField = false
            apiKeyError = nil
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                saveSuccess = false
            }
        } catch {
            print("while saving API key: \(error)")
        }
        
        isSaving = false
    }
    
    private func toggleAutoStart(_ enabled: Bool) {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let launchAgent = home.appendingPathComponent("Library/LaunchAgents/com.naomisphere.macpaper.app.plist")
        let appPath = Bundle.main.bundlePath
        
        if enabled {
            let plistContent = """
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.naomisphere.macpaper.app</string>
    <key>ProgramArguments</key>
    <array>
        <string>\(appPath)/Contents/MacOS/macpaper</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <false/>
</dict>
</plist>
"""
            
            do {
                try FileManager.default.createDirectory(at: launchAgent.deletingLastPathComponent(), withIntermediateDirectories: true)
                try plistContent.write(to: launchAgent, atomically: true, encoding: .utf8)
                
                let loadTask = Process()
                loadTask.launchPath = "/bin/launchctl"
                loadTask.arguments = ["load", launchAgent.path]
                loadTask.launch()
                loadTask.waitUntilExit()
            } catch {
                print("while enabling auto start: \(error)")
                autoStartEnabled = false
            }
        } else {
            do {
                let unloadTask = Process()
                unloadTask.launchPath = "/bin/launchctl"
                unloadTask.arguments = ["unload", launchAgent.path]
                unloadTask.launch()
                unloadTask.waitUntilExit()
                
                if FileManager.default.fileExists(atPath: launchAgent.path) {
                    try FileManager.default.removeItem(at: launchAgent)
                }
            } catch {
                print("while disabling auto start: \(error)")
            }
        }
    }
    
    private func checkAutoStartStatus() {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let launchAgent = home.appendingPathComponent("Library/LaunchAgents/com.naomisphere.macpaper.app.plist")
        autoStartEnabled = FileManager.default.fileExists(atPath: launchAgent.path)
    }
    
    private func loadExportFolder() {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let settingsFile = home.appendingPathComponent(".local/share/macpaper/export_folder")
        
        if FileManager.default.fileExists(atPath: settingsFile.path) {
            do {
                exportFolderPath = try String(contentsOf: settingsFile).trimmingCharacters(in: .whitespacesAndNewlines)
            } catch {
                print("while reading export folder: \(error)")
            }
        }
        
        if exportFolderPath.isEmpty {
            let picturesURL = FileManager.default.urls(for: .picturesDirectory, in: .userDomainMask).first
            if let picturesPath = picturesURL?.path {
                exportFolderPath = picturesPath
            }
        }
    }
    
    private func saveExportFolder() {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let settingsFile = home.appendingPathComponent(".local/share/macpaper/export_folder")
        
        do {
            try FileManager.default.createDirectory(at: settingsFile.deletingLastPathComponent(), withIntermediateDirectories: true)
            
            if exportFolderPath.isEmpty {
                if FileManager.default.fileExists(atPath: settingsFile.path) {
                    try FileManager.default.removeItem(at: settingsFile)
                }
            } else {
                try exportFolderPath.write(to: settingsFile, atomically: true, encoding: .utf8)
            }
        } catch {
            print("while saving export folder: \(error)")
        }
    }
}

struct Section<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.primary.opacity(0.8))
                .padding(.leading, 4)
            
            content
        }
    }
}

struct SToggle: View {
    let title: String
    let description: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                
                Text(description)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .toggleStyle(SwitchToggleStyle(tint: .blue))
                .labelsHidden()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.primary.opacity(0.05))
        )
    }
}
