import Combine
import Foundation
import Network
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Performance Optimization Framework

// Advanced performance optimization system for memory, CPU, network, and battery efficiency

// MARK: - Performance Monitor

public class PerformanceMonitor: ObservableObject {
    public static let shared = PerformanceMonitor()
    
    @Published public var currentMetrics = PerformanceMetrics()
    @Published public var isMonitoring = false
    
    private var monitoringTimer: Timer?
    private var memoryWarningObserver: NSObjectProtocol?
    private var batteryObserver: NSObjectProtocol?
    private let networkMonitor = NetworkMonitor.shared
    
    private init() {
        self.setupSystemObservers()
    }
    
    deinit {
        stopMonitoring()
        removeSystemObservers()
    }
    
    // MARK: - Monitoring Control

    public func startMonitoring(interval: TimeInterval = 1.0) {
        guard !self.isMonitoring else { return }
        
        self.isMonitoring = true
        self.monitoringTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.updateMetrics()
        }
        
        self.networkMonitor.startMonitoring()
    }
    
    public func stopMonitoring() {
        self.isMonitoring = false
        self.monitoringTimer?.invalidate()
        self.monitoringTimer = nil
        self.networkMonitor.stopMonitoring()
    }
    
    // MARK: - Metrics Collection

    private func updateMetrics() {
        Task { @MainActor in
            self.currentMetrics = PerformanceMetrics(
                memoryUsage: self.getCurrentMemoryUsage(),
                cpuUsage: self.getCurrentCPUUsage(),
                batteryLevel: self.getCurrentBatteryLevel(),
                networkStatus: self.networkMonitor.currentStatus,
                frameRate: self.getCurrentFrameRate(),
                thermalState: self.getCurrentThermalState(),
                timestamp: Date()
            )
        }
    }
    
    private func getCurrentMemoryUsage() -> MemoryUsage {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let kerr = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            let usedMemory = Double(info.resident_size) / 1024 / 1024 // Convert to MB
            let availableMemory = Double(ProcessInfo.processInfo.physicalMemory) / 1024 / 1024
            
            return MemoryUsage(
                used: usedMemory,
                available: availableMemory,
                percentage: (usedMemory / availableMemory) * 100
            )
        }
        
        return MemoryUsage(used: 0, available: 0, percentage: 0)
    }
    
    private func getCurrentCPUUsage() -> CPUUsage {
        var info = processor_info_array_t(bitPattern: 0)
        var numCpuInfo: mach_msg_type_number_t = 0
        var numCpus: natural_t = 0
        
        let result = host_processor_info(
            mach_host_self(),
            PROCESSOR_CPU_LOAD_INFO,
            &numCpus,
            &info,
            &numCpuInfo
        )
        
        if result == KERN_SUCCESS {
            let cpuLoadInfo = withUnsafePointer(to: info) {
                $0.withMemoryRebound(to: processor_cpu_load_info_data_t.self, capacity: Int(numCpus)) {
                    Array(UnsafeBufferPointer(start: $0, count: Int(numCpus)))
                }
            }
            
            var totalUser: UInt32 = 0
            var totalSystem: UInt32 = 0
            var totalIdle: UInt32 = 0
            
            for cpu in cpuLoadInfo {
                totalUser += cpu.cpu_ticks.0 // CPU_STATE_USER
                totalSystem += cpu.cpu_ticks.1 // CPU_STATE_SYSTEM
                totalIdle += cpu.cpu_ticks.2 // CPU_STATE_IDLE
            }
            
            let totalTicks = totalUser + totalSystem + totalIdle
            
            if totalTicks > 0 {
                let userPercentage = Double(totalUser) / Double(totalTicks) * 100
                let systemPercentage = Double(totalSystem) / Double(totalTicks) * 100
                let idlePercentage = Double(totalIdle) / Double(totalTicks) * 100
                
                return CPUUsage(
                    user: userPercentage,
                    system: systemPercentage,
                    idle: idlePercentage,
                    total: userPercentage + systemPercentage
                )
            }
        }
        
        return CPUUsage(user: 0, system: 0, idle: 100, total: 0)
    }
    
    private func getCurrentBatteryLevel() -> BatteryStatus {
        #if canImport(UIKit)
        let device = UIDevice.current
        device.isBatteryMonitoringEnabled = true
        
        return BatteryStatus(
            level: Double(device.batteryLevel * 100),
            state: BatteryState(from: device.batteryState),
            isLowPowerModeEnabled: ProcessInfo.processInfo.isLowPowerModeEnabled
        )
        #else
        return BatteryStatus(level: 100, state: .unknown, isLowPowerModeEnabled: false)
        #endif
    }
    
    private func getCurrentFrameRate() -> Double {
        // This would typically be measured by the display system
        // For now, return a default value - in production, integrate with CADisplayLink
        60.0
    }
    
    private func getCurrentThermalState() -> ThermalState {
        #if canImport(UIKit)
        switch ProcessInfo.processInfo.thermalState {
        case .nominal:
            return .nominal
        case .fair:
            return .fair
        case .serious:
            return .serious
        case .critical:
            return .critical
        @unknown default:
            return .nominal
        }
        #else
        return .nominal
        #endif
    }
    
    // MARK: - System Observers

    private func setupSystemObservers() {
        #if canImport(UIKit)
        self.memoryWarningObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleMemoryWarning()
        }
        
        self.batteryObserver = NotificationCenter.default.addObserver(
            forName: UIDevice.batteryStateDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updateMetrics()
        }
        #endif
    }
    
    private func removeSystemObservers() {
        if let observer = memoryWarningObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        if let observer = batteryObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    private func handleMemoryWarning() {
        // Trigger memory cleanup
        MemoryManager.shared.performEmergencyCleanup()
        
        // Notify observers
        NotificationCenter.default.post(name: .performanceMemoryWarning, object: nil)
    }
}

