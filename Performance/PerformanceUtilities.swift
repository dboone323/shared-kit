import Foundation
import SwiftUI

// MARK: - Performance Optimization Utilities

// Additional utilities and helpers for performance optimization across projects

// MARK: - Performance Profiler

public class PerformanceProfiler {
    public static let shared = PerformanceProfiler()
    
    private var measurements: [String: [TimeInterval]] = [:]
    private let queue = DispatchQueue(label: "performance.profiler", attributes: .concurrent)
    
    private init() {}
    
    // MARK: - Time Measurement

    public func startMeasuring(_ operation: String) -> UUID {
        let id = UUID()
        let startTime = CFAbsoluteTimeGetCurrent()
        
        self.queue.async(flags: .barrier) {
            self.measurements["\(operation)_\(id.uuidString)_start"] = [startTime]
        }
        
        return id
    }
    
    public func endMeasuring(_ operation: String, id: UUID) -> TimeInterval? {
        let endTime = CFAbsoluteTimeGetCurrent()
        let key = "\(operation)_\(id.uuidString)_start"
        
        return self.queue.sync {
            guard let startTimes = measurements[key],
                  let startTime = startTimes.first else {
                return nil
            }
            
            let duration = endTime - startTime
            self.measurements.removeValue(forKey: key)
            
            // Store measurement history
            if self.measurements[operation] == nil {
                self.measurements[operation] = []
            }
            self.measurements[operation]?.append(duration)
            
            // Keep only last 100 measurements
            if self.measurements[operation]!.count > 100 {
                self.measurements[operation]?.removeFirst(self.measurements[operation]!.count - 100)
            }
            
            return duration
        }
    }
    
    public func measureOperation<T>(
        _ operation: String,
        block: () throws -> T
    ) rethrows -> (result: T, duration: TimeInterval) {
        let startTime = CFAbsoluteTimeGetCurrent()
        let result = try block()
        let endTime = CFAbsoluteTimeGetCurrent()
        let duration = endTime - startTime
        
        self.queue.async(flags: .barrier) {
            if self.measurements[operation] == nil {
                self.measurements[operation] = []
            }
            self.measurements[operation]?.append(duration)
            
            // Keep only last 100 measurements
            if self.measurements[operation]!.count > 100 {
                self.measurements[operation]?.removeFirst(self.measurements[operation]!.count - 100)
            }
        }
        
        return (result, duration)
    }
    
    public func measureAsyncOperation<T>(
        _ operation: String,
        block: () async throws -> T
    ) async rethrows -> (result: T, duration: TimeInterval) {
        let startTime = CFAbsoluteTimeGetCurrent()
        let result = try await block()
        let endTime = CFAbsoluteTimeGetCurrent()
        let duration = endTime - startTime
        
        self.queue.async(flags: .barrier) {
            if self.measurements[operation] == nil {
                self.measurements[operation] = []
            }
            self.measurements[operation]?.append(duration)
            
            // Keep only last 100 measurements
            if self.measurements[operation]!.count > 100 {
                self.measurements[operation]?.removeFirst(self.measurements[operation]!.count - 100)
            }
        }
        
        return (result, duration)
    }
    
    // MARK: - Performance Analytics

    public func getAverageTime(for operation: String) -> TimeInterval? {
        self.queue.sync {
            guard let times = measurements[operation], !times.isEmpty else {
                return nil
            }
            return times.reduce(0, +) / Double(times.count)
        }
    }
    
    public func getMedianTime(for operation: String) -> TimeInterval? {
        self.queue.sync {
            guard let times = measurements[operation], !times.isEmpty else {
                return nil
            }
            let sorted = times.sorted()
            let mid = sorted.count / 2
            if sorted.count % 2 == 0 {
                return (sorted[mid - 1] + sorted[mid]) / 2
            } else {
                return sorted[mid]
            }
        }
    }
    
    public func getPercentile(_ percentile: Double, for operation: String) -> TimeInterval? {
        guard percentile >= 0, percentile <= 100 else { return nil }
        
        return self.queue.sync {
            guard let times = measurements[operation], !times.isEmpty else {
                return nil
            }
            let sorted = times.sorted()
            let index = Int((percentile / 100.0) * Double(sorted.count - 1))
            return sorted[index]
        }
    }
    
