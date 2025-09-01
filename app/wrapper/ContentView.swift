// ContentView.swift

import SwiftUI

struct ContentView: View {
    @State private var selectedTab: TabSelection? /*= .wallpapers */
    @State private var showAuthPrompt = false
    @State private var isAuthenticating = false
    @State private var version_label_alpha: Double = 0.6
    
    private func app_version() -> String {
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
            return "v\(version) (\(build))"
        }
        return "unknown"
    }
    
    enum TabSelection: CaseIterable {
        case wallpapers
        
        var title: String {
            switch self {
            case .wallpapers: return NSLocalizedString("mgr_wp_title", comment: "wallpapers")
            }
        }
        
        var icon: String {
            switch self {
            case .wallpapers: return "photo.on.rectangle"
            }
        }
    }
    
    var body: some View {
        ZStack {
            Color.clear
            
            VStack(spacing: 0) {
            HStack(spacing: 20) {
            HStack(spacing: 12) {
            Image(systemName: "sparkles")
                .font(.system(size: 24, weight: .medium))
                .foregroundStyle(.primary.opacity(0.8))
            Text(NSLocalizedString("mgr_title", comment: "macpaper"))
                .font(.system(size: 28, weight: .semibold, design: .rounded))
                .foregroundStyle(.primary.opacity(0.9))
            
            Text(app_version())
                .font(.system(size: 12, weight: .regular, design: .monospaced))
                .foregroundStyle(.secondary.opacity(version_label_alpha))
                .padding(.leading, 4)
                .padding(.top, 4)
                }
                    
            Spacer()
                    
            HStack(spacing: 8) {
                tabButton(
                    title: TabSelection.wallpapers.title,
                    icon: TabSelection.wallpapers.icon,
                    isSelected: true,
                    action: {}
                )
            }
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 24)
        .background(
            bg()
        )
        .padding(.horizontal, 16)
        .padding(.top, 16)
        
        ZStack {
            ManagerView()
                .transition(.opacity)
        }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .focusable(false)
        }
    }
}

struct tabButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                Text(title)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
            }
            .foregroundStyle(isSelected ? .primary : .secondary)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.regularMaterial)
                        .overlay {
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(.primary.opacity(0.1), lineWidth: 1)
                        }
                } else if isHovered {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.quaternary.opacity(0.3))
                }
            }
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
    }
}

struct bg: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(.ultraThinMaterial)
            .overlay {
                RoundedRectangle(cornerRadius: 20)
                    .stroke(.primary.opacity(0.08), lineWidth: 0.5)
            }
    }
}