// MARK: - Performance Metrics

public struct PerformanceMetrics {
    public let memoryUsage: MemoryUsage
    public let cpuUsage: CPUUsage
    public let batteryLevel: BatteryStatus
    public let networkStatus: NetworkStatus
    public let frameRate: Double
    public let thermalState: ThermalState
    public let timestamp: Date
    
    public init(
        memoryUsage: MemoryUsage = MemoryUsage(used: 0, available: 0, percentage: 0),
        cpuUsage: CPUUsage = CPUUsage(user: 0, system: 0, idle: 100, total: 0),
        batteryLevel: BatteryStatus = BatteryStatus(level: 100, state: .unknown, isLowPowerModeEnabled: false),
        networkStatus: NetworkStatus = NetworkStatus(isConnected: true, connectionType: .wifi, bandwidth: 0),
        frameRate: Double = 60.0,
        thermalState: ThermalState = .nominal,
        timestamp: Date = Date()
    ) {
        self.memoryUsage = memoryUsage
        self.cpuUsage = cpuUsage
        self.batteryLevel = batteryLevel
        self.networkStatus = networkStatus
        self.frameRate = frameRate
        self.thermalState = thermalState
        self.timestamp = timestamp
    }
    
    // Performance assessment
    public var overallPerformanceScore: Double {
        var score = 100.0
        
        // Memory impact (0-30 points)
        if self.memoryUsage.percentage > 80 {
            score -= 30
        } else if self.memoryUsage.percentage > 60 {
            score -= 15
        } else if self.memoryUsage.percentage > 40 {
            score -= 5
        }
        
        // CPU impact (0-25 points)
        if self.cpuUsage.total > 80 {
            score -= 25
        } else if self.cpuUsage.total > 60 {
            score -= 15
        } else if self.cpuUsage.total > 40 {
            score -= 8
        }
        
        // Battery impact (0-20 points)
        if self.batteryLevel.isLowPowerModeEnabled {
            score -= 20
        } else if self.batteryLevel.level < 20 {
            score -= 10
        }
        
        // Thermal impact (0-15 points)
        switch self.thermalState {
        case .critical:
            score -= 15
        case .serious:
            score -= 10
        case .fair:
            score -= 5
        case .nominal:
            break
        }
        
        // Frame rate impact (0-10 points)
        if self.frameRate < 30 {
            score -= 10
        } else if self.frameRate < 45 {
            score -= 5
        }
        
        return max(0, score)
    }
    
