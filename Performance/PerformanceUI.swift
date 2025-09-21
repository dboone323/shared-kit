import Combine
import SwiftUI

// Import all performance optimization components
// This file provides SwiftUI views for monitoring and controlling performance optimization

// MARK: - Performance Dashboard

public struct PerformanceDashboard: View {
    @StateObject private var performanceMonitor = PerformanceMonitor.shared
    @StateObject private var memoryManager = MemoryManager.shared
    @StateObject private var cpuOptimizer = CPUOptimizer.shared
    @StateObject private var networkMonitor = NetworkMonitor.shared
    @StateObject private var batteryOptimizer = BatteryOptimizer.shared
    
    @State private var showingDetails = false
    @State private var selectedMetricTab: MetricTab = .overview
    
    public init() {}
    
    public var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Performance Score Card
                PerformanceScoreCard(metrics: self.performanceMonitor.currentMetrics)
                
                // Metric Tabs
                MetricTabView(selectedTab: self.$selectedMetricTab)
                
                // Content based on selected tab
                ScrollView {
                    LazyVStack(spacing: 16) {
                        switch self.selectedMetricTab {
                        case .overview:
                            OverviewContent()
                        case .memory:
                            MemoryContent()
                        case .cpu:
                            CPUContent()
                        case .network:
                            NetworkContent()
                        case .battery:
                            BatteryContent()
                        }
                    }
                    .padding()
                }
                
                // Control Actions
                PerformanceControlActions()
            }
            .navigationTitle("Performance")
            .navigationBarItems(trailing: Button("Details") {
                self.showingDetails = true
            })
            .sheet(isPresented: self.$showingDetails) {
                DetailedPerformanceView()
            }
            .onAppear {
                self.performanceMonitor.startMonitoring()
            }
            .onDisappear {
                self.performanceMonitor.stopMonitoring()
            }
        }
    }
}

// MARK: - Performance Score Card

private struct PerformanceScoreCard: View {
    let metrics: PerformanceMetrics
    
    var body: some View {
        VStack(spacing: 12) {
            // Overall Score
            HStack {
                VStack(alignment: .leading) {
                    Text("Performance Score")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text("\(Int(self.metrics.overallPerformanceScore))")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(self.metrics.performanceLevel.color)
                }
                
                Spacer()
                
                // Performance Ring
                PerformanceRing(score: self.metrics.overallPerformanceScore)
                    .frame(width: 80, height: 80)
            }
            
            // Performance Level
            HStack {
                Circle()
                    .fill(self.metrics.performanceLevel.color)
                    .frame(width: 8, height: 8)
                
                Text(self.metrics.performanceLevel.description)
                    .font(.subheadline)
                    .foregroundColor(self.metrics.performanceLevel.color)
                
                Spacer()
                
                Text("Updated \(self.metrics.timestamp, style: .relative) ago")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
}

// MARK: - Performance Ring

private struct PerformanceRing: View {
    let score: Double
    
    private var progress: Double {
        self.score / 100.0
    }
    
    private var color: Color {
        if self.score >= 85 {
            .green
        } else if self.score >= 70 {
            .blue
        } else if self.score >= 50 {
            .orange
        } else {
            .red
        }
    }
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(
                    #if canImport(UIKit)
                    Color(UIColor.systemGray5)
                    #else
                    Color.gray.opacity(0.2)
                    #endif,
                    lineWidth: 8
                )
            
            Circle()
                .trim(from: 0, to: self.progress)
                .stroke(
                    self.color,
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 1.0), value: self.progress)
            
            Text("\(Int(self.score))")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(self.color)
        }
    }
}

// MARK: - Metric Tabs

private enum MetricTab: String, CaseIterable {
    case overview = "Overview"
    case memory = "Memory"
    case cpu = "CPU"
    case network = "Network"
    case battery = "Battery"
    
