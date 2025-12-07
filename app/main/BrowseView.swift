//
// BrowseView.swift
//
// Created on September 17, 2025
// naomisphere
//

import SwiftUI
import Combine

struct BrowseView: View {
    @StateObject private var WHServ = WHService()
    @State private var searchQuery = ""
    @State private var chosen_sorting: WHSort = .date_added
    @State private var chosen_order: WHOrder = .desc
    @State private var chosen_purity: WHPurityStatus = .sfw
    @State private var chosen_categ: WHCategory = .all
    @State private var chosen_prov: Set<WallpaperProvider> = [.wallhaven]
    @State private var selectedResolution: ResolutionFilter = .all
    @State private var activeResolutionFilter: ResolutionFilter = .all
    @State private var currentPage = 1
    @State private var showFilters = false
    @State private var isLoading = false
    @State private var showAPIKeyAlert = false
    @State private var apiKey = ""
    
    enum ResolutionFilter: String, CaseIterable {
        case hd = "HD"
        case fullHd = "Full HD"
        case wqhd = "WQHD"
        case uhd4k = "4K UHD"
        case all = "All"
        
        var displayName: String {
            switch self {
            case .hd: return "HD"
            case .fullHd: return "Full HD"
            case .wqhd: return "WQHD"
            case .uhd4k: return "4K"
            case .all: return NSLocalizedString("filter_resolution_all", comment: "All")
            }
        }
        
        func matches(width: Int, height: Int) -> Bool {
            switch self {
            case .all:
                return true
            case .hd:
                let totalPixels = width * height
                return totalPixels >= 800_000 && totalPixels < 1_500_000
            case .fullHd:
                let totalPixels = width * height
                return totalPixels >= 1_500_000 && totalPixels < 3_000_000
            case .wqhd:
                let totalPixels = width * height
                return totalPixels >= 3_000_000 && totalPixels < 5_000_000
            case .uhd4k:
                let totalPixels = width * height
                return totalPixels >= 5_000_000
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            searchBar
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 8)
            
            if isLoading {
                loadingView
            } else if filteredWallpapers.isEmpty {
                emptyStateView
            } else {
                contentView
            }
        }
        .onAppear {
            if WHServ.wallpapers.isEmpty {
                loadWallpapers()
            }
        }
    }
    