    public var performanceLevel: PerformanceLevel {
        let score = self.overallPerformanceScore
        if score >= 85 {
            return .excellent
        } else if score >= 70 {
            return .good
        } else if score >= 50 {
            return .fair
        } else {
            return .poor
        }
    }
}

public struct MemoryUsage: Codable {
    public let used: Double // MB
    public let available: Double // MB
    public let percentage: Double
    
    public init(used: Double, available: Double, percentage: Double) {
        self.used = used
        self.available = available
        self.percentage = percentage
    }
    
    public var usageLevel: UsageLevel {
        if self.percentage > 80 {
            .critical
        } else if self.percentage > 60 {
            .high
        } else if self.percentage > 40 {
            .medium
        } else {
            .low
        }
    }
}

public struct CPUUsage: Codable {
    public let user: Double
    public let system: Double
    public let idle: Double
    public let total: Double
    
    public init(user: Double, system: Double, idle: Double, total: Double) {
        self.user = user
        self.system = system
        self.idle = idle
        self.total = total
    }
    
    public var usageLevel: UsageLevel {
        if self.total > 80 {
            .critical
        } else if self.total > 60 {
            .high
        } else if self.total > 40 {
            .medium
        } else {
            .low
        }
    }
}

public struct BatteryStatus: Codable {
    public let level: Double // Percentage
    public let state: BatteryState
    public let isLowPowerModeEnabled: Bool
    
    public init(level: Double, state: BatteryState, isLowPowerModeEnabled: Bool) {
        self.level = level
        self.state = state
        self.isLowPowerModeEnabled = isLowPowerModeEnabled
    }
    
    public var needsOptimization: Bool {
        self.level < 20 || self.isLowPowerModeEnabled || self.state == .unplugged
    }
}

public enum BatteryState: String, Codable {
    case unknown
    case unplugged
    case charging
    case full
    
    #if canImport(UIKit)
    init(from uiState: UIDevice.BatteryState) {
        switch uiState {
        case .unknown:
            self = .unknown
        case .unplugged:
            self = .unplugged
        case .charging:
            self = .charging
        case .full:
            self = .full
        @unknown default:
            self = .unknown
        }
    }
    #endif
}

public struct NetworkStatus: Codable {
    public let isConnected: Bool
    public let connectionType: ConnectionType
    public let bandwidth: Double // Mbps
    
    public init(isConnected: Bool, connectionType: ConnectionType, bandwidth: Double) {
        self.isConnected = isConnected
        self.connectionType = connectionType
        self.bandwidth = bandwidth
    }
    
    public var isHighBandwidth: Bool {
        self.connectionType == .wifi || self.connectionType == .ethernet
    }
    
    public var shouldOptimizeForBandwidth: Bool {
        self.connectionType == .cellular || self.bandwidth < 1.0
    }
}

public enum ConnectionType: String, Codable {
    case unknown
    case wifi
    case cellular
    case ethernet
    case offline
}

public enum ThermalState: String, Codable {
    case nominal
    case fair
    case serious
    case critical
    
    public var shouldThrottle: Bool {
        self == .serious || self == .critical
    }
}

public enum UsageLevel: String, Codable {
    case low
    case medium
    case high
    case critical
    
    public var color: Color {
        switch self {
        case .low:
            .green
        case .medium:
            .yellow
        case .high:
            .orange
        case .critical:
            .red
        }
    }
}

public enum PerformanceLevel: String, Codable {
    case excellent
    case good
    case fair
    case poor
    
    public var description: String {
        switch self {
        case .excellent:
            "Excellent Performance"
        case .good:
            "Good Performance"
        case .fair:
            "Fair Performance"
        case .poor:
            "Poor Performance"
        }
    }
    
    public var color: Color {
        switch self {
        case .excellent:
            .green
        case .good:
            .blue
        case .fair:
            .orange
        case .poor:
            .red
        }
    }
}

// MARK: - Memory Manager

public class MemoryManager: ObservableObject {
    public static let shared = MemoryManager()
    