    public func getAllMeasurements() -> [String: [TimeInterval]] {
        self.queue.sync {
            self.measurements
        }
    }
    
    public func clearMeasurements(for operation: String? = nil) {
        self.queue.async(flags: .barrier) {
            if let operation {
                self.measurements.removeValue(forKey: operation)
            } else {
                self.measurements.removeAll()
            }
        }
    }
}

// MARK: - SwiftUI Performance Helpers

public extension View {
    func measureRenderTime(_ label: String) -> some View {
        self.onAppear {
            let startTime = CFAbsoluteTimeGetCurrent()
            DispatchQueue.main.async {
                let renderTime = CFAbsoluteTimeGetCurrent() - startTime
                print("[\(label)] Render time: \(renderTime * 1000)ms")
            }
        }
    }
    
    func optimizeForBattery() -> some View {
        self.drawingGroup(opaque: BatteryOptimizer.shared.currentMode != .normal)
    }
    
    func conditionalAnimation(
        _ value: some Equatable,
        animation: Animation? = .default
    ) -> some View {
        let shouldAnimate = PerformanceMonitor.shared.currentMetrics.performanceLevel != .poor
        return self.animation(shouldAnimate ? animation : nil, value: value)
    }
    
    func performanceAware() -> some View {
        self.modifier(PerformanceAwareModifier())
    }
}

// MARK: - Performance Aware View Modifier

private struct PerformanceAwareModifier: ViewModifier {
    @StateObject private var performanceMonitor = PerformanceMonitor.shared
    
    func body(content: Content) -> some View {
        content
            .opacity(self.performanceMonitor.currentMetrics.thermalState.shouldThrottle ? 0.8 : 1.0)
            .animation(
                self.performanceMonitor.currentMetrics.performanceLevel == .poor ? nil : .easeInOut,
                value: self.performanceMonitor.currentMetrics.thermalState
            )
    }
}

// MARK: - Image Optimization Utilities

public enum ImageOptimizer {
    public static func optimizeForNetwork(_ image: UIImage) -> UIImage? {
        #if canImport(UIKit)
        let networkMonitor = NetworkMonitor.shared
        let quality = networkMonitor.recommendedImageQuality()
        
        guard let data = image.jpegData(compressionQuality: quality.compressionQuality),
              let optimizedImage = UIImage(data: data) else {
            return image
        }
        
        return optimizedImage
        #else
        return nil
        #endif
    }
    
    public static func resizeForPerformance(_ image: UIImage, targetSize: CGSize) -> UIImage? {
        #if canImport(UIKit)
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
        #else
        return nil
        #endif
    }
    
    public static func shouldDownsample(imageSize: CGSize, targetSize: CGSize) -> Bool {
        let sizeRatio = max(imageSize.width / targetSize.width, imageSize.height / targetSize.height)
        return sizeRatio > 2.0 // Downsample if image is more than 2x target size
    }
}

// MARK: - Data Optimization Utilities

public enum DataOptimizer {
    public static func compressJSON(_ object: some Codable) throws -> Data {
        let encoder = JSONEncoder()
        
        // Optimize encoding based on network conditions
        let networkMonitor = NetworkMonitor.shared
        if networkMonitor.shouldCompressData() {
            encoder.outputFormatting = [] // Compact format
        } else {
            encoder.outputFormatting = [.prettyPrinted] // Readable format for debugging
        }
        
        let data = try encoder.encode(object)
        
        // Apply compression if beneficial
        if data.count > 1024, networkMonitor.shouldCompressData() {
            return try data.compressed()
        }
        
        return data
    }
    
    public static func optimizedCacheKey(for url: URL) -> String {
        // Create optimized cache keys that include quality parameters
        let networkMonitor = NetworkMonitor.shared
        let quality = networkMonitor.recommendedImageQuality()
        return "\(url.absoluteString)_\(quality.rawValue)"
    }
}

// MARK: - Animation Performance Helpers

public struct PerformantAnimationModifier: ViewModifier {
    let animation: Animation
    let condition: () -> Bool
    
