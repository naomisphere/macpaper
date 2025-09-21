// Settings.swift

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var service: macpaperService
    @State private var apiKey = ""
    @State private var showAPIKeyField = false
    @State private var isSaving = false
    @State private var saveSuccess = false
    @State private var ap_is_enabled: Bool = false
    @State private var apiKeyError: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(NSLocalizedString("settings", comment: "Settings"))
                .font(.system(size: 24, weight: .semibold))
                .padding(.bottom, 8)
            
            /* smart playback start */
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    Image(systemName: "pause.circle.fill")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.primary.opacity(0.8))
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(NSLocalizedString("cfg_auto_pause", comment: "Smart Playback"))
                            .font(.system(size: 16, weight: .medium))
                        
                        Text(NSLocalizedString("cfg_auto_pause_desc", comment: "Description"))
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }
                
                Toggle("", isOn: $ap_is_enabled)
                    .toggleStyle(SwitchToggleStyle(tint: .blue))
                    .onChange(of: ap_is_enabled) { newValue in
                        service._ap_enabled(newValue)
                    }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.1))
            )
            /* smart playback end */
            
            /* wh api key start */
            VStack(alignment: .leading, spacing: 12) {
                Text(NSLocalizedString("settings_api_key", comment: "Wallhaven API Key"))
                    .font(.system(size: 16, weight: .medium))
                
                Text(NSLocalizedString("settings_api_key_description", comment: ""))
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
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.1))
            )
            
            Spacer()
        }
        .padding()
        .onAppear {
            loadAPIKey()
            ap_is_enabled = service.ap_is_enabled
        }
    }
    
    private func validateAPIKey(_ key: String) {
        if key.isEmpty {
            apiKeyError = nil
            return
        }
        
        // as far as i could research, they're always 32 characters long. Not that I would know.
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