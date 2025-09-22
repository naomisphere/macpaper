// ManagerApp.swift

import SwiftUI
import AVKit
import UniformTypeIdentifiers

class MenuHandler: NSObject {
    weak var service: macpaperService?
    
    @objc func toggleVideos() {
        guard let service = service else { return }
        service.showVideos.toggle()
        service.fetch_wallpapers()
        print("toggle videos: \(service.showVideos)")
    }
    
    @objc func toggleImages() {
        guard let service = service else { return }
        service.showImages.toggle()
        service.fetch_wallpapers()
        print("toggle images: \(service.showImages)")
    }
}

struct ManagerView: View {
    @StateObject private var service = macpaperService()
    @State private var show_importer = false
    @State private var file_drag = false
    private let menuHandler = MenuHandler()
    
    var body: some View {
        VStack(spacing: 0) {
            toolbarView
            contentView
        }
        .onAppear {
            service.fetch_wallpapers()
            menuHandler.service = service
        }
        .fileImporter(
            isPresented: $show_importer,
            allowedContentTypes: [
                UTType.movie,
                UTType.gif,
                UTType.jpeg,
                UTType.png,
                UTType(filenameExtension: "mp4")!,
                UTType(filenameExtension: "mov")!,
                UTType(filenameExtension: "gif")!,
                UTType(filenameExtension: "jpg")!,
                UTType(filenameExtension: "jpeg")!,
                UTType(filenameExtension: "png")!
            ],
            allowsMultipleSelection: true
        ) { result in
            switch result {
            case .success(let urls):
                for url in urls {
                    import_wp(from: url)
                }
            case .failure(let error):
                print("couldn't import file: \(error)")
            }
        }
    }
    
    private var toolbarView: some View {
        HStack(spacing: 16) {
            SimpleButton(
                title: NSLocalizedString("add_wallpaper", comment: "add wallpaper"),
                icon: "plus",
                isPrimary: true,
                action: {
                    show_importer = true
                }
            )

            SimpleButton(
                title: NSLocalizedString("mgr_settings", comment: "settings"),
                icon: "gearshape",
                isPrimary: false,
                action: {
                    show_settings()
                }
            )
        
            Spacer()
            
            if service.current_wp != nil && !isStillWallpaper(service.current_wp!) {
                Button(action: {
                    service.wp_doPersist(!service.wp_is_agent)
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: service.wp_is_agent ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 13, weight: .medium))
                        Text(NSLocalizedString("persist", comment: "persist toggle"))
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                    }
                    .foregroundStyle(service.wp_is_agent ? .primary : .secondary)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.regularMaterial.opacity(service.wp_is_agent ? 0.9 : 0.5))
                            .overlay {
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(.primary.opacity(service.wp_is_agent ? 0.3 : 0.2), lineWidth: 1)
                            }
                    }
                }
                .buttonStyle(.plain)
                
                SimpleButton(
                    title: NSLocalizedString("unset_current", comment: "unset current wallpaper"),
                    icon: "xmark",
                    isPrimary: false,
                    action: {
                        service.unset_wp()
                    }
                )
            }

            SimpleButton(
                title: NSLocalizedString("filter", comment: "Filter"),
                icon: "line.3.horizontal.decrease.circle",
                isPrimary: false,
                action: {
                    showFilterMenu()
                }
            )
            
            SimpleButton(
                title: NSLocalizedString("refresh", comment: "refresh wallpapers"),
                icon: "arrow.clockwise",
                isPrimary: false,
                action: {
                    service.fetch_wallpapers()
                }
            )
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 20)
        .background {
            RoundedRectangle(cornerRadius: 22)
                .fill(.ultraThinMaterial.opacity(0.9))
                .overlay {
                    RoundedRectangle(cornerRadius: 22)
                        .stroke(.primary.opacity(0.1), lineWidth: 0.5)
                }
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
    }

    private func show_settings() {
    let settingsView = SettingsView()
        .environmentObject(service)
    
    let window = NSWindow(
        contentRect: NSRect(x: 0, y: 0, width: 500, height: 500),
        styleMask: [.titled, .closable, .resizable],
        backing: .buffered,
        defer: false
    )
    
    if let managerWindow = NSApp.keyWindow {
        let managerFrame = managerWindow.frame
        let settingsSize = window.frame.size
        
        let x = managerFrame.midX - settingsSize.width / 2
        let y = managerFrame.midY - settingsSize.height / 2
        
        window.setFrameOrigin(NSPoint(x: x, y: y))
    } else {
        window.center()
    }
    
    window.title = "Settings"
    window.titleVisibility = .hidden
    window.contentView = NSHostingView(rootView: settingsView)
    window.isReleasedWhenClosed = false
    window.makeKeyAndOrderFront(nil)
    NSApp.activate(ignoringOtherApps: true)
}

    private func showFilterMenu() {
    let menu = NSMenu()
    
    let filterHeader = NSMenuItem(
        title: NSLocalizedString("show_types", comment: "Show"),
        action: nil,
        keyEquivalent: ""
    )
    filterHeader.isEnabled = false
    menu.addItem(filterHeader)
    
    let videoItem = NSMenuItem(
        title: NSLocalizedString("show_videos", comment: "Videos"),
        action: #selector(MenuHandler.toggleVideos),
        keyEquivalent: ""
    )
    videoItem.target = menuHandler
    videoItem.state = service.showVideos ? .on : .off
    menu.addItem(videoItem)
    
    let imageItem = NSMenuItem(
        title: NSLocalizedString("show_images", comment: "Images"),
        action: #selector(MenuHandler.toggleImages),
        keyEquivalent: ""
    )
    imageItem.target = menuHandler
    imageItem.state = service.showImages ? .on : .off
    menu.addItem(imageItem)
    
    if let window = NSApp.keyWindow,
       let contentView = window.contentView {
        
        let filterButtonTitle = NSLocalizedString("filter", comment: "Filter")
        if let filterButton = findButton(with: filterButtonTitle, in: contentView) {
            let buttonFrame = filterButton.convert(filterButton.bounds, to: nil)
            let menuPosition = NSPoint(x: buttonFrame.minX, y: buttonFrame.maxY)
            menu.popUp(positioning: nil, at: menuPosition, in: nil)
        } else {
            menu.popUp(positioning: nil, at: NSEvent.mouseLocation, in: nil)
        }
    }
}