    var icon: String {
        switch self {
        case .overview:
            "chart.bar.fill"
        case .memory:
            "memorychip.fill"
        case .cpu:
            "cpu.fill"
        case .network:
            "network"
        case .battery:
            "battery.100"
        }
    }
}

private struct MetricTabView: View {
    @Binding var selectedTab: MetricTab
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(MetricTab.allCases, id: \.self) { tab in
                    MetricTabButton(
                        tab: tab,
                        isSelected: tab == selectedTab
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedTab = tab
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

private struct MetricTabButton: View {
    let tab: MetricTab
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: tab.icon)
                    .font(.system(size: 14, weight: .medium))
                
                Text(tab.rawValue)
                    .font(.system(size: 14, weight: .medium))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? Color.accentColor :
                        #if canImport(UIKit)
                        Color(UIColor.systemGray6)
                        #else
                        Color.gray.opacity(0.1)
                        #endif
                    )
            )
            .foregroundColor(isSelected ? .white : .primary)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Content Views

private struct OverviewContent: View {
    @StateObject private var performanceMonitor = PerformanceMonitor.shared
    
    var body: some View {
        let metrics = performanceMonitor.currentMetrics
        
        VStack(spacing: 16) {
            // Quick Metrics Grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                MetricCard(
                    title: "Memory",
                    value: "\(Int(metrics.memoryUsage.percentage))%",
                    color: metrics.memoryUsage.usageLevel.color,
                    icon: "memorychip.fill"
                )
                
                MetricCard(
                    title: "CPU",
                    value: "\(Int(metrics.cpuUsage.total))%",
                    color: metrics.cpuUsage.usageLevel.color,
                    icon: "cpu.fill"
                )
                
                MetricCard(
                    title: "Battery",
                    value: "\(Int(metrics.batteryLevel.level))%",
                    color: batteryColor(for: metrics.batteryLevel),
                    icon: "battery.100"
                )
                
                MetricCard(
                    title: "Network",
                    value: networkStatusText(metrics.networkStatus),
                    color: metrics.networkStatus.isConnected ? .green : .red,
                    icon: "network"
                )
            }
            
            // System Status Indicators
            SystemStatusIndicators()
        }
    }
    
    private func batteryColor(for battery: BatteryStatus) -> Color {
        if battery.level < 15 {
            .red
        } else if battery.level < 30 {
            .orange
        } else {
            .green
        }
    }
    
    private func networkStatusText(_ status: NetworkStatus) -> String {
        if !status.isConnected {
            return "Offline"
        }
        
        switch status.connectionType {
        case .wifi:
            return "Wi-Fi"
        case .cellular:
            return "Cellular"
        case .ethernet:
            return "Ethernet"
        default:
            return "Connected"
        }
    }
}

private struct MemoryContent: View {
    @StateObject private var memoryManager = MemoryManager.shared
    @StateObject private var performanceMonitor = PerformanceMonitor.shared
    
    var body: some View {
        let memoryUsage = performanceMonitor.currentMetrics.memoryUsage
        
        VStack(spacing: 20) {
            // Memory Usage Chart
            MemoryUsageChart(usage: memoryUsage)
            
            // Memory Details
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Memory Details")
                        .font(.headline)
                    Spacer()
                }
                
                DetailRow(
                    title: "Used",
                    value: "\(String(format: "%.1f", memoryUsage.used)) MB"
                )
                
                DetailRow(
                    title: "Available",
                    value: "\(String(format: "%.1f", memoryUsage.available)) MB"
                )
                
                DetailRow(
                    title: "Usage Level",
                    value: memoryUsage.usageLevel.rawValue.capitalized,
                    color: memoryUsage.usageLevel.color
                )
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            
            // Memory Management Actions
            MemoryManagementActions()
        }
    }
}

private struct CPUContent: View {
    @StateObject private var cpuOptimizer = CPUOptimizer.shared
    @StateObject private var performanceMonitor = PerformanceMonitor.shared
    