    public init(animation: Animation, when condition: @escaping () -> Bool = { true }) {
        self.animation = animation
        self.condition = condition
    }
    
    public func body(content: Content) -> some View {
        let performanceLevel = PerformanceMonitor.shared.currentMetrics.performanceLevel
        let shouldAnimate = self.condition() && performanceLevel != .poor
        
        return content
            .animation(shouldAnimate ? self.animation : nil, value: shouldAnimate)
    }
}

public extension Animation {
    static var performanceOptimized: Animation {
        let performanceLevel = PerformanceMonitor.shared.currentMetrics.performanceLevel
        
        switch performanceLevel {
        case .excellent:
            return .spring(response: 0.5, dampingFraction: 0.8)
        case .good:
            return .easeInOut(duration: 0.3)
        case .fair:
            return .easeInOut(duration: 0.2)
        case .poor:
            return .easeInOut(duration: 0.1)
        }
    }
}

// MARK: - Performance Testing Utilities

public class PerformanceTest {
    public let name: String
    public let iterations: Int
    public private(set) var results: [TimeInterval] = []
    
    public init(name: String, iterations: Int = 100) {
        self.name = name
        self.iterations = iterations
    }
    
    public func run(operation: () throws -> Void) rethrows -> PerformanceTestResult {
        self.results.removeAll()
        
        for _ in 0 ..< self.iterations {
            let startTime = CFAbsoluteTimeGetCurrent()
            try operation()
            let endTime = CFAbsoluteTimeGetCurrent()
            self.results.append(endTime - startTime)
        }
        
        return PerformanceTestResult(
            name: self.name,
            iterations: self.iterations,
            times: self.results
        )
    }
    
    public func runAsync(operation: () async throws -> Void) async rethrows -> PerformanceTestResult {
        self.results.removeAll()
        
        for _ in 0 ..< self.iterations {
            let startTime = CFAbsoluteTimeGetCurrent()
            try await operation()
            let endTime = CFAbsoluteTimeGetCurrent()
            self.results.append(endTime - startTime)
        }
        
        return PerformanceTestResult(
            name: self.name,
            iterations: self.iterations,
            times: self.results
        )
    }
}

public struct PerformanceTestResult {
    public let name: String
    public let iterations: Int
    public let times: [TimeInterval]
    
    public var averageTime: TimeInterval {
        self.times.reduce(0, +) / Double(self.times.count)
    }
    
    public var medianTime: TimeInterval {
        let sorted = self.times.sorted()
        let mid = sorted.count / 2
        if sorted.count % 2 == 0 {
            return (sorted[mid - 1] + sorted[mid]) / 2
        } else {
            return sorted[mid]
        }
    }
    
    public var minTime: TimeInterval {
        self.times.min() ?? 0
    }
    
    public var maxTime: TimeInterval {
        self.times.max() ?? 0
    }
    
    public func percentile(_ p: Double) -> TimeInterval? {
        guard p >= 0, p <= 100 else { return nil }
        let sorted = self.times.sorted()
        let index = Int((p / 100.0) * Double(sorted.count - 1))
        return sorted[index]
    }
    
    public var summary: String {
        """
        Performance Test: \(self.name)
        Iterations: \(self.iterations)
        Average: \(String(format: "%.3f", self.averageTime * 1000))ms
        Median: \(String(format: "%.3f", self.medianTime * 1000))ms
        Min: \(String(format: "%.3f", self.minTime * 1000))ms
        Max: \(String(format: "%.3f", self.maxTime * 1000))ms
        95th percentile: \(String(format: "%.3f", (self.percentile(95) ?? 0) * 1000))ms
        """
    }
}

// MARK: - Background Task Manager

public class BackgroundTaskManager: ObservableObject {
    public static let shared = BackgroundTaskManager()
    
    @Published public var activeTasks: Set<String> = []
    @Published public var taskResults: [String: TaskResult] = [:]
    
    private var tasks: [String: Task<Void, Never>] = [:]
    private let queue = DispatchQueue(label: "background.tasks", attributes: .concurrent)
    
    private init() {}
    