private func findButton(with title: String, in view: NSView) -> NSButton? {
    for subview in view.subviews {
        if let button = subview as? NSButton, button.title == title {
            return button
        }
        if let foundButton = findButton(with: title, in: subview) {
            return foundButton
        }
    }
    return nil
}
    
    private var contentView: some View {
        ZStack {
            if service.isLoading {
                loadingView
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 0.9)),
                        removal: .opacity.combined(with: .scale(scale: 1.1))
                    ))
            } else if service.wallpapers.isEmpty {
                NoWpView
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 0.95)),
                        removal: .opacity
                    ))
            } else {
                gridView
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .bottom)),
                        removal: .opacity
                    ))
            }
        }
        .animation(.easeInOut(duration: 0.4), value: service.isLoading)
        .animation(.easeInOut(duration: 0.4), value: service.wallpapers.isEmpty)
    }
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(.thinMaterial)
                    .frame(width: 80, height: 80)
                    .overlay {
                        Circle()
                            .stroke(.primary.opacity(0.1), lineWidth: 1)
                    }
                
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .primary.opacity(0.7)))
                    .scaleEffect(1.2)
            }
            
            VStack(spacing: 8) {
                Text(NSLocalizedString("loading_wallpapers", comment: "loading wallpapers"))
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundStyle(.primary.opacity(0.8))
                
                Text(NSLocalizedString("scanning_files", comment: "scanning for video files"))
                    .font(.system(size: 13, weight: .regular, design: .rounded))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .transition(.opacity.combined(with: .scale(scale: 0.95)))
    }
    
    private var NoWpView: some View {
        VStack(spacing: 24) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 48, weight: .ultraLight))
                .foregroundStyle(.primary.opacity(0.4))
            
            VStack(spacing: 8) {
                Text(NSLocalizedString("no_wallpapers_found", comment: "no wallpapers found"))
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundStyle(.primary.opacity(0.8))
                
                Text(NSLocalizedString("drop_files_or_add", comment: "drop files or add wallpaper"))
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                
                Text(NSLocalizedString("supported_formats", comment: "supported file formats"))
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .foregroundStyle(.secondary.opacity(0.8))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
        .onDrop(of: [.fileURL], isTargeted: $file_drag) { providers in
            drop_handle(providers)
        }
    }
    
    private var gridView: some View {
        ScrollView {
            let columns = [
                GridItem(.fixed(300), spacing: 30),
                GridItem(.fixed(300), spacing: 30),
                GridItem(.fixed(300), spacing: 30)
            ]
            
            LazyVGrid(columns: columns, alignment: .center, spacing: 30) {
                ForEach(Array(service.wallpapers.enumerated()), id: \.element.id) { index, wallpaper in
                    WallpaperCard(
                        wallpaper: wallpaper,
                        isActive: service.current_wp == wallpaper.path,
                        onSelect: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                service.set_wp(wallpaper)
                            }
                        },
                        onDelete: {
                            withAnimation(.easeInOut(duration: 0.4)) {
                                delete_wp(wallpaper)
                            }
                        },
                        onRename: { newName in
                            rename_wp(wallpaper, to: newName)
                        }
                    )
                    .environmentObject(service)
                    .frame(width: 300, height: 260)
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 0.8).combined(with: .offset(y: 20))),
                        removal: .opacity.combined(with: .scale(scale: 0.8))
                    ))
                    .animation(.easeOut(duration: 0.4).delay(Double(index) * 0.1), value: service.wallpapers.count)
                }
            }
            .padding(32)
        }
        .onDrop(of: [.fileURL], isTargeted: $file_drag) { providers in
            drop_handle(providers)
        }
    }
    
    private func drop_handle(_ providers: [NSItemProvider]) -> Bool {
        for provider in providers {
            _ = provider.loadObject(ofClass: URL.self) { url, _ in
                guard let url = url else { return }
                DispatchQueue.main.async {
                    import_wp(from: url)
                }
            }
            return true
        }
        return false
    }
    
    private func import_wp(from url: URL) {
        let ext = url.pathExtension.lowercased()
        guard ["mp4", "mov", "gif", "jpg", "jpeg", "png"].contains(ext) else {
            return
        }
        
        let wp_storage_dir = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".local/share/paper/wallpaper")
        
        do {
            try FileManager.default.createDirectory(at: wp_storage_dir, withIntermediateDirectories: true)
            
            let fileName = url.lastPathComponent
            let destination = wp_storage_dir.appendingPathComponent(fileName)
            
            if FileManager.default.fileExists(atPath: destination.path) {
                try FileManager.default.removeItem(at: destination)
            }
            
            try FileManager.default.copyItem(at: url, to: destination)
            service.fetch_wallpapers()
        } catch {
            print(error)
        }
    }
    
    private func delete_wp(_ wallpaper: endup_wp) {
        do {
            try FileManager.default.removeItem(atPath: wallpaper.path)
            service.fetch_wallpapers()
        } catch {
            print(error)
        }
    }
    
    private func rename_wp(_ wallpaper: endup_wp, to newName: String) {
        let fileURL = URL(fileURLWithPath: wallpaper.path)
        let directory = fileURL.deletingLastPathComponent()
        let fileExtension = fileURL.pathExtension
        let newFileName = "\(newName).\(fileExtension)"
        let newURL = directory.appendingPathComponent(newFileName)
        
        do {
            try FileManager.default.moveItem(at: fileURL, to: newURL)
            service.fetch_wallpapers()
        } catch {
            print("Error renaming file: \(error)")
        }
    }
    
    private func isStillWallpaper(_ path: String) -> Bool {
        let ext = (path as NSString).pathExtension.lowercased()
        return ["jpg", "jpeg", "png"].contains(ext)
    }
}

