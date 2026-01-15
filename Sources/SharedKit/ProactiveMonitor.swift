import Foundation

/// Proactive monitoring system that runs background health checks
@available(macOS 12.0, *)
public actor ProactiveMonitor {
    
    public static let shared = ProactiveMonitor()
    
    private var isMonitoring: Bool = false
    private var checkInterval: TimeInterval = 300 // 5 minutes
    private var lastCheck: Date?
    private var detectedIssues: [MonitoringIssue] = []
    private var suggestions: [String] = []
    
    public struct MonitoringIssue: Sendable {
        public let severity: Severity
        public let component: String
        public let description: String
        public let detectedAt: Date
        public let suggestion: String?
        
        public enum Severity: Sendable {
            case info, warning, critical
        }
    }
    
    private init() {}
    
    /// Start proactive monitoring
    public func startMonitoring(interval: TimeInterval = 300) {
        guard !isMonitoring else { return }
        isMonitoring = true
        checkInterval = interval
        
        Task {
            await runMonitoringLoop()
        }
    }
    
    /// Stop proactive monitoring
    public func stopMonitoring() {
        isMonitoring = false
    }
    
    /// Get current issues
    public func getIssues() -> [MonitoringIssue] {
        return detectedIssues
    }
    
    /// Get suggestions
    public func getSuggestions() -> [String] {
        return suggestions
    }
    
    private func runMonitoringLoop() async {
        while isMonitoring {
            await performHealthCheck()
            try? await Task.sleep(nanoseconds: UInt64(checkInterval * 1_000_000_000))
        }
    }
    
    private func performHealthCheck() async {
        lastCheck = Date()
        var newIssues: [MonitoringIssue] = []
        var newSuggestions: [String] = []
        
        // Check 1: Database connectivity
        do {
            let store = PostgresVectorStore.shared
            try await store.connect()
            print("✅ Proactive Monitor: Database healthy")
        } catch {
            let issue = MonitoringIssue(
                severity: .critical,
                component: "Database",
                description: "PostgreSQL connection failed: \(error.localizedDescription)",
                detectedAt: Date(),
                suggestion: "Check if PostgreSQL is running: docker ps | grep db"
            )
            newIssues.append(issue)
            newSuggestions.append("Database connection lost - restart the db container")
        }
        
        // Check 2: Vector store size monitoring
        // Additional checks can be added here in production
        
        // Update state
        detectedIssues = newIssues
        suggestions = newSuggestions
        
        // Notify if critical issues found
        if newIssues.contains(where: { $0.severity == .critical }) {
            await notifyCriticalIssues(newIssues.filter { $0.severity == .critical })
        }
    }
    
    private func notifyCriticalIssues(_ issues: [MonitoringIssue]) async {
        // In production, send notification to user
        for issue in issues {
            print("🚨 CRITICAL: \(issue.component) - \(issue.description)")
            if let suggestion = issue.suggestion {
                print("   💡 Suggestion: \(suggestion)")
            }
        }
    }
}