    private var searchBar: some View {
        HStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                    .font(.system(size: 14))
                
                TextField(NSLocalizedString("browse_search_placeholder", comment: "Search wallpapers..."), text: $searchQuery)
                    .textFieldStyle(PlainTextFieldStyle())
                    .font(.system(size: 14))
                    .onSubmit {
                        currentPage = 1
                        loadWallpapers()
                    }
                
                if !searchQuery.isEmpty {
                    Button(action: {
                        searchQuery = ""
                        currentPage = 1
                        loadWallpapers()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background {
                RoundedRectangle(cornerRadius: 12)
                    .fill(.regularMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(.primary.opacity(0.1), lineWidth: 1)
                    }
            }
            
            Button(action: {
                showFilters.toggle()
            }) {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
                    .padding(10)
                    .background {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(.regularMaterial)
                            .overlay {
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(.primary.opacity(0.1), lineWidth: 1)
                            }
                    }
            }
            .buttonStyle(PlainButtonStyle())
            .popover(isPresented: $showFilters) {
                filtersView
                    .frame(width: 300)
                    .padding()
            }
        }
    }
    
    private var filtersView: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(NSLocalizedString("browse_filters", comment: "Filters"))
                .font(.system(size: 16, weight: .semibold))
            
            // select provider...
            VStack(alignment: .leading, spacing: 12) {
                Text(NSLocalizedString("browse_provider", comment: "Source"))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                    ForEach(WallpaperProvider.allCases, id: \.self) { provider in
                        providerToggle(provider: provider)
                    }
                }
            }
            
            VStack(alignment: .leading, spacing: 12) {
                Text(NSLocalizedString("browse_category", comment: "Category"))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                
                Picker("", selection: $chosen_categ) {
                    ForEach(WHCategory.allCases, id: \.self) { category in
                        Text(category.displayName).tag(category)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            
            VStack(alignment: .leading, spacing: 12) {
                Text(NSLocalizedString("browse_purity", comment: "Purity"))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                
                Picker("", selection: $chosen_purity) {
                    ForEach(WHPurityStatus.allCases, id: \.self) { purity in
                        Text(purity.displayName).tag(purity)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            
            VStack(alignment: .leading, spacing: 12) {
                Text(NSLocalizedString("browse_resolution", comment: "Resolution"))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                
                Picker("", selection: $selectedResolution) {
                    ForEach(ResolutionFilter.allCases, id: \.self) { resolution in
                        Text(resolution.displayName).tag(resolution)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            
            VStack(alignment: .leading, spacing: 12) {
                Text(NSLocalizedString("browse_sort", comment: "Sort by"))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                
                Picker("", selection: $chosen_sorting) {
                    ForEach(WHSort.allCases, id: \.self) { sorting in
                        Text(sorting.displayName).tag(sorting)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                
                Picker("", selection: $chosen_order) {
                    Text(NSLocalizedString("browse_desc", comment: "Descending")).tag(WHOrder.desc)
                    Text(NSLocalizedString("browse_asc", comment: "Ascending")).tag(WHOrder.asc)
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            
            Button(action: {
                activeResolutionFilter = selectedResolution
                currentPage = 1
                loadWallpapers()
                showFilters = false
            }) {
                Text(NSLocalizedString("browse_apply", comment: "Apply Filters"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.borderedProminent)
        }
    }
    
    private func providerToggle(provider: WallpaperProvider) -> some View {
        Toggle(isOn: Binding(
            get: { chosen_prov.contains(provider) },
            set: { isSelected in
                if isSelected {
                    chosen_prov.insert(provider)
                } else {
                    chosen_prov.remove(provider)
                }
            }
        )) {
            HStack(spacing: 6) {
                Image(systemName: provider.icon)
                    .font(.system(size: 11))
                Text(provider.displayName)
                    .font(.system(size: 11, weight: .medium))
            }
        }
        .toggleStyle(CBToggle())
        .disabled(provider != .wallhaven)
    }
    
    private var contentView: some View {
        ScrollView {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 20), count: 3), spacing: 20) {
                ForEach(filteredWallpapers) { wallpaper in
                    WHWallpaperCard(wallpaper: wallpaper)
                        .onAppear {
                            if wallpaper.id == filteredWallpapers.last?.id {
                                loadNextPage()
                            }
                        }
                }
            }
            .padding(24)
        }
    }
    
    private var filteredWallpapers: [WHWallpaper] {
        return WHServ.wallpapers.filter { wallpaper in
            activeResolutionFilter.matches(width: wallpaper.dimension_x, height: wallpaper.dimension_y)
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.2)
            Text(NSLocalizedString("browse_loading", comment: "Loading wallpapers..."))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "photo.on.rectangle")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            Text(NSLocalizedString("browse_no_results", comment: "No wallpapers found"))
                .font(.system(size: 16, weight: .medium))
            Text(NSLocalizedString("browse_try_search", comment: "Try adjusting your search or filters"))
                .font(.system(size: 14))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func loadWallpapers() {
        isLoading = true
        WHServ.searchWallpapers(
            query: searchQuery.isEmpty ? nil : searchQuery,
            sorting: chosen_sorting,
            order: chosen_order,
            purity: chosen_purity,
            category: chosen_categ,
            page: currentPage
        ) {
            isLoading = false
        }
    }
    
    private func loadNextPage() {
        currentPage += 1
        WHServ.loadMoreWallpapers(
            query: searchQuery.isEmpty ? nil : searchQuery,
            sorting: chosen_sorting,
            order: chosen_order,
            purity: chosen_purity,
            category: chosen_categ,
            page: currentPage
        )
    }
}

struct CBToggle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
            Spacer()
            Image(systemName: configuration.isOn ? "checkmark.square.fill" : "square")
                .foregroundColor(configuration.isOn ? .blue : .secondary)
                .onTapGesture { configuration.isOn.toggle() }
        }
    }
}

struct WHWallpaperCard: View {
    let wallpaper: WHWallpaper
    @State private var image: NSImage?
    @State private var isLoading = true
    @State private var isHovered = false
    @State private var downloadProgress: Double = 0
    @State private var isDownloading = false
    @State private var downloadTask: URLSessionDownloadTask?
    @State private var imageTask: URLSessionDataTask?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack {
                if let image = image {
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 200)
                        .clipped()
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 200)
                    
                    if isLoading {
                        ProgressView()
                    }
                }
                
                if isHovered {
                    VStack {
                        HStack {
                            Spacer()
                            downloadButton
                        }
                        Spacer()
                    }
                    .padding(8)
                }
                
                // tag:WORK
                // buggy
                if isDownloading {
                    ZStack {
                        Circle()
                            .stroke(Color.gray.opacity(0.3), lineWidth: 3)
                        
                        Circle()
                            .trim(from: 0, to: downloadProgress)
                            .stroke(Color.blue, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                            .animation(.easeInOut(duration: 0.3), value: downloadProgress)
                    }
                    .frame(width: 30, height: 30)
                }
            }
            .frame(height: 200)
            .cornerRadius(12)
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.2)) {
                    isHovered = hovering
                }
            }
            
            Text(wallpaper.id)
                .font(.system(size: 12, weight: .medium))
                .lineLimit(1)
            
            Text("\(wallpaper.dimension_x)x\(wallpaper.dimension_y)")
                .font(.system(size: 10))
                .foregroundColor(.secondary)
        }
        .onAppear {
            loadImage()
        }
        .onDisappear {
            downloadTask?.cancel()
            imageTask?.cancel()
        }
    }
    
    private var downloadButton: some View {
        Button(action: {
            downloadWallpaper()
        }) {
            Image(systemName: isDownloading ? "checkmark" : "arrow.down.circle.fill")
                .font(.system(size: 20))
                .foregroundColor(isDownloading ? .green : .white)
                .padding(8)
                .background(Circle().fill(Color.black.opacity(0.6)))
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isDownloading)
    }
    
    private func loadImage() {
        guard let url = URL(string: wallpaper.thumbs.large) else {
            isLoading = false
            return
        }
        
        let cacheKey = url.absoluteString as NSString
        if let cachedImage = ThumbnailCache.shared.getImage(forKey: cacheKey as String) {
            self.image = cachedImage
            self.isLoading = false
            return
        }
        
        imageTask = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("image load error: \(error)")
                DispatchQueue.main.async {
                    self.isLoading = false
                }
                return
            }
            
            guard let data = data, let nsImage = NSImage(data: data) else {
                DispatchQueue.main.async {
                    self.isLoading = false
                }
                return
            }
            
            ThumbnailCache.shared.setImage(nsImage, forKey: cacheKey as String)
            
            DispatchQueue.main.async {
                self.image = nsImage
                self.isLoading = false
            }
        }
        imageTask?.resume()
    }
    