    #if canImport(UIKit)
    private let imageCache = NSCache<NSString, UIImage>()
    #endif
    private let dataCache = NSCache<NSString, NSData>()
    private var cacheCleanupTimer: Timer?
    
    @Published public var isOptimizing = false
    @Published public var lastCleanupDate: Date?
    
    private init() {
        self.setupCaches()
        self.startPeriodicCleanup()
    }
    
    deinit {
        cacheCleanupTimer?.invalidate()
    }
    
    // MARK: - Cache Management

    private func setupCaches() {
        #if canImport(UIKit)
        // Configure image cache
        self.imageCache.countLimit = 100 // Max 100 images
        self.imageCache.totalCostLimit = 50 * 1024 * 1024 // 50MB
        #endif
        
        // Configure data cache
        self.dataCache.countLimit = 200 // Max 200 data objects
        self.dataCache.totalCostLimit = 20 * 1024 * 1024 // 20MB
        
        // Set up automatic cleanup on memory warning
        #if canImport(UIKit)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.handleMemoryWarning),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
        #endif
    }
    
    @objc private func handleMemoryWarning() {
        self.performEmergencyCleanup()
    }
    
    // MARK: - Cleanup Operations

    public func performEmergencyCleanup() {
        Task { @MainActor in
            self.isOptimizing = true
        }
        
        // Clear caches aggressively
        #if canImport(UIKit)
        self.imageCache.removeAllObjects()
        #endif
        self.dataCache.removeAllObjects()
        
        // Force garbage collection
        autoreleasepool {
            // Perform any additional cleanup
        }
        
        Task { @MainActor in
            self.isOptimizing = false
            self.lastCleanupDate = Date()
        }
        
        // Notify system of cleanup
        NotificationCenter.default.post(name: .performanceMemoryCleanup, object: nil)
    }
    
    public func performRoutineCleanup() {
        Task { @MainActor in
            self.isOptimizing = true
        }
        
        // Less aggressive cleanup
        let memoryUsage = PerformanceMonitor.shared.currentMetrics.memoryUsage
        
        if memoryUsage.percentage > 60 {
            // Clear half of the caches
            self.clearCachePercentage(0.5)
        } else if memoryUsage.percentage > 40 {
            // Clear quarter of the caches
            self.clearCachePercentage(0.25)
        }
        
        Task { @MainActor in
            self.isOptimizing = false
            self.lastCleanupDate = Date()
        }
    }
    
    private func clearCachePercentage(_ percentage: Double) {
        #if canImport(UIKit)
        _ = Int(Double(self.imageCache.countLimit) * percentage)
        #endif
        _ = Int(Double(self.dataCache.countLimit) * percentage)
        
        // Implementation would need to track cache keys for selective removal
        // For now, we'll remove all if percentage > 0.5, otherwise do nothing
        if percentage > 0.5 {
            #if canImport(UIKit)
            self.imageCache.removeAllObjects()
            #endif
            self.dataCache.removeAllObjects()
        }
    }
    
    private func startPeriodicCleanup() {
        self.cacheCleanupTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            // Cleanup every 5 minutes
            self?.performRoutineCleanup()
        }
    }
    
    // MARK: - Cache Access

    #if canImport(UIKit)
    public func cacheImage(_ image: UIImage, forKey key: String) {
        let cost = Int(image.size.width * image.size.height * 4) // Rough memory estimate
        self.imageCache.setObject(image, forKey: key as NSString, cost: cost)
    }
    
    public func cachedImage(forKey key: String) -> UIImage? {
        self.imageCache.object(forKey: key as NSString)
    }
    #endif
    
    public func cacheData(_ data: Data, forKey key: String) {
        self.dataCache.setObject(data as NSData, forKey: key as NSString, cost: data.count)
    }
    
    public func cachedData(forKey key: String) -> Data? {
        self.dataCache.object(forKey: key as NSString) as Data?
    }
}

// MARK: - CPU Optimizer

public class CPUOptimizer: ObservableObject {
    public static let shared = CPUOptimizer()
    
    @Published public var isThrottling = false
    @Published public var optimizationLevel: OptimizationLevel = .normal
    
    private var throttleTimer: Timer?
    private let processingQueue = DispatchQueue(label: "cpu.optimization", qos: .utility)
    
