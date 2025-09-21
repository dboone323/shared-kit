//
//  ErrorHandlingUI.swift
//  User Interface Components for Error Handling
//
//  Created by Enhanced Architecture System
//  Copyright © 2024 Quantum Workspace. All rights reserved.
//

import Combine
import Foundation
import SwiftUI

// MARK: - Error Display Components

/// Main error display view for showing errors to users
public struct ErrorDisplayView: View {
    let error: any AppErrorProtocol
    let onDismiss: () -> Void
    let onRetry: (() -> Void)?
    let onReportIssue: (() -> Void)?
    
    public init(
        error: any AppErrorProtocol,
        onDismiss: @escaping () -> Void,
        onRetry: (() -> Void)? = nil,
        onReportIssue: (() -> Void)? = nil
    ) {
        self.error = error
        self.onDismiss = onDismiss
        self.onRetry = onRetry
        self.onReportIssue = onReportIssue
    }
    
    public var body: some View {
        VStack(spacing: 16) {
            // Error Icon
            Image(systemName: self.severityIcon)
                .font(.system(size: 48))
                .foregroundColor(self.severityColor)
            
            // Error Message
            VStack(spacing: 8) {
                Text(self.error.userMessage)
                    .font(.headline)
                    .multilineTextAlignment(.center)
                
                Text(self.error.category.displayName)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Recovery Suggestions
            if !self.error.recoverySuggestions.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Try these solutions:")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    ForEach(Array(self.error.recoverySuggestions.enumerated()), id: \.offset) { index, suggestion in
                        HStack {
                            Text("\(index + 1).")
                                .foregroundColor(.secondary)
                            Text(suggestion)
                                .font(.caption)
                        }
                    }
                }
                .padding()
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(8)
            }
            
            // Action Buttons
            HStack(spacing: 16) {
                if let onRetry, error.isRecoverable {
                    Button("Try Again") {
                        onRetry()
                    }
                    .buttonStyle(.borderedProminent)
                }
                
                if let onReportIssue {
                    Button("Report Issue") {
                        onReportIssue()
                    }
                    .buttonStyle(.bordered)
                }
                
                Button("Dismiss") {
                    self.onDismiss()
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(24)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 8)
    }
    
    private var severityIcon: String {
        switch self.error.severity {
        case .low: "info.circle"
        case .medium: "exclamationmark.triangle"
        case .high: "xmark.circle"
        case .critical: "xmark.octagon"
        }
    }
    
    private var severityColor: Color {
        switch self.error.severity {
        case .low: .blue
        case .medium: .orange
        case .high: .red
        case .critical: .purple
        }
    }
}

/// Compact error banner for inline error display
public struct ErrorBannerView: View {
    let error: any AppErrorProtocol
    let onDismiss: () -> Void
    let onTap: (() -> Void)?
    
    public init(
        error: any AppErrorProtocol,
        onDismiss: @escaping () -> Void,
        onTap: (() -> Void)? = nil
    ) {
        self.error = error
        self.onDismiss = onDismiss
        self.onTap = onTap
    }
    
    public var body: some View {
        HStack {
            Image(systemName: self.severityIcon)
                .foregroundColor(self.severityColor)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(self.error.userMessage)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(2)
                
                Text(self.error.category.displayName)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: self.onDismiss) {
                Image(systemName: "xmark")
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(self.severityColor.opacity(0.1))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(self.severityColor.opacity(0.3), lineWidth: 1)
        )
        .onTapGesture {
            self.onTap?()
        }
    }
    
    private var severityIcon: String {
        switch self.error.severity {
        case .low: "info.circle.fill"
        case .medium: "exclamationmark.triangle.fill"
        case .high: "xmark.circle.fill"
        case .critical: "xmark.octagon.fill"
        }
    }
    
    private var severityColor: Color {
        switch self.error.severity {
        case .low: .blue
        case .medium: .orange
        case .high: .red
        case .critical: .purple
        }
    }
}

/// Error list view for displaying multiple errors
public struct ErrorListView: View {
    @StateObject private var errorManager = ErrorHandlerManager.shared
    @State private var selectedError: (any AppErrorProtocol)?
    @State private var showingErrorDetail = false
    
