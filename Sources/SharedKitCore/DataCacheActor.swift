import Foundation

public actor DataCacheActor {
    public static let shared = DataCacheActor()
    
    private var cache: [String: CacheEntry] = [:]
    
    private struct CacheEntry: Sendable {
        let data: Data
        let timestamp: Date
        
        func isExpired(after interval: TimeInterval) -> Bool {
            Date().timeIntervalSince(timestamp) > interval
        }
    }
    
    public init() {}
    
    public func set(_ data: Data, forKey key: String) {
        cache[key] = CacheEntry(data: data, timestamp: Date())
        
        // Simple eviction
        if cache.count > 1000 {
            cleanExpired(interval: 3600) // 1 hour default
        }
    }
    
    public func get(forKey key: String, expirationInterval: TimeInterval = 3600) -> Data? {
        guard let entry = cache[key] else { return nil }
        if entry.isExpired(after: expirationInterval) {
            cache.removeValue(forKey: key)
            return nil
        }
        return entry.data
    }
    
    public func cleanExpired(interval: TimeInterval = 3600) {
        cache = cache.filter { !$0.value.isExpired(after: interval) }
    }
    
    public func clear() {
        cache.removeAll()
    }
}