struct videoPreview: View {
    let videoURL: URL
    @State private var thumbnail: NSImage?
    
    private static var thumbnailCache = NSCache<NSString, NSImage>()
    private static var loadingOperations = [String: Operation]()
    private static let operationQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 3
        queue.qualityOfService = .utility
        return queue
    }()
    
    var body: some View {
        ZStack {
            if let thumbnail = thumbnail {
                Image(nsImage: thumbnail)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Rectangle()
                    .fill(Color.brown.opacity(0.3))
                    .overlay {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white.opacity(0.7)))
                            .scaleEffect(0.8)
                    }
            }
        }
        .onAppear {
            loadThumbnail()
        }
        .onDisappear {
            cancelLoading()
        }
    }

    private func loadThumbnail() {
        let cacheKey = videoURL.path as NSString
        
        if let cachedThumbnail = Self.thumbnailCache.object(forKey: cacheKey) {
            self.thumbnail = cachedThumbnail
            return
        }
        
        cancelLoading()
        
        var operation: BlockOperation?
        
        operation = BlockOperation {
            if operation?.isCancelled ?? true { return }
            
            let asset = AVAsset(url: self.videoURL)
            let imageGenerator = AVAssetImageGenerator(asset: asset)
            imageGenerator.appliesPreferredTrackTransform = true
            imageGenerator.maximumSize = CGSize(width: 300, height: 200)
            imageGenerator.requestedTimeToleranceAfter = .zero
            imageGenerator.requestedTimeToleranceBefore = .zero
            
            do {
                let cgImage = try imageGenerator.copyCGImage(at: CMTime(seconds: 1, preferredTimescale: 60), actualTime: nil)
                let nsImage = NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
                
                if operation?.isCancelled ?? true { return }
                
                Self.thumbnailCache.setObject(nsImage, forKey: cacheKey)
                
                DispatchQueue.main.async {
                    Self.loadingOperations.removeValue(forKey: self.videoURL.path)
                    if let op = operation, !op.isCancelled {
                        self.thumbnail = nsImage
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    Self.loadingOperations.removeValue(forKey: self.videoURL.path)
                }
            }
        }
        
        if let op = operation {
            Self.loadingOperations[videoURL.path] = op
            Self.operationQueue.addOperation(op)
        }
    }

    private func cancelLoading() {
        if let operation = Self.loadingOperations[videoURL.path] {
            operation.cancel()
            Self.loadingOperations.removeValue(forKey: videoURL.path)
        }
    }
}