    public init() {}
    
    public var body: some View {
        NavigationView {
            VStack {
                // Error summary
                if !self.errorManager.recentErrors.isEmpty {
                    ErrorSummaryCard(
                        totalErrors: self.errorManager.recentErrors.count,
                        criticalErrors: self.errorManager.criticalErrors.count,
                        globalState: self.errorManager.globalErrorState
                    )
                    .padding(.horizontal)
                }
                
                // Error list
                List {
                    if self.errorManager.recentErrors.isEmpty {
                        ContentUnavailableView(
                            "No Recent Errors",
                            systemImage: "checkmark.circle",
                            description: Text("Your app is running smoothly!")
                        )
                    } else {
                        ForEach(Array(self.errorManager.recentErrors.enumerated()), id: \.element.errorId) { _, error in
                            ErrorRowView(error: error) {
                                self.selectedError = error
                                self.showingErrorDetail = true
                            }
                        }
                        .onDelete(perform: self.deleteErrors)
                    }
                }
                .listStyle(InsetGroupedListStyle())
            }
            .navigationTitle("Error Log")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Clear") {
                        self.errorManager.clearErrorHistory()
                    }
                    .disabled(self.errorManager.recentErrors.isEmpty)
                }
            }
        }
        .sheet(isPresented: self.$showingErrorDetail) {
            if let error = selectedError {
                ErrorDetailView(error: error) {
                    self.showingErrorDetail = false
                }
            }
        }
    }
    
    private func deleteErrors(offsets: IndexSet) {
        // In a real implementation, would remove specific errors
        // For now, just clear all
        self.errorManager.clearErrorHistory()
    }
}

/// Error summary card showing overall error state
public struct ErrorSummaryCard: View {
    let totalErrors: Int
    let criticalErrors: Int
    let globalState: GlobalErrorState
    
    public var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Error Summary")
                    .font(.headline)
                
                Text("\(self.totalErrors) recent errors")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if self.criticalErrors > 0 {
                    Text("\(self.criticalErrors) critical")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                StatusIndicator(state: self.globalState)
                
                Text(self.globalState.displayName)
                    .font(.caption)
                    .foregroundColor(self.stateColor)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var stateColor: Color {
        switch self.globalState {
        case .normal: .green
        case .degraded: .orange
        case .critical: .red
        }
    }
}

/// Status indicator for global error state
public struct StatusIndicator: View {
    let state: GlobalErrorState
    
    public var body: some View {
        Circle()
            .fill(self.indicatorColor)
            .frame(width: 12, height: 12)
            .overlay(
                Circle()
                    .stroke(self.indicatorColor.opacity(0.3), lineWidth: 2)
                    .scaleEffect(1.5)
            )
    }
    
    private var indicatorColor: Color {
        switch self.state {
        case .normal: .green
        case .degraded: .orange
        case .critical: .red
        }
    }
}

/// Individual error row in the list
public struct ErrorRowView: View {
    let error: any AppErrorProtocol
    let onTap: () -> Void
    
    public var body: some View {
        HStack {
            Image(systemName: self.severityIcon)
                .foregroundColor(self.severityColor)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(self.error.userMessage)
                    .font(.subheadline)
                    .lineLimit(2)
                
                HStack {
                    Text(self.error.category.displayName)
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(self.severityColor.opacity(0.2))
                        .cornerRadius(4)
                    
                    Text(self.formatTimestamp(self.error.timestamp))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
            }
            
            if self.error.isRecoverable {
                Image(systemName: "arrow.clockwise")
                    .foregroundColor(.blue)
                    .font(.caption)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: self.onTap)
    }
    
    private var severityIcon: String {
        switch self.error.severity {
        case .low: "info.circle"
        case .medium: "exclamationmark.triangle"
        case .high: "xmark.circle"
        case .critical: "xmark.octagon"
        }
    }
    
    private var severityColor: Color {
        switch self.error.severity {
        case .low: .blue
        case .medium: .orange
        case .high: .red
        case .critical: .purple
        }
    }
    
    private func formatTimestamp(_ timestamp: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }
}

/// Detailed error view with all information
public struct ErrorDetailView: View {
    let error: any AppErrorProtocol
    let onDismiss: () -> Void
    