    var body: some View {
        let cpuUsage = performanceMonitor.currentMetrics.cpuUsage
        
        VStack(spacing: 20) {
            // CPU Usage Chart
            CPUUsageChart(usage: cpuUsage)
            
            // CPU Optimization Status
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("CPU Optimization")
                        .font(.headline)
                    Spacer()
                    
                    if cpuOptimizer.isThrottling {
                        Label("Throttling", systemImage: "speedometer")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
                
                DetailRow(
                    title: "Optimization Level",
                    value: cpuOptimizer.optimizationLevel.description
                )
                
                DetailRow(
                    title: "User CPU",
                    value: "\(String(format: "%.1f", cpuUsage.user))%"
                )
                
                DetailRow(
                    title: "System CPU",
                    value: "\(String(format: "%.1f", cpuUsage.system))%"
                )
                
                DetailRow(
                    title: "Total CPU",
                    value: "\(String(format: "%.1f", cpuUsage.total))%",
                    color: cpuUsage.usageLevel.color
                )
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
}

private struct NetworkContent: View {
    @StateObject private var networkMonitor = NetworkMonitor.shared
    
    var body: some View {
        let status = networkMonitor.currentStatus
        
        VStack(spacing: 20) {
            // Network Status Card
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Network Status")
                        .font(.headline)
                    Spacer()
                    
                    Circle()
                        .fill(status.isConnected ? .green : .red)
                        .frame(width: 12, height: 12)
                }
                
                DetailRow(
                    title: "Connection",
                    value: status.connectionType.rawValue.capitalized
                )
                
                DetailRow(
                    title: "Status",
                    value: status.isConnected ? "Connected" : "Disconnected",
                    color: status.isConnected ? .green : .red
                )
                
                if status.bandwidth > 0 {
                    DetailRow(
                        title: "Bandwidth",
                        value: "\(String(format: "%.1f", status.bandwidth)) Mbps"
                    )
                }
                
                if networkMonitor.isOptimizing {
                    DetailRow(
                        title: "Optimization",
                        value: "Active",
                        color: .orange
                    )
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            
            // Network Recommendations
            NetworkRecommendations(status: status)
        }
    }
}

private struct BatteryContent: View {
    @StateObject private var batteryOptimizer = BatteryOptimizer.shared
    @StateObject private var performanceMonitor = PerformanceMonitor.shared
    
    var body: some View {
        let batteryStatus = performanceMonitor.currentMetrics.batteryLevel
        
        VStack(spacing: 20) {
            // Battery Status Card
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Battery Status")
                        .font(.headline)
                    Spacer()
                    
                    Text("\(Int(batteryStatus.level))%")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(batteryColor(for: batteryStatus))
                }
                
                DetailRow(
                    title: "Battery Mode",
                    value: batteryOptimizer.currentMode.description,
                    color: batteryOptimizer.currentMode.color
                )
                
                DetailRow(
                    title: "Charging State",
                    value: batteryStatus.state.rawValue.capitalized
                )
                
                if batteryStatus.isLowPowerModeEnabled {
                    DetailRow(
                        title: "Low Power Mode",
                        value: "Enabled",
                        color: .orange
                    )
                }
                
                if let estimatedLife = batteryOptimizer.estimatedBatteryLife {
                    let hours = Int(estimatedLife / 3600)
                    let minutes = Int((estimatedLife.truncatingRemainder(dividingBy: 3600)) / 60)
                    DetailRow(
                        title: "Estimated Life",
                        value: "\(hours)h \(minutes)m"
                    )
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            
            // Battery Optimization Actions
            BatteryOptimizationActions()
        }
    }
    
    private func batteryColor(for battery: BatteryStatus) -> Color {
        if battery.level < 15 {
            .red
        } else if battery.level < 30 {
            .orange
        } else {
            .green
        }
    }
}

// MARK: - Supporting Views

private struct MetricCard: View {
    let title: String
    let value: String
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.system(size: 16))
                
                Spacer()
                
                Text(value)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(color)
            }
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.03), radius: 5, x: 0, y: 2)
    }
}