    private func downloadWallpaper(retryCount: Int = 0) {
        isDownloading = true
        downloadProgress = 0
        
        guard let sourceURL = URL(string: wallpaper.path) else {
            isDownloading = false
            return
        }
        
        let home = FileManager.default.homeDirectoryForCurrentUser
        let wpStorageDir = home.appendingPathComponent(".local/share/paper/wallpaper")
        
        do {
            try FileManager.default.createDirectory(at: wpStorageDir, withIntermediateDirectories: true)
            
            let fileName = "wallhaven-\(wallpaper.id).\(sourceURL.pathExtension)"
            let destinationURL = wpStorageDir.appendingPathComponent(fileName)
            
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                withAnimation {
                    downloadProgress = 1.0
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.isDownloading = false
                }
                return
            }
            
            downloadTask = URLSession.shared.downloadTask(with: sourceURL) { tempURL, response, error in
                defer {
                    DispatchQueue.main.async {
                        self.isDownloading = false
                        self.downloadProgress = 0
                    }
                }
                
                if let error = error {
                    print("download error: \(error)")
                    if retryCount < 2 {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            self.downloadWallpaper(retryCount: retryCount + 1)
                        }
                    }
                    return
                }
                
                guard let tempURL = tempURL else {
                    print("download error: no temporary file")
                    if retryCount < 2 {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            self.downloadWallpaper(retryCount: retryCount + 1)
                        }
                    }
                    return
                }
                