    @StateObject private var errorManager = ErrorHandlerManager.shared
    @State private var isAttemptingRecovery = false
    
    public var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Error header
                    ErrorHeaderView(error: self.error)
                    
                    // Error details
                    ErrorDetailsSection(error: self.error)
                    
                    // Recovery suggestions
                    if !self.error.recoverySuggestions.isEmpty {
                        RecoverySuggestionsSection(error: self.error)
                    }
                    
                    // Context information
                    if !self.error.context.isEmpty {
                        ContextSection(context: self.error.context)
                    }
                    
                    // Technical details
                    TechnicalDetailsSection(error: self.error)
                    
                    // Recovery action
                    if self.error.isRecoverable {
                        RecoveryActionSection(error: self.error, isAttempting: self.$isAttemptingRecovery)
                    }
                }
                .padding()
            }
            .navigationTitle("Error Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        self.onDismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Copy Error ID") {
                            UIPasteboard.general.string = self.error.errorId
                        }
                        
                        Button("Export Error Report") {
                            self.exportErrorReport()
                        }
                        
                        if self.error.shouldReport {
                            Button("Report Issue") {
                                self.reportIssue()
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
    }
    
    private func exportErrorReport() {
        let report = self.errorManager.exportErrorReport()
        // In real implementation, would export the report
        print("Error report exported: \(report)")
    }
    
    private func reportIssue() {
        // In real implementation, would open issue reporting flow
        print("Reporting issue for error: \(self.error.errorId)")
    }
}

/// Error header section
public struct ErrorHeaderView: View {
    let error: any AppErrorProtocol
    
    public var body: some View {
        VStack(spacing: 12) {
            Image(systemName: self.severityIcon)
                .font(.system(size: 48))
                .foregroundColor(self.severityColor)
            
            Text(self.error.userMessage)
                .font(.title2)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
            
            HStack {
                Label(self.error.severity.displayName, systemImage: "exclamationmark.triangle")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(self.severityColor.opacity(0.2))
                    .cornerRadius(6)
                
                Label(self.error.category.displayName, systemImage: "tag")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.2))
                    .cornerRadius(6)
            }
        }
    }
    
    private var severityIcon: String {
        switch self.error.severity {
        case .low: "info.circle"
        case .medium: "exclamationmark.triangle"
        case .high: "xmark.circle"
        case .critical: "xmark.octagon"
        }
    }
    
    private var severityColor: Color {
        switch self.error.severity {
        case .low: .blue
        case .medium: .orange
        case .high: .red
        case .critical: .purple
        }
    }
}

/// Error details section
public struct ErrorDetailsSection: View {
    let error: any AppErrorProtocol
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Error Details", systemImage: "info.circle")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 4) {
                DetailRow(title: "Error ID", value: self.error.errorId)
                DetailRow(title: "Timestamp", value: self.formatTimestamp(self.error.timestamp))
                DetailRow(title: "Recoverable", value: self.error.isRecoverable ? "Yes" : "No")
                DetailRow(title: "Should Report", value: self.error.shouldReport ? "Yes" : "No")
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
    }
    
    private func formatTimestamp(_ timestamp: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        return formatter.string(from: timestamp)
    }
}

/// Recovery suggestions section
public struct RecoverySuggestionsSection: View {
    let error: any AppErrorProtocol
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Recovery Suggestions", systemImage: "lightbulb")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(self.error.recoverySuggestions.enumerated()), id: \.offset) { index, suggestion in
                    HStack(alignment: .top) {
                        Text("\(index + 1).")
                            .fontWeight(.medium)
                            .foregroundColor(.blue)
                        Text(suggestion)
                            .font(.subheadline)
                    }
                }
            }
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(8)
        }
    }
}

/// Context section
public struct ContextSection: View {
    let context: [String: Any]
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Context Information", systemImage: "doc.text")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 4) {
                ForEach(Array(self.context.keys.sorted()), id: \.self) { key in
                    DetailRow(title: key, value: "\(self.context[key] ?? "N/A")")
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
    }
}

/// Technical details section
public struct TechnicalDetailsSection: View {
    let error: any AppErrorProtocol
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Technical Details", systemImage: "wrench.and.screwdriver")
                .font(.headline)
            