    public func scheduleTask<T>(
        _ identifier: String,
        priority: TaskPriority = .background,
        operation: @escaping () async throws -> T,
        completion: @escaping (Result<T, Error>) -> Void = { _ in }
    ) {
        // Cancel existing task with same identifier
        self.cancelTask(identifier)
        
        let task = Task(priority: priority) {
            await MainActor.run {
                self.activeTasks.insert(identifier)
            }
            
            let startTime = CFAbsoluteTimeGetCurrent()
            
            do {
                let result = try await operation()
                let duration = CFAbsoluteTimeGetCurrent() - startTime
                
                await MainActor.run {
                    self.taskResults[identifier] = TaskResult(
                        identifier: identifier,
                        duration: duration,
                        success: true,
                        completedAt: Date()
                    )
                    self.activeTasks.remove(identifier)
                }
                
                completion(.success(result))
            } catch {
                let duration = CFAbsoluteTimeGetCurrent() - startTime
                
                await MainActor.run {
                    self.taskResults[identifier] = TaskResult(
                        identifier: identifier,
                        duration: duration,
                        success: false,
                        completedAt: Date(),
                        error: error.localizedDescription
                    )
                    self.activeTasks.remove(identifier)
                }
                
                completion(.failure(error))
            }
        }
        
        self.queue.async(flags: .barrier) {
            self.tasks[identifier] = task
        }
    }
    
    public func cancelTask(_ identifier: String) {
        self.queue.async(flags: .barrier) {
            self.tasks[identifier]?.cancel()
            self.tasks.removeValue(forKey: identifier)
        }
        
        Task { @MainActor in
            self.activeTasks.remove(identifier)
        }
    }
    
    public func cancelAllTasks() {
        self.queue.async(flags: .barrier) {
            self.tasks.values.forEach { $0.cancel() }
            self.tasks.removeAll()
        }
        
        Task { @MainActor in
            self.activeTasks.removeAll()
        }
    }
    
    public func isTaskActive(_ identifier: String) -> Bool {
        self.activeTasks.contains(identifier)
    }
    
    public func getTaskResult(_ identifier: String) -> TaskResult? {
        self.taskResults[identifier]
    }
    
    // MARK: - Performance Optimized Task Scheduling

    public func scheduleOptimizedTask<T>(
        _ identifier: String,
        operation: @escaping () async throws -> T,
        completion: @escaping (Result<T, Error>) -> Void = { _ in }
    ) {
        let cpuOptimizer = CPUOptimizer.shared
        let batteryOptimizer = BatteryOptimizer.shared
        
        // Determine optimal priority based on system state
        let priority: TaskPriority = if batteryOptimizer.currentMode == .critical {
            .background
        } else if cpuOptimizer.shouldDeferNonCriticalWork() {
            .utility
        } else {
            .medium
        }
        
        self.scheduleTask(identifier, priority: priority, operation: operation, completion: completion)
    }
}

public struct TaskResult {
    public let identifier: String
    public let duration: TimeInterval
    public let success: Bool
    public let completedAt: Date
    public let error: String?
    
    public init(identifier: String, duration: TimeInterval, success: Bool, completedAt: Date, error: String? = nil) {
        self.identifier = identifier
        self.duration = duration
        self.success = success
        self.completedAt = completedAt
        self.error = error
    }
}

// MARK: - Data Extensions for Performance

extension Data {
    func compressed() throws -> Data {
        try (self as NSData).compressed(using: .lzfse) as Data
    }
    
    func decompressed() throws -> Data {
        try (self as NSData).decompressed(using: .lzfse) as Data
    }
}

// MARK: - UserDefaults Performance Optimization

public extension UserDefaults {
    func setOptimized(_ object: some Codable, forKey key: String) throws {
        let data = try DataOptimizer.compressJSON(object)
        set(data, forKey: key)
    }
    
    func getOptimized<T: Codable>(_ type: T.Type, forKey key: String) throws -> T? {
        guard let data = data(forKey: key) else { return nil }
        
        let decoder = JSONDecoder()
        
        // Try decompression first
        do {
            let decompressed = try data.decompressed()
            return try decoder.decode(type, from: decompressed)
        } catch {
            // Fall back to direct decoding
            return try decoder.decode(type, from: data)
        }
    }
}