struct SimpleButton: View {
    let title: String
    let icon: String
    let isPrimary: Bool
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .medium))
                Text(title)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
            }
            .foregroundStyle(isPrimary ? .primary : .secondary)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background {
                RoundedRectangle(cornerRadius: 16)
                    .fill(.regularMaterial.opacity(isPrimary ? 0.9 : (isHovered ? 0.7 : 0.5)))
                    .overlay {
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(.primary.opacity(isPrimary ? 0.3 : 0.2), lineWidth: 1)
                    }
            }
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }
}

struct VolumeSlider: View {
    @Binding var volume: Double
    let onVolumeChange: (Double) -> Void
    
    @State private var isHovered = false
    @State private var isDragging = false
    @State private var lastUpdateTime = Date()
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: volume == 0 ? "speaker.slash.fill" : (volume < 0.33 ? "speaker.fill" : (volume < 0.67 ? "speaker.wave.1.fill" : "speaker.wave.2.fill")))
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.primary.opacity(0.8))
                .frame(width: 16)
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(.regularMaterial.opacity(0.6))
                        .overlay {
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(.primary.opacity(0.15), lineWidth: 0.5)
                        }
                        .frame(height: 12)
                    
                    RoundedRectangle(cornerRadius: 6)
                        .fill(LinearGradient(
                            colors: [
                                Color.primary.opacity(0.8),
                                Color.primary.opacity(0.6)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        ))
                        .frame(width: geometry.size.width * volume, height: 12)
                        .overlay {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(.white.opacity(isDragging ? 0.3 : 0.2))
                        }
                    
                    Circle()
                        .fill(.regularMaterial)
                        .overlay {
                            Circle()
                                .fill(.white.opacity(0.9))
                                .scaleEffect(0.7)
                        }
                        .overlay {
                            Circle()
                                .stroke(.primary.opacity(0.2), lineWidth: 1)
                        }
                        .frame(width: isDragging ? 18 : 16, height: isDragging ? 18 : 16)
                        .position(
                            x: max(8, min(geometry.size.width - 8, geometry.size.width * volume)),
                            y: geometry.size.height / 2
                        )
                        .scaleEffect(isHovered || isDragging ? 1.1 : 1.0)
                }
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            if !isDragging {
                                withAnimation(.easeOut(duration: 0.2)) {
                                    isDragging = true
                                }
                            }
                            
                            let newVolume = max(0, min(1, value.location.x / geometry.size.width))
                            volume = newVolume
                            
                            let now = Date()
                            if now.timeIntervalSince(lastUpdateTime) > 0.02 {
                                lastUpdateTime = now
                                onVolumeChange(newVolume)
                            }
                        }
                        .onEnded { _ in
                            withAnimation(.easeOut(duration: 0.2)) {
                                isDragging = false
                            }
                            onVolumeChange(volume)
                        }
                )
            }
            .frame(width: 80, height: 20)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(.regularMaterial.opacity(0.9))
                .overlay {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(.primary.opacity(0.2), lineWidth: 1)
                }
        }
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }
}

