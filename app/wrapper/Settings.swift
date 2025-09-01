// Settings.swift

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var service: macpaperService
    @State private var ap_is_enabled: Bool = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text(NSLocalizedString("settings", comment: "settings"))
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundStyle(.primary.opacity(0.9))
                .padding(.top, 20)
            
            Divider()
            
            Toggle(isOn: $ap_is_enabled) {
                HStack(spacing: 12) {
                    Image(systemName: "pause.circle.fill")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.primary.opacity(0.8))
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(NSLocalizedString("cfg_auto_pause", comment: "Smart Playback"))
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                         Text(NSLocalizedString("cfg_auto_pause_desc", comment: "Description"))
                            .font(.system(size: 11, weight: .regular, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .toggleStyle(SwitchToggleStyle(tint: .blue))
            .onChange(of: ap_is_enabled) { newValue in
                service._ap_enabled(newValue)
            }
            
            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
        .frame(width: 300, height: 200)
        .onAppear {
            ap_is_enabled = service.ap_is_enabled
        }
    }
}