private struct DetailRow: View {
    let title: String
    let value: String
    let color: Color?
    
    init(title: String, value: String, color: Color? = nil) {
        self.title = title
        self.value = value
        self.color = color
    }
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .fontWeight(.medium)
                .foregroundColor(color ?? .primary)
        }
        .font(.system(size: 14))
    }
}

private struct SystemStatusIndicators: View {
    @StateObject private var performanceMonitor = PerformanceMonitor.shared
    
    var body: some View {
        let metrics = performanceMonitor.currentMetrics
        
        VStack(alignment: .leading, spacing: 12) {
            Text("System Status")
                .font(.headline)
            
            VStack(spacing: 8) {
                StatusIndicator(
                    title: "Thermal State",
                    status: metrics.thermalState.rawValue.capitalized,
                    color: thermalColor(for: metrics.thermalState),
                    icon: "thermometer"
                )
                
                StatusIndicator(
                    title: "Frame Rate",
                    status: "\(Int(metrics.frameRate)) FPS",
                    color: frameRateColor(for: metrics.frameRate),
                    icon: "display"
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func thermalColor(for state: ThermalState) -> Color {
        switch state {
        case .nominal:
            .green
        case .fair:
            .yellow
        case .serious:
            .orange
        case .critical:
            .red
        }
    }
    
    private func frameRateColor(for fps: Double) -> Color {
        if fps >= 55 {
            .green
        } else if fps >= 45 {
            .yellow
        } else if fps >= 30 {
            .orange
        } else {
            .red
        }
    }
}

private struct StatusIndicator: View {
    let title: String
    let status: String
    let color: Color
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 20)
            
            Text(title)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(status)
                .fontWeight(.medium)
                .foregroundColor(color)
        }
        .font(.system(size: 14))
    }
}

private struct MemoryUsageChart: View {
    let usage: MemoryUsage
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Memory Usage")
                .font(.headline)
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color(.systemGray5))
                        .cornerRadius(6)
                    
                    Rectangle()
                        .fill(usage.usageLevel.color)
                        .frame(width: geometry.size.width * (usage.percentage / 100))
                        .cornerRadius(6)
                        .animation(.easeInOut(duration: 0.5), value: usage.percentage)
                }
            }
            .frame(height: 12)
            
            HStack {
                Text("\(String(format: "%.1f", usage.percentage))% used")
                    .font(.caption)
                    .foregroundColor(usage.usageLevel.color)
                
                Spacer()
                
                Text("\(String(format: "%.1f", usage.available - usage.used)) MB free")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.03), radius: 5, x: 0, y: 2)
    }
}

private struct CPUUsageChart: View {
    let usage: CPUUsage
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("CPU Usage")
                .font(.headline)
            
            // Stacked progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color(.systemGray5))
                        .cornerRadius(6)
                    
                    HStack(spacing: 0) {
                        Rectangle()
                            .fill(Color.blue)
                            .frame(width: geometry.size.width * (usage.user / 100))
                        
                        Rectangle()
                            .fill(Color.orange)
                            .frame(width: geometry.size.width * (usage.system / 100))
                        
                        Spacer(minLength: 0)
                    }
                    .cornerRadius(6)
                    .animation(.easeInOut(duration: 0.5), value: usage.total)
                }
            }
            .frame(height: 12)
            
            HStack {
                Label("User: \(String(format: "%.1f", usage.user))%", systemImage: "person.fill")
                    .font(.caption)
                    .foregroundColor(.blue)
                
                Spacer()
                
                Label("System: \(String(format: "%.1f", usage.system))%", systemImage: "gearshape.fill")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.03), radius: 5, x: 0, y: 2)
    }
}