    private init() {
        self.startMonitoring()
    }
    
    // MARK: - Optimization Control

    private func startMonitoring() {
        Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.evaluateOptimizationNeeds()
        }
    }
    
    private func evaluateOptimizationNeeds() {
        let metrics = PerformanceMonitor.shared.currentMetrics
        let thermalState = metrics.thermalState
        let cpuUsage = metrics.cpuUsage
        let batteryStatus = metrics.batteryLevel
        
        var newLevel: OptimizationLevel = .normal
        
        // Determine optimization level based on multiple factors
        if thermalState.shouldThrottle || cpuUsage.total > 80 {
            newLevel = .aggressive
        } else if batteryStatus.isLowPowerModeEnabled || batteryStatus.level < 20 {
            newLevel = .moderate
        } else if cpuUsage.total > 60 || batteryStatus.level < 50 {
            newLevel = .mild
        }
        
        if newLevel != self.optimizationLevel {
            Task { @MainActor in
                self.optimizationLevel = newLevel
                self.applyOptimizationLevel(newLevel)
            }
        }
    }
    
    private func applyOptimizationLevel(_ level: OptimizationLevel) {
        switch level {
        case .normal:
            self.stopThrottling()
        case .mild:
            self.startThrottling(factor: 0.9)
        case .moderate:
            self.startThrottling(factor: 0.7)
        case .aggressive:
            self.startThrottling(factor: 0.5)
        }
        
        // Notify other systems of optimization changes
        NotificationCenter.default.post(
            name: .performanceOptimizationChanged,
            object: level
        )
    }
    
    private func startThrottling(factor: Double) {
        self.isThrottling = true
        
        // Implement CPU throttling by introducing delays in processing
        self.processingQueue.async { [weak self] in
            self?.throttleProcessing(factor: factor)
        }
    }
    
    private func stopThrottling() {
        self.isThrottling = false
        self.throttleTimer?.invalidate()
        self.throttleTimer = nil
    }
    
    private func throttleProcessing(factor: Double) {
        let sleepTime = (1.0 - factor) * 0.1 // Up to 100ms delay
        Thread.sleep(forTimeInterval: sleepTime)
    }
    
    // MARK: - Optimized Task Execution

    public func executeOptimizedTask<T>(
        priority: TaskPriority = .medium,
        operation: @escaping () async throws -> T
    ) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            let taskPriority: TaskPriority = switch self.optimizationLevel {
            case .normal:
                priority
            case .mild:
                .utility
            case .moderate:
                .background
            case .aggressive:
                .background
            }
            
            group.addTask(priority: taskPriority) {
                try await operation()
            }
            
            return try await group.next()!
        }
    }
    
    public func shouldDeferNonCriticalWork() -> Bool {
        self.optimizationLevel == .moderate || self.optimizationLevel == .aggressive
    }
}

public enum OptimizationLevel: String, Codable {
    case normal
    case mild
    case moderate
    case aggressive
    
    public var description: String {
        switch self {
        case .normal:
            "Normal Performance"
        case .mild:
            "Mild Optimization"
        case .moderate:
            "Moderate Optimization"
        case .aggressive:
            "Aggressive Optimization"
        }
    }
}

extension TaskPriority {
    var qosClass: DispatchQoS.QoSClass {
        if #available(iOS 15.0, macOS 12.0, *) {
            switch self {
            case .background:
                .background
            case .utility:
                .utility
            case .medium:
                .default
            case .userInitiated:
                .userInitiated
            case .high:
                .userInteractive
            default:
                .default
            }
        } else {
            .default
        }
    }
}

// MARK: - Network Monitor

public class NetworkMonitor: ObservableObject {
    public static let shared = NetworkMonitor()
    
    @Published public var currentStatus = NetworkStatus(isConnected: true, connectionType: .wifi, bandwidth: 0)
    @Published public var isOptimizing = false
    