struct WallpaperCard: View {
    let wallpaper: endup_wp
    let isActive: Bool
    let onSelect: () -> Void
    let onDelete: () -> Void
    let onRename: (String) -> Void
    
    @State private var isHovered = false
    @State private var isEditing = false
    @State private var editedName = ""
    @FocusState private var isNameFocused: Bool
    @EnvironmentObject private var service: macpaperService
    
    private var isStillWallpaper: Bool {
        let ext = (wallpaper.path as NSString).pathExtension.lowercased()
        return ["jpg", "jpeg", "png"].contains(ext)
    }
    
    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            previewSection
                .frame(maxWidth: .infinity)
            infoSection
                .frame(height: 50)
        }
        .frame(width: 300, height: 260)
        .padding(12)
        .background {
            RoundedRectangle(cornerRadius: 22)
                .fill(.regularMaterial.opacity(0.8))
                .overlay {
                    RoundedRectangle(cornerRadius: 22)
                        .stroke(.primary.opacity(0.1), lineWidth: 0.5)
                }
        }
        .onChange(of: isEditing) { editing in
            if editing {
                editedName = wallpaper.name
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isNameFocused = true
                }
            }
        }
    }
    
    private var previewSection: some View {
        ZStack {
            Rectangle()
                .fill(Color.brown.opacity(0.2))
            
            let ext = (wallpaper.path as NSString).pathExtension.lowercased()
            
            if ["gif", "jpg", "jpeg", "png"].contains(ext) {
                LazyImagePreview(path: wallpaper.path)
            } else if ["mp4", "mov"].contains(ext) {
                videoPreview(videoURL: URL(fileURLWithPath: wallpaper.path))
                    .clipped()
                    .overlay {
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 32, weight: .light))
                            .foregroundStyle(.white.opacity(0.8))
                            .background {
                                Circle()
                                    .fill(.black.opacity(0.3))
                                    .frame(width: 40, height: 40)
                            }
                    }
            } else {
                Image(systemName: "photo")
                    .font(.system(size: 24, weight: .light))
                    .foregroundStyle(.secondary)
            }
            
            if isHovered || isActive {
                overlayControls
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 0.9)),
                        removal: .opacity.combined(with: .scale(scale: 1.1))
                    ))
            }
        }
        .frame(width: 276, height: 184)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    isActive 
                        ? Color.primary.opacity(0.4)
                        : Color.primary.opacity(0.1), 
                    lineWidth: isActive ? 2 : 1
                )
        }
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .onHover { hovering in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isHovered = hovering
            }
        }
    }

    private var overlayControls: some View {
        ZStack {
            LinearGradient(
                colors: [
                    .black.opacity(0.6),
                    .black.opacity(0.3),
                    .clear
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            
            VStack {
                HStack {
                    if isActive {
                        Circle()
                            .fill(.green.opacity(0.9))
                            .frame(width: 24, height: 24)
                            .overlay {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(.white)
                            }
                            .background {
                                Circle()
                                    .fill(.regularMaterial)
                                    .frame(width: 28, height: 28)
                            }
                    }
                    
                    Spacer()
                    
                    if isActive && !isStillWallpaper {
                        VolumeSlider(
                            volume: $service.volume,
                            onVolumeChange: { newVolume in
                                service.chvol(newVolume)
                            }
                        )
                        .scaleEffect(0.85)
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.8).combined(with: .opacity),
                            removal: .scale(scale: 0.8).combined(with: .opacity)
                        ))
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 8) {
                        Button(action: {
                            isEditing = true
                        }) {
                            Circle()
                                .fill(.mint.opacity(0.9))
                                .frame(width: 24, height: 24)
                                .overlay {
                                    Image(systemName: "pencil")
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundStyle(.white)
                                }
                                .background {
                                    Circle()
                                        .fill(.regularMaterial)
                                        .frame(width: 28, height: 28)
                                }
                        }
                        .buttonStyle(.plain)
                        
                        Button(action: onDelete) {
                            Circle()
                                .fill(.red.opacity(0.9))
                                .frame(width: 24, height: 24)
                                .overlay {
                                    Image(systemName: "trash")
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundStyle(.white)
                                }
                                .background {
                                    Circle()
                                        .fill(.regularMaterial)
                                        .frame(width: 28, height: 28)
                                }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.top, 12)
                
                Spacer()
                
                if !isActive {
                    SimpleButton(
                        title: NSLocalizedString("set_wallpaper", comment: "set wallpaper"),
                        icon: "wand.and.stars",
                        isPrimary: true,
                        action: onSelect
                    )
                    .padding(.bottom, 12)
                }
            }
        }
        .frame(width: 276, height: 184)
    }
    
    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            if isEditing {
                HStack(spacing: 4) {
                    TextField("", text: $editedName)
                        .textFieldStyle(PlainTextFieldStyle())
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(.primary.opacity(0.9))
                        .focused($isNameFocused)
                        .onSubmit {
                            saveName()
                        }
                    
                    Button(action: saveName) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.green)
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: {
                        isEditing = false
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.red)
                    }
                    .buttonStyle(.plain)
                }
                .padding(4)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.primary.opacity(0.1))
                )
            } else {
                Text(wallpaper.name)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(.primary.opacity(0.9))
                    .lineLimit(2)
            }
            
            HStack {
                let ext = (wallpaper.path as NSString).pathExtension.lowercased()
                
                let fileType = ["mp4", "mov"].contains(ext) ? "video" :
                            ext == "gif" ? "gif" :
                            ["jpg", "jpeg", "png"].contains(ext) ? "image" : "unknown"
                
                Text(fileType)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background {
                        Capsule()
                            .fill(Color.brown.opacity(0.3))
                    }
                
                Spacer()
                
                Text(ByteCountFormatter.string(fromByteCount: wallpaper.fileSize, countStyle: .file))
                    .font(.system(size: 11, weight: .regular, design: .rounded))
                    .foregroundStyle(.secondary.opacity(0.8))
            }
        }
    }
    
    private func saveName() {
        if !editedName.isEmpty && editedName != wallpaper.name {
            onRename(editedName)
        }
        isEditing = false
    }
}