                do {
                    try FileManager.default.moveItem(at: tempURL, to: destinationURL)
                    print("downloaded wallpaper to: \(destinationURL.path)")
                    
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(
                            name: NSNotification.Name("WallpaperDownloadCompleted"),
                            object: nil
                        )
                    }
                } catch {
                    print("while moving file: \(error)")
                }
            }
            
            _ = downloadTask?.progress.observe(\.fractionCompleted) { progress, _ in
                DispatchQueue.main.async {
                    self.downloadProgress = progress.fractionCompleted
                }
            }
            
            downloadTask?.resume()
            
        } catch {
            print("while creating directory: \(error)")
            isDownloading = false
            downloadProgress = 0
        }
    }
}

enum WallpaperProvider: String, CaseIterable {
    case wallhaven = "wallhaven"
    
    var displayName: String {
        switch self {
        case .wallhaven: return "Wallhaven"
        }
    }
    
    var icon: String {
        switch self {
        case .wallhaven: return "globe"
        }
    }
}

// WH service and blah blah
class WHService: ObservableObject {
    @Published var wallpapers: [WHWallpaper] = []
    private let baseURL = "https://wallhaven.cc/api/v1/search"
    private var currentSeed: String?
    
    func searchWallpapers(
        query: String? = nil,
        sorting: WHSort = .date_added,
        order: WHOrder = .desc,
        purity: WHPurityStatus = .sfw,
        category: WHCategory = .all,
        page: Int = 1,
        completion: (() -> Void)? = nil
    ) {
        var components = URLComponents(string: baseURL)!
        var queryItems: [URLQueryItem] = []
        
        if let query = query, !query.isEmpty {
            queryItems.append(URLQueryItem(name: "q", value: query))
        }
        
        queryItems.append(URLQueryItem(name: "sorting", value: sorting.rawValue))
        queryItems.append(URLQueryItem(name: "order", value: order.rawValue))
        queryItems.append(URLQueryItem(name: "purity", value: purity.rawValue))
        queryItems.append(URLQueryItem(name: "categories", value: category.rawValue))
        queryItems.append(URLQueryItem(name: "page", value: "\(page)"))
        
        if sorting == .random, let seed = currentSeed {
            queryItems.append(URLQueryItem(name: "seed", value: seed))
        }
        
        components.queryItems = queryItems
        
        guard let url = components.url else { return }
        
        URLSession.shared.dataTask(with: url) { data, _, error in
            defer { completion?() }
            
            if let error = error {
                print("while fetching wallpapers: \(error)")
                return
            }
            
            guard let data = data else { return }
            
            do {
                let response = try JSONDecoder().decode(WHResponse.self, from: data)
                DispatchQueue.main.async {
                    self.wallpapers = response.data
                    if let seed = response.meta.seed {
                        self.currentSeed = seed
                    }
                }
            } catch {
                print("while decoding response: \(error)")
            }
        }.resume()
    }
    