private struct NetworkRecommendations: View {
    let status: NetworkStatus
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recommendations")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                if status.shouldOptimizeForBandwidth {
                    RecommendationItem(
                        icon: "wifi.exclamationmark",
                        text: "Limited bandwidth detected. Consider enabling data compression.",
                        color: .orange
                    )
                }
                
                if !status.isConnected {
                    RecommendationItem(
                        icon: "wifi.slash",
                        text: "No network connection. Enable offline mode for better experience.",
                        color: .red
                    )
                }
                
                if status.connectionType == .cellular {
                    RecommendationItem(
                        icon: "antenna.radiowaves.left.and.right",
                        text: "Using cellular data. Consider switching to Wi-Fi to save battery.",
                        color: .blue
                    )
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

private struct RecommendationItem: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 20)
            
            Text(text)
                .font(.system(size: 14))
                .foregroundColor(.primary)
                .multilineTextAlignment(.leading)
            
            Spacer()
        }
    }
}

// MARK: - Action Views

private struct PerformanceControlActions: View {
    @StateObject private var memoryManager = MemoryManager.shared
    @StateObject private var performanceMonitor = PerformanceMonitor.shared
    
    var body: some View {
        HStack(spacing: 16) {
            Button(action: {
                memoryManager.performRoutineCleanup()
            }) {
                Label("Clean Memory", systemImage: "trash")
            }
            .buttonStyle(.bordered)
            .disabled(memoryManager.isOptimizing)
            
            Button(action: {
                if performanceMonitor.isMonitoring {
                    performanceMonitor.stopMonitoring()
                } else {
                    performanceMonitor.startMonitoring()
                }
            }) {
                Label(
                    performanceMonitor.isMonitoring ? "Stop" : "Start",
                    systemImage: performanceMonitor.isMonitoring ? "stop.circle" : "play.circle"
                )
            }
            .buttonStyle(.bordered)
            
            Spacer()
        }
        .padding()
    }
}