struct LazyImagePreview: View {
    let path: String
    @State private var image: NSImage?
    
    var body: some View {
        Group {
            if let image = image {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: 276, maxHeight: 184)
                    .clipped()
            } else {
                Rectangle()
                    .fill(Color.brown.opacity(0.3))
                    .onAppear {
                        loadThumbnail()
                    }
            }
        }
    }
    
    private func loadThumbnail() {
        if let cachedImage = ImageCache.shared.getImage(forKey: path) {
            self.image = cachedImage
            return
        }
        
        DispatchQueue.global(qos: .utility).async {
            if let fullImage = NSImage(contentsOfFile: self.path) {
                let targetSize = NSSize(width: 276, height: 184)
                let thumbnail = self.resizeImageToFill(fullImage, to: targetSize)
                
                ImageCache.shared.setImage(thumbnail, forKey: self.path)
                
                DispatchQueue.main.async {
                    self.image = thumbnail
                }
            }
        }
    }
    
    private func resizeImageToFill(_ image: NSImage, to size: NSSize) -> NSImage {
        let imageSize = image.size
        let widthRatio  = size.width / imageSize.width
        let heightRatio = size.height / imageSize.height
        
        let scaleRatio = max(widthRatio, heightRatio)
        
        let scaledSize = NSSize(
            width: imageSize.width * scaleRatio,
            height: imageSize.height * scaleRatio
        )
        
        let newImage = NSImage(size: size)
        newImage.lockFocus()
        
        let drawingRect = NSRect(
            x: (size.width - scaledSize.width) / 2,
            y: (size.height - scaledSize.height) / 2,
            width: scaledSize.width,
            height: scaledSize.height
        )
        
        image.draw(in: drawingRect,
                  from: NSRect(origin: .zero, size: imageSize),
                  operation: .copy,
                  fraction: 1.0)
        newImage.unlockFocus()
        return newImage
    }
}

class ImageCache {
    static let shared = ImageCache()
    private var cache = NSCache<NSString, NSImage>()
    
    private init() {
        cache.countLimit = 30
        cache.totalCostLimit = 50 * 1024 * 1024 // 50 MB
    }
    
    func getImage(forKey key: String) -> NSImage? {
        return cache.object(forKey: key as NSString)
    }
    
    func setImage(_ image: NSImage, forKey key: String) {
        let cost = image.size.width * image.size.height * 4
        cache.setObject(image, forKey: key as NSString, cost: Int(cost))
    }
    
    func clear() {
        cache.removeAllObjects()
    }
}