    func loadMoreWallpapers(
        query: String? = nil,
        sorting: WHSort = .date_added,
        order: WHOrder = .desc,
        purity: WHPurityStatus = .sfw,
        category: WHCategory = .all,
        page: Int
    ) {
        var components = URLComponents(string: baseURL)!
        var queryItems: [URLQueryItem] = []
        
        if let query = query, !query.isEmpty {
            queryItems.append(URLQueryItem(name: "q", value: query))
        }
        
        queryItems.append(URLQueryItem(name: "sorting", value: sorting.rawValue))
        queryItems.append(URLQueryItem(name: "order", value: order.rawValue))
        queryItems.append(URLQueryItem(name: "purity", value: purity.rawValue))
        queryItems.append(URLQueryItem(name: "categories", value: category.rawValue))
        queryItems.append(URLQueryItem(name: "page", value: "\(page)"))
        
        if sorting == .random, let seed = currentSeed {
            queryItems.append(URLQueryItem(name: "seed", value: seed))
        }
        
        components.queryItems = queryItems
        
        guard let url = components.url else { return }
        
        URLSession.shared.dataTask(with: url) { data, _, error in
            if let error = error {
                print("while getting more wallpapers: \(error)")
                return
            }
            
            guard let data = data else { return }
            
            do {
                let response = try JSONDecoder().decode(WHResponse.self, from: data)
                DispatchQueue.main.async {
                    self.wallpapers.append(contentsOf: response.data)
                    if let seed = response.meta.seed {
                        self.currentSeed = seed
                    }
                }
            } catch {
                print("while decoding response: \(error)")
            }
        }.resume()
    }
}

struct WHResponse: Codable {
    let data: [WHWallpaper]
    let meta: WHMeta
}

struct WHWallpaper: Codable, Identifiable {
    let id: String
    let url: String
    let short_url: String
    let views: Int
    let favorites: Int
    let source: String
    let purity: String
    let category: String
    let dimension_x: Int
    let dimension_y: Int
    let resolution: String
    let ratio: String
    let file_size: Int
    let file_type: String
    let created_at: String
    let colors: [String]
    let path: String
    let thumbs: WHThumbs
}

struct WHThumbs: Codable {
    let large: String
    let original: String
    let small: String
}

struct WHMeta: Codable {
    let current_page: Int
    let last_page: Int
    let per_page: Int
    let total: Int
    let query: String?
    let seed: String?
}

enum WHSort: String, CaseIterable {
    case date_added = "date_added"
    case relevance = "relevance"
    case random = "random"
    case views = "views"
    case favorites = "favorites"
    case toplist = "toplist"
    
    var displayName: String {
        switch self {
        case .date_added: return NSLocalizedString("sort_date", comment: "Date Added")
        case .relevance: return NSLocalizedString("sort_relevance", comment: "Relevance")
        case .random: return NSLocalizedString("sort_random", comment: "Random")
        case .views: return NSLocalizedString("sort_views", comment: "Views")
        case .favorites: return NSLocalizedString("sort_favorites", comment: "Favorites")
        case .toplist: return NSLocalizedString("sort_top", comment: "Toplist")
        }
    }
}

enum WHOrder: String {
    case desc = "desc"
    case asc = "asc"
}

enum WHPurityStatus: String, CaseIterable {
    case sfw = "100"
    
    var displayName: String {
        switch self {
        case .sfw: return "SFW"
        }
    }
}

enum WHCategory: String, CaseIterable {
    case general = "100"
    case anime = "010"
    case people = "001"
    case all = "111"
    
    var displayName: String {
        switch self {
        case .general: return NSLocalizedString("category_general", comment: "General")
        case .anime: return NSLocalizedString("category_anime", comment: "Anime")
        case .people: return NSLocalizedString("category_people", comment: "People")
        case .all: return NSLocalizedString("category_all", comment: "All")
        }
    }
}

class ThumbnailCache {
    static let shared = ThumbnailCache()
    private var cache = NSCache<NSString, NSImage>()
    
    private init() {
        cache.countLimit = 100
        cache.totalCostLimit = 100 * 1024 * 1024
    }
    
    func getImage(forKey key: String) -> NSImage? {
        return cache.object(forKey: key as NSString)
    }
    
    func setImage(_ image: NSImage, forKey key: String) {
        let cost = Int(image.size.width * image.size.height * 4)
        cache.setObject(image, forKey: key as NSString, cost: cost)
    }
}