private struct MemoryManagementActions: View {
    @StateObject private var memoryManager = MemoryManager.shared
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Button(action: {
                    memoryManager.performRoutineCleanup()
                }) {
                    Label("Routine Cleanup", systemImage: "trash")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(memoryManager.isOptimizing)
                
                Button(action: {
                    memoryManager.performEmergencyCleanup()
                }) {
                    Label("Emergency Cleanup", systemImage: "exclamationmark.triangle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(memoryManager.isOptimizing)
            }
            
            if let lastCleanup = memoryManager.lastCleanupDate {
                Text("Last cleanup: \(lastCleanup, style: .relative) ago")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

private struct BatteryOptimizationActions: View {
    @StateObject private var batteryOptimizer = BatteryOptimizer.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Battery Optimization")
                .font(.headline)
            
            VStack(spacing: 8) {
                if batteryOptimizer.currentMode == .normal {
                    Text("Battery optimization is not currently active.")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                } else {
                    Text("Active optimizations are helping extend battery life.")
                        .font(.system(size: 14))
                        .foregroundColor(.green)
                }
                
                #if canImport(UIKit)
                Button(action: {
                    // Open system settings for Low Power Mode
                    if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(settingsUrl)
                    }
                }) {
                    Label("Open Battery Settings", systemImage: "gearshape")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                #endif
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Detailed Performance View

private struct DetailedPerformanceView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var performanceMonitor = PerformanceMonitor.shared
    
    var body: some View {
        NavigationView {
            List {
                Section("Performance Metrics") {
                    MetricDetailRow(
                        title: "Overall Score",
                        value: "\(Int(performanceMonitor.currentMetrics.overallPerformanceScore))/100",
                        color: performanceMonitor.currentMetrics.performanceLevel.color
                    )
                    
                    MetricDetailRow(
                        title: "Performance Level",
                        value: performanceMonitor.currentMetrics.performanceLevel.description
                    )
                }
                
                Section("Memory") {
                    let memory = performanceMonitor.currentMetrics.memoryUsage
                    
                    MetricDetailRow(
                        title: "Used Memory",
                        value: "\(String(format: "%.1f", memory.used)) MB"
                    )
                    
                    MetricDetailRow(
                        title: "Available Memory",
                        value: "\(String(format: "%.1f", memory.available)) MB"
                    )
                    
                    MetricDetailRow(
                        title: "Usage Percentage",
                        value: "\(String(format: "%.1f", memory.percentage))%",
                        color: memory.usageLevel.color
                    )
                }
                
                Section("CPU") {
                    let cpu = performanceMonitor.currentMetrics.cpuUsage
                    
                    MetricDetailRow(
                        title: "User CPU",
                        value: "\(String(format: "%.1f", cpu.user))%"
                    )
                    
                    MetricDetailRow(
                        title: "System CPU",
                        value: "\(String(format: "%.1f", cpu.system))%"
                    )
                    
                    MetricDetailRow(
                        title: "Total CPU",
                        value: "\(String(format: "%.1f", cpu.total))%",
                        color: cpu.usageLevel.color
                    )
                }
                
                Section("Network") {
                    let network = performanceMonitor.currentMetrics.networkStatus
                    
                    MetricDetailRow(
                        title: "Connection Status",
                        value: network.isConnected ? "Connected" : "Disconnected",
                        color: network.isConnected ? .green : .red
                    )
                    
                    MetricDetailRow(
                        title: "Connection Type",
                        value: network.connectionType.rawValue.capitalized
                    )
                    
                    if network.bandwidth > 0 {
                        MetricDetailRow(
                            title: "Bandwidth",
                            value: "\(String(format: "%.1f", network.bandwidth)) Mbps"
                        )
                    }
                }
                
                Section("Battery & Thermal") {
                    let battery = performanceMonitor.currentMetrics.batteryLevel
                    let thermal = performanceMonitor.currentMetrics.thermalState
                    
                    MetricDetailRow(
                        title: "Battery Level",
                        value: "\(Int(battery.level))%",
                        color: batteryColor(for: battery)
                    )
                    
                    MetricDetailRow(
                        title: "Battery State",
                        value: battery.state.rawValue.capitalized
                    )
                    
                    if battery.isLowPowerModeEnabled {
                        MetricDetailRow(
                            title: "Low Power Mode",
                            value: "Enabled",
                            color: .orange
                        )
                    }
                    
                    MetricDetailRow(
                        title: "Thermal State",
                        value: thermal.rawValue.capitalized,
                        color: thermalColor(for: thermal)
                    )
                    
                    MetricDetailRow(
                        title: "Frame Rate",
                        value: "\(Int(performanceMonitor.currentMetrics.frameRate)) FPS"
                    )
                }
            }
            .navigationTitle("Performance Details")
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
    
    private func batteryColor(for battery: BatteryStatus) -> Color {
        if battery.level < 15 {
            .red
        } else if battery.level < 30 {
            .orange
        } else {
            .green
        }
    }
    
    private func thermalColor(for state: ThermalState) -> Color {
        switch state {
        case .nominal:
            .green
        case .fair:
            .yellow
        case .serious:
            .orange
        case .critical:
            .red
        }
    }
}

private struct MetricDetailRow: View {
    let title: String
    let value: String
    let color: Color?
    
    init(title: String, value: String, color: Color? = nil) {
        self.title = title
        self.value = value
        self.color = color
    }
    
    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .fontWeight(.medium)
                .foregroundColor(color ?? .primary)
        }
    }
}

// MARK: - Performance Optimization Widget

public struct PerformanceWidget: View {
    @StateObject private var performanceMonitor = PerformanceMonitor.shared
    @State private var showingDashboard = false
    
    public init() {}
    
    public var body: some View {
        Button(action: {
            showingDashboard = true
        }) {
            HStack(spacing: 8) {
                PerformanceRing(score: performanceMonitor.currentMetrics.overallPerformanceScore)
                    .frame(width: 24, height: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Performance")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(Int(performanceMonitor.currentMetrics.overallPerformanceScore))")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.primary)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingDashboard) {
            PerformanceDashboard()
        }
        .onAppear {
            performanceMonitor.startMonitoring(interval: 5.0) // Less frequent for widget
        }
    }
}