            Text(self.error.technicalDetails)
                .font(.system(.caption, design: .monospaced))
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
        }
    }
}

/// Recovery action section
public struct RecoveryActionSection: View {
    let error: any AppErrorProtocol
    @Binding var isAttempting: Bool
    
    @StateObject private var errorManager = ErrorHandlerManager.shared
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Recovery Actions", systemImage: "arrow.clockwise")
                .font(.headline)
            
            if self.isAttempting {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Attempting recovery...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
            } else {
                Button("Attempt Automatic Recovery") {
                    self.attemptRecovery()
                }
                .buttonStyle(.borderedProminent)
                .disabled(self.errorManager.isProcessingRecovery)
            }
        }
    }
    
    private func attemptRecovery() {
        Task {
            self.isAttempting = true
            defer { isAttempting = false }
            
            let result = await errorManager.attemptManualRecovery(for: self.error)
            
            // In real implementation, would show recovery result to user
            print("Recovery result: \(result.success ? "Success" : "Failed") - \(result.message)")
        }
    }
}

/// Detail row for key-value pairs
public struct DetailRow: View {
    let title: String
    let value: String
    
    public var body: some View {
        HStack {
            Text(self.title + ":")
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(self.value)
                .font(.system(.subheadline, design: .monospaced))
        }
    }
}

// MARK: - Error Alert Modifiers

/// SwiftUI modifier for displaying errors as alerts
public struct ErrorAlertModifier: ViewModifier {
    @Binding var error: (any AppErrorProtocol)?
    let onRetry: (() -> Void)?
    
    public func body(content: Content) -> some View {
        content
            .alert(
                self.error?.category.displayName ?? "Error",
                isPresented: .constant(self.error != nil),
                presenting: self.error
            ) { presentedError in
                Button("OK") {
                    self.error = nil
                }
                
                if let onRetry, presentedError.isRecoverable {
                    Button("Try Again") {
                        onRetry()
                        self.error = nil
                    }
                }
                
                if presentedError.shouldReport {
                    Button("Report") {
                        // Report error
                        self.error = nil
                    }
                }
            } message: { presentedError in
                Text(presentedError.userMessage)
            }
    }
}

public extension View {
    /// Display error as alert
    func errorAlert(
        error: Binding<(any AppErrorProtocol)?>,
        onRetry: (() -> Void)? = nil
    ) -> some View {
        self.modifier(ErrorAlertModifier(error: error, onRetry: onRetry))
    }
}

// MARK: - Error Toast Notifications

/// Toast notification for errors
public struct ErrorToast: View {
    let error: any AppErrorProtocol
    let onDismiss: () -> Void
    
    @State private var isVisible = false
    
    public var body: some View {
        HStack {
            Image(systemName: self.severityIcon)
                .foregroundColor(.white)
            
            Text(self.error.userMessage)
                .font(.subheadline)
                .foregroundColor(.white)
                .lineLimit(2)
            
            Spacer()
            
            Button(action: self.onDismiss) {
                Image(systemName: "xmark")
                    .foregroundColor(.white)
            }
        }
        .padding()
        .background(self.severityColor)
        .cornerRadius(8)
        .shadow(radius: 4)
        .offset(y: self.isVisible ? 0 : -100)
        .opacity(self.isVisible ? 1 : 0)
        .onAppear {
            withAnimation(.easeOut(duration: 0.3)) {
                self.isVisible = true
            }
            
            // Auto-dismiss after delay for non-critical errors
            if self.error.severity != .critical {
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    self.dismissToast()
                }
            }
        }
    }
    
    private var severityIcon: String {
        switch self.error.severity {
        case .low: "info.circle.fill"
        case .medium: "exclamationmark.triangle.fill"
        case .high: "xmark.circle.fill"
        case .critical: "xmark.octagon.fill"
        }
    }
    
    private var severityColor: Color {
        switch self.error.severity {
        case .low: .blue
        case .medium: .orange
        case .high: .red
        case .critical: .purple
        }
    }
    
    private func dismissToast() {
        withAnimation(.easeIn(duration: 0.2)) {
            self.isVisible = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.onDismiss()
        }
    }
}