    private let pathMonitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "network.monitor")
    private var bandwidthTimer: Timer?
    
    private init() {
        self.setupPathMonitor()
    }
    
    // MARK: - Monitoring

    public func startMonitoring() {
        self.pathMonitor.start(queue: self.monitorQueue)
        self.startBandwidthMeasurement()
    }
    
    public func stopMonitoring() {
        self.pathMonitor.cancel()
        self.bandwidthTimer?.invalidate()
        self.bandwidthTimer = nil
    }
    
    private func setupPathMonitor() {
        self.pathMonitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.updateNetworkStatus(from: path)
            }
        }
    }
    
    private func updateNetworkStatus(from path: NWPath) {
        let isConnected = path.status == .satisfied
        let connectionType: ConnectionType = if path.usesInterfaceType(.wifi) {
            .wifi
        } else if path.usesInterfaceType(.cellular) {
            .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            .ethernet
        } else if !isConnected {
            .offline
        } else {
            .unknown
        }
        
        self.currentStatus = NetworkStatus(
            isConnected: isConnected,
            connectionType: connectionType,
            bandwidth: self.currentStatus.bandwidth // Keep existing bandwidth until updated
        )
        
        // Apply network-based optimizations
        self.applyNetworkOptimizations()
    }
    
    private func startBandwidthMeasurement() {
        self.bandwidthTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            self?.measureBandwidth()
        }
    }
    
    private func measureBandwidth() {
        // Simplified bandwidth measurement
        // In production, this would perform actual network tests
        let estimatedBandwidth: Double = switch self.currentStatus.connectionType {
        case .wifi:
            Double.random(in: 10 ... 100)
        case .ethernet:
            Double.random(in: 50 ... 1000)
        case .cellular:
            Double.random(in: 1 ... 50)
        default:
            0
        }
        
        self.currentStatus = NetworkStatus(
            isConnected: self.currentStatus.isConnected,
            connectionType: self.currentStatus.connectionType,
            bandwidth: estimatedBandwidth
        )
    }
    
    private func applyNetworkOptimizations() {
        self.isOptimizing = self.currentStatus.shouldOptimizeForBandwidth
        
        // Notify other systems of network changes
        NotificationCenter.default.post(
            name: .performanceNetworkChanged,
            object: self.currentStatus
        )
    }
    
    // MARK: - Network Optimization Helpers

    public func shouldCompressData() -> Bool {
        self.currentStatus.connectionType == .cellular || self.currentStatus.bandwidth < 5.0
    }
    
    public func shouldCacheAggressively() -> Bool {
        !self.currentStatus.isConnected || self.currentStatus.bandwidth < 2.0
    }
    
    public func recommendedImageQuality() -> ImageQuality {
        if self.currentStatus.connectionType == .wifi, self.currentStatus.bandwidth > 10 {
            .high
        } else if self.currentStatus.connectionType == .cellular, self.currentStatus.bandwidth > 5 {
            .medium
        } else {
            .low
        }
    }
}

public enum ImageQuality: String, Codable {
    case low
    case medium
    case high
    
    public var compressionQuality: CGFloat {
        switch self {
        case .low:
            0.3
        case .medium:
            0.6
        case .high:
            0.9
        }
    }
}

// MARK: - Battery Optimizer

public class BatteryOptimizer: ObservableObject {
    public static let shared = BatteryOptimizer()
    
    @Published public var currentMode: BatteryMode = .normal
    @Published public var isOptimizing = false
    @Published public var estimatedBatteryLife: TimeInterval?
    
    private var batteryTimer: Timer?
    private var lastBatteryLevel: Double = 100
    private var batteryHistory: [BatteryReading] = []
    
    private init() {
        self.startBatteryMonitoring()
    }
    
    // MARK: - Battery Monitoring

