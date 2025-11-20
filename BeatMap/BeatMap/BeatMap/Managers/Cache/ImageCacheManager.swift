// MARK: - File Header
//
// ImageCacheManager.swift
// BeatMap
//
// Version: 1.0.0
// Created: November 2025
//
// Property of A. Wheildon
// All rights reserved.
//
// MARK: - End File Header

import SwiftUI
import Combine

/// High-performance image caching system for BeatMap.
/// Caches album artwork in memory and on disk to minimize network requests.
class ImageCacheManager {
    
    static let shared = ImageCacheManager()
    
    // In-memory cache (fast)
    private let memoryCache = NSCache<NSString, UIImage>()
    
    // Disk cache directory
    private let diskCacheDirectory: URL
    
    // Currently loading URLs to prevent duplicate requests
    private var loadingURLs = Set<URL>()
    private let loadingQueue = DispatchQueue(label: "com.beatmap.imageloading")
    
    private init() {
        // Configure memory cache
        memoryCache.countLimit = 100 // Store up to 100 images
        memoryCache.totalCostLimit = 50 * 1024 * 1024 // 50 MB limit
        
        // Setup disk cache
        let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        diskCacheDirectory = cacheDir.appendingPathComponent("ImageCache", isDirectory: true)
        
        try? FileManager.default.createDirectory(at: diskCacheDirectory, withIntermediateDirectories: true)
        
        print("✅ ImageCacheManager initialized")
    }
    
    // MARK: - Public Methods
    
    /// Retrieve image from cache or download if needed
    func loadImage(from urlString: String) async -> UIImage? {
        guard let url = URL(string: urlString) else { return nil }
        
        let cacheKey = cacheKeyForURL(url)
        
        // 1. Check memory cache (fastest)
        if let cachedImage = memoryCache.object(forKey: cacheKey as NSString) {
            return cachedImage
        }
        
        // 2. Check disk cache
        if let diskImage = loadFromDisk(cacheKey: cacheKey) {
            // Store in memory for next time
            memoryCache.setObject(diskImage, forKey: cacheKey as NSString)
            return diskImage
        }
        
        // 3. Download from network
        return await downloadImage(from: url, cacheKey: cacheKey)
    }
    
    /// Preload images in background
    func preloadImages(urls: [String]) {
        Task.detached(priority: .background) {
            for urlString in urls {
                _ = await self.loadImage(from: urlString)
            }
        }
    }
    
    /// Clear all cached images
    func clearCache() {
        memoryCache.removeAllObjects()
        try? FileManager.default.removeItem(at: diskCacheDirectory)
        try? FileManager.default.createDirectory(at: diskCacheDirectory, withIntermediateDirectories: true)
        print("🗑️ Image cache cleared")
    }
    
    /// Get cache size in MB
    func getCacheSize() -> Double {
        guard let enumerator = FileManager.default.enumerator(at: diskCacheDirectory, includingPropertiesForKeys: [.fileSizeKey]) else {
            return 0
        }
        
        var totalSize: Int64 = 0
        for case let fileURL as URL in enumerator {
            if let fileSize = try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                totalSize += Int64(fileSize)
            }
        }
        
        return Double(totalSize) / 1_000_000.0 // Convert to MB
    }
    
    // MARK: - Private Methods
    
    private func downloadImage(from url: URL, cacheKey: String) async -> UIImage? {
        // Check if already downloading
        let isAlreadyLoading = await loadingQueue.sync {
            let isLoading = loadingURLs.contains(url)
            if !isLoading {
                loadingURLs.insert(url)
            }
            return isLoading
        }
        
        if isAlreadyLoading {
            // Wait a bit and check cache again
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            return memoryCache.object(forKey: cacheKey as NSString)
        }
        
        defer {
            loadingQueue.async {
                self.loadingURLs.remove(url)
            }
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            
            guard let image = UIImage(data: data) else {
                print("⚠️ Failed to decode image from: \(url.lastPathComponent)")
                return nil
            }
            
            // Compress image for better memory usage
            let compressedImage = compressImage(image)
            
            // Cache in memory
            memoryCache.setObject(compressedImage, forKey: cacheKey as NSString)
            
            // Cache on disk
            saveToDisk(image: compressedImage, cacheKey: cacheKey)
            
            return compressedImage
            
        } catch {
            print("❌ Failed to download image: \(error.localizedDescription)")
            return nil
        }
    }
    
    private func compressImage(_ image: UIImage) -> UIImage {
        // Resize if too large
        let maxDimension: CGFloat = 400
        let size = image.size
        
        if size.width <= maxDimension && size.height <= maxDimension {
            return image
        }
        
        let scale = min(maxDimension / size.width, maxDimension / size.height)
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return resizedImage ?? image
    }
    
    private func saveToDisk(image: UIImage, cacheKey: String) {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return }
        
        let fileURL = diskCacheDirectory.appendingPathComponent(cacheKey)
        try? data.write(to: fileURL)
    }
    
    private func loadFromDisk(cacheKey: String) -> UIImage? {
        let fileURL = diskCacheDirectory.appendingPathComponent(cacheKey)
        guard let data = try? Data(contentsOf: fileURL),
              let image = UIImage(data: data) else {
            return nil
        }
        return image
    }
    
    private func cacheKeyForURL(_ url: URL) -> String {
        // Use URL hash as filename
        let urlString = url.absoluteString
        return String(urlString.hashValue)
    }
}

// MARK: - SwiftUI View Extension

extension View {
    /// Cached async image loader
    func cachedAsyncImage(url: String?, placeholder: Image = Image(systemName: "music.note")) -> some View {
        CachedAsyncImageView(urlString: url, placeholder: placeholder)
    }
}

struct CachedAsyncImageView: View {
    let urlString: String?
    let placeholder: Image
    
    @State private var loadedImage: UIImage?
    @State private var isLoading = false
    
    var body: some View {
        Group {
            if let image = loadedImage {
                Image(uiImage: image)
                    .resizable()
            } else if isLoading {
                ZStack {
                    Color.gray.opacity(0.2)
                    ProgressView()
                }
            } else {
                placeholder
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(.gray)
            }
        }
        .task {
            await loadImage()
        }
    }
    
    private func loadImage() async {
        guard let urlString = urlString else { return }
        
        isLoading = true
        loadedImage = await ImageCacheManager.shared.loadImage(from: urlString)
        isLoading = false
    }
}
