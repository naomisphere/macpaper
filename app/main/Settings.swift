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
    @State private var ap_is_enabled: Bool = false
    
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
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(.primary.opacity(0.8))
                    
                    Text(NSLocalizedString("settings", comment: "Settings"))
                        .font(.system(size: 24, weight: .semibold, design: .rounded))
                    
                    Spacer()
                }

                HStack(spacing: 0) {
                    ForEach(SettingsTab.allCases, id: \.self) { tab in
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedTab = tab
                            }
                        }) {
                            VStack(spacing: 6) {
                                HStack(spacing: 6) {
                                    Image(systemName: tab.icon)
                                        .font(.system(size: 12, weight: .medium))
                                    Text(tab.title)
                                        .font(.system(size: 12, weight: .medium))
                                }
                                .foregroundStyle(selectedTab == tab ? .primary : .secondary)
                                
                                Rectangle()
                                    .fill(selectedTab == tab ? .primary : Color.clear)
                                    .frame(height: 2)
                                    .cornerRadius(1)
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .focusable(false)
                        
                        if tab != SettingsTab.allCases.last {
                            Spacer()
                        }
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 16)
            
            Divider()
                .padding(.horizontal, 16)

            ScrollView {
                VStack(spacing: 20) {
                    Group {
                        switch selectedTab {
                        case .general:
                            generalSettings
                        case .manager:
                            managerSettings
                        case .playback:
                            playbackSettings
                        }
                    }
                    .padding(.horizontal, 24)
                }
                .padding(.vertical, 20)
            }
        }
        .frame(minWidth: 500, minHeight: 400)
        .onAppear {
            loadAPIKey()
            ap_is_enabled = service.ap_is_enabled
        }
    }
    
    private var generalSettings: some View {
        /* general settings start */
        VStack(alignment: .leading, spacing: 20) {
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
    
    /* manager settings start */
    private var managerSettings: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Nothing to see here.. for now")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 40)
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