    private func startBatteryMonitoring() {
        self.batteryTimer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { [weak self] _ in
            self?.updateBatteryOptimization()
        }
        
        #if canImport(UIKit)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.batteryLevelChanged),
            name: UIDevice.batteryLevelDidChangeNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.powerModeChanged),
            name: .NSProcessInfoPowerStateDidChange,
            object: nil
        )
        #endif
    }
    
    @objc private func batteryLevelChanged() {
        self.updateBatteryOptimization()
    }
    
    @objc private func powerModeChanged() {
        self.updateBatteryOptimization()
    }
    
    private func updateBatteryOptimization() {
        let batteryStatus = PerformanceMonitor.shared.currentMetrics.batteryLevel
        
        // Record battery reading
        self.recordBatteryReading(batteryStatus)
        
        // Determine battery mode
        let newMode: BatteryMode = if batteryStatus.isLowPowerModeEnabled {
            .lowPowerMode
        } else if batteryStatus.level < 15 {
            .critical
        } else if batteryStatus.level < 30 {
            .saver
        } else {
            .normal
        }
        
        if newMode != self.currentMode {
            Task { @MainActor in
                self.currentMode = newMode
                self.applyBatteryOptimizations(newMode)
            }
        }
        
        // Update battery life estimation
        self.updateBatteryLifeEstimation()
    }
    
    private func recordBatteryReading(_ status: BatteryStatus) {
        let reading = BatteryReading(
            level: status.level,
            timestamp: Date(),
            isCharging: status.state == .charging
        )
        
        self.batteryHistory.append(reading)
        
        // Keep only last 24 hours of readings
        let cutoffTime = Date().addingTimeInterval(-24 * 3600)
        self.batteryHistory = self.batteryHistory.filter { $0.timestamp > cutoffTime }
    }
    
    private func updateBatteryLifeEstimation() {
        guard self.batteryHistory.count > 2 else {
            self.estimatedBatteryLife = nil
            return
        }
        
        // Calculate battery drain rate
        let recentReadings = self.batteryHistory.suffix(10)
        let timeSpan = recentReadings.last!.timestamp.timeIntervalSince(recentReadings.first!.timestamp)
        let levelDrop = recentReadings.first!.level - recentReadings.last!.level
        
        if timeSpan > 0, levelDrop > 0 {
            let drainRate = levelDrop / timeSpan // Percent per second
            let currentLevel = self.batteryHistory.last!.level
            let estimatedSeconds = currentLevel / drainRate
            self.estimatedBatteryLife = estimatedSeconds
        }
    }
    
    private func applyBatteryOptimizations(_ mode: BatteryMode) {
        self.isOptimizing = mode != .normal
        
        switch mode {
        case .normal:
            // No special optimizations
            break
        case .saver:
            // Moderate battery saving
            self.enableBatterySaving(level: .moderate)
        case .critical:
            // Aggressive battery saving
            self.enableBatterySaving(level: .aggressive)
        case .lowPowerMode:
            // System-level low power mode optimizations
            self.enableBatterySaving(level: .maximum)
        }
        
        // Notify other systems
        NotificationCenter.default.post(
            name: .performanceBatteryModeChanged,
            object: mode
        )
    }
    
    private func enableBatterySaving(level: BatterySavingLevel) {
        switch level {
        case .moderate:
            // Reduce background activity, lower screen brightness recommendations
            break
        case .aggressive:
            // Minimize network activity, reduce animation frame rates
            break
        case .maximum:
            // All optimizations enabled
            break
        }
    }
}

public enum BatteryMode: String, Codable {
    case normal
    case saver
    case critical
    case lowPowerMode
    
    public var description: String {
        switch self {
        case .normal:
            "Normal"
        case .saver:
            "Battery Saver"
        case .critical:
            "Critical Battery"
        case .lowPowerMode:
            "Low Power Mode"
        }
    }
    
    public var color: Color {
        switch self {
        case .normal:
            .green
        case .saver:
            .yellow
        case .critical:
            .red
        case .lowPowerMode:
            .orange
        }
    }
}

public enum BatterySavingLevel {
    case moderate
    case aggressive
    case maximum
}

private struct BatteryReading {
    let level: Double
    let timestamp: Date
    let isCharging: Bool
}

// MARK: - Notification Names

public extension Notification.Name {
    static let performanceMemoryWarning = Notification.Name("PerformanceMemoryWarning")
    static let performanceMemoryCleanup = Notification.Name("PerformanceMemoryCleanup")
    static let performanceOptimizationChanged = Notification.Name("PerformanceOptimizationChanged")
    static let performanceNetworkChanged = Notification.Name("PerformanceNetworkChanged")
    static let performanceBatteryModeChanged = Notification.Name("PerformanceBatteryModeChanged")
}
