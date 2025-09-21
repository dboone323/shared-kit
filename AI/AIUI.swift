import Combine
import SwiftUI

// MARK: - AI Integration UI Components

// SwiftUI views for AI and machine learning features

// MARK: - AI Dashboard

@available(iOS 13.0, macOS 10.15, *)
public struct AIDashboard: View {
    @StateObject private var aiCoordinator = AICoordinator.shared
    @StateObject private var coreMLManager = CoreMLManager.shared
    @StateObject private var nlProcessor = NaturalLanguageProcessor.shared
    @StateObject private var visionProcessor = ComputerVisionProcessor.shared
    @StateObject private var predictiveEngine = PredictiveAnalyticsEngine.shared
    
    @State private var selectedTab: AITab = .overview
    @State private var showingModelManager = false
    
    public init() {}
    
    public var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Status Header
                AIStatusHeader()
                
                // Tab Selection
                AITabView(selectedTab: self.$selectedTab)
                
                // Content
                ScrollView {
                    LazyVStack(spacing: 16) {
                        switch self.selectedTab {
                        case .overview:
                            AIOverviewContent()
                        case .textAnalysis:
                            TextAnalysisContent()
                        case .imageProcessing:
                            ImageProcessingContent()
                        case .predictions:
                            PredictionsContent()
                        case .models:
                            ModelsContent()
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("AI & ML")
            .navigationBarItems(trailing: Button("Models") {
                self.showingModelManager = true
            })
            .sheet(isPresented: self.$showingModelManager) {
                ModelManagerView()
            }
        }
    }
}

// MARK: - AI Status Header

@available(iOS 13.0, macOS 10.15, *)
private struct AIStatusHeader: View {
    @StateObject private var aiCoordinator = AICoordinator.shared
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("AI Status")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(self.statusText)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                StatusIndicatorView(isActive: self.aiCoordinator.isInitialized)
            }
            
            // Available Features
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 8) {
                ForEach(AIFeature.allCases, id: \.self) { feature in
                    FeatureStatusCard(
                        feature: feature,
                        isAvailable: self.aiCoordinator.isFeatureAvailable(feature)
                    )
                }
            }
        }
        .padding()
        .background(
            #if canImport(UIKit)
            Color(UIColor.systemBackground)
            #else
            Color(.controlBackgroundColor)
            #endif
        )
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
    
    private var statusText: String {
        if aiCoordinator.isInitialized {
            "AI system initialized - \(aiCoordinator.availableFeatures.count) features available"
        } else {
            "Initializing AI system..."
        }
    }
}

// MARK: - Feature Status Card

private struct FeatureStatusCard: View {
    let feature: AIFeature
    let isAvailable: Bool
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: iconName)
                .font(.system(size: 20))
                .foregroundColor(isAvailable ? .green : .gray)
            
            Text(displayName)
                .font(.caption)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isAvailable ? Color.green.opacity(0.1) : Color.gray.opacity(0.1))
        )
    }
    
    private var iconName: String {
        switch feature {
        case .machineLearning:
            "cpu"
        case .naturalLanguageProcessing:
            "text.bubble"
        case .computerVision:
            "camera.viewfinder"
        case .predictiveAnalytics:
            "chart.line.uptrend.xyaxis"
        }
    }
    
    private var displayName: String {
        switch feature {
        case .machineLearning:
            "Core ML"
        case .naturalLanguageProcessing:
            "NLP"
        case .computerVision:
            "Vision"
        case .predictiveAnalytics:
            "Analytics"
        }
    }
}

// MARK: - Status Indicator

private struct StatusIndicatorView: View {
    let isActive: Bool
    
    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(isActive ? Color.green : Color.orange)
                .frame(width: 8, height: 8)
                .scaleEffect(isActive ? 1.0 : 0.8)
                .animation(.easeInOut(duration: 1.0).repeatForever(), value: isActive)
            
            Text(isActive ? "Active" : "Initializing")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(isActive ? .green : .orange)
        }
    }
}

// MARK: - AI Tabs

private enum AITab: String, CaseIterable {
    case overview = "Overview"
    case textAnalysis = "Text"
    case imageProcessing = "Vision"
    case predictions = "Predictions"
    case models = "Models"
    
    var icon: String {
        switch self {
        case .overview:
            "square.grid.2x2"
        case .textAnalysis:
            "text.alignleft"
        case .imageProcessing:
            "photo"
        case .predictions:
            "chart.bar.fill"
        case .models:
            "brain.head.profile"
        }
    }
}

private struct AITabView: View {
    @Binding var selectedTab: AITab
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(AITab.allCases, id: \.self) { tab in
                    AITabButton(
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
        .background(
            #if canImport(UIKit)
            Color(UIColor.systemGray6)
            #else
            Color.gray.opacity(0.1)
            #endif
        )
    }
}

private struct AITabButton: View {
    let tab: AITab
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
                    .fill(isSelected ? Color.accentColor : Color.clear)
            )
            .foregroundColor(isSelected ? .white : .primary)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Content Views

@available(iOS 13.0, macOS 10.15, *)
private struct AIOverviewContent: View {
    @StateObject private var aiCoordinator = AICoordinator.shared
    @StateObject private var coreMLManager = CoreMLManager.shared
    
    var body: some View {
        VStack(spacing: 16) {
            // Quick Stats
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                StatCard(
                    title: "Available Models",
                    value: "\(coreMLManager.availableModels.count)",
                    icon: "brain.head.profile",
                    color: .blue
                )
                
                StatCard(
                    title: "Loaded Models",
                    value: "\(coreMLManager.loadedModels.count)",
                    icon: "cpu",
                    color: .green
                )
                
                StatCard(
                    title: "AI Features",
                    value: "\(aiCoordinator.availableFeatures.count)",
                    icon: "sparkles",
                    color: .purple
                )
                
                StatCard(
                    title: "Status",
                    value: aiCoordinator.isInitialized ? "Ready" : "Loading",
                    icon: aiCoordinator.isInitialized ? "checkmark.circle" : "clock",
                    color: aiCoordinator.isInitialized ? .green : .orange
                )
            }
            
            // Recent Activity
            AIActivityFeed()
        }
    }
}

@available(iOS 13.0, macOS 10.15, *)
private struct TextAnalysisContent: View {
    @StateObject private var nlProcessor = NaturalLanguageProcessor.shared
    @State private var inputText = ""
    @State private var analysisResult: SentimentAnalysis?
    @State private var keywords: [Keyword] = []
    @State private var languageInfo: LanguageInfo?
    
    var body: some View {
        VStack(spacing: 16) {
            // Text Input
            VStack(alignment: .leading, spacing: 8) {
                Text("Text Analysis")
                    .font(.headline)
                
                TextEditor(text: $inputText)
                    .frame(minHeight: 100)
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                
                HStack {
                    Button("Analyze Sentiment") {
                        Task {
                            analysisResult = await nlProcessor.analyzeSentiment(inputText)
                        }
                    }
                    .buttonStyle(.bordered)
                    .disabled(inputText.isEmpty || nlProcessor.isProcessing)
                    
                    Button("Extract Keywords") {
                        keywords = nlProcessor.extractKeywords(inputText)
                    }
                    .buttonStyle(.bordered)
                    .disabled(inputText.isEmpty)
                    
                    Button("Detect Language") {
                        languageInfo = nlProcessor.detectLanguage(inputText)
                    }
                    .buttonStyle(.bordered)
                    .disabled(inputText.isEmpty)
                    
                    Spacer()
                    
                    if nlProcessor.isProcessing {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                }
            }
            .padding()
            .background(
                #if canImport(UIKit)
                Color(UIColor.systemBackground)
                #else
                Color(.controlBackgroundColor)
                #endif
            )
            .cornerRadius(12)
            
            // Results
            if let analysis = analysisResult {
                SentimentResultView(analysis: analysis)
            }
            
            if !keywords.isEmpty {
                KeywordsResultView(keywords: keywords)
            }
            
            if let language = languageInfo {
                LanguageResultView(languageInfo: language)
            }
        }
    }
}

@available(iOS 13.0, macOS 10.15, *)
private struct ImageProcessingContent: View {
    @StateObject private var visionProcessor = ComputerVisionProcessor.shared
    @State private var selectedImage: PlatformImage?
    @State private var classificationResult: ImageClassificationResult?
    @State private var textRecognitionResult: TextRecognitionResult?
    @State private var showingImagePicker = false
    
    var body: some View {
        VStack(spacing: 16) {
            // Image Selection
            VStack(alignment: .leading, spacing: 12) {
                Text("Image Processing")
                    .font(.headline)
                
                if let image = selectedImage {
                    #if canImport(UIKit)
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 200)
                        .cornerRadius(8)
                    #else
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 200)
                        .cornerRadius(8)
                    #endif
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 200)
                        .overlay(
                            VStack {
                                Image(systemName: "photo")
                                    .font(.system(size: 48))
                                    .foregroundColor(.gray)
                                Text("Select an image")
                                    .foregroundColor(.gray)
                            }
                        )
                }
                
                HStack {
                    Button("Select Image") {
                        showingImagePicker = true
                    }
                    .buttonStyle(.bordered)
                    
                    if selectedImage != nil {
                        Button("Classify") {
                            Task {
                                do {
                                    classificationResult = try await visionProcessor.classifyImage(selectedImage!)
                                } catch {
                                    print("Classification error: \(error)")
                                }
                            }
                        }
                        .buttonStyle(.bordered)
                        .disabled(visionProcessor.isProcessing)
                        
                        Button("Extract Text") {
                            Task {
                                do {
                                    textRecognitionResult = try await visionProcessor.recognizeText(in: selectedImage!)
                                } catch {
                                    print("Text recognition error: \(error)")
                                }
                            }
                        }
                        .buttonStyle(.bordered)
                        .disabled(visionProcessor.isProcessing)
                    }
                    
                    Spacer()
                    
                    if visionProcessor.isProcessing {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                }
            }
            .padding()
            .background(
                #if canImport(UIKit)
                Color(UIColor.systemBackground)
                #else
                Color(.controlBackgroundColor)
                #endif
            )
            .cornerRadius(12)
            
            // Results
            if let classification = classificationResult {
                ImageClassificationResultView(result: classification)
            }
            
            if let textResult = textRecognitionResult {
                TextRecognitionResultView(result: textResult)
            }
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePickerView { image in
                selectedImage = image
            }
        }
    }
}

@available(iOS 13.0, macOS 10.15, *)
private struct PredictionsContent: View {
    @StateObject private var predictiveEngine = PredictiveAnalyticsEngine.shared
    @State private var selectedPredictionType: PredictionType = .habitSuccess
    @State private var habitPrediction: HabitPrediction?
    @State private var expensePrediction: ExpensePrediction?
    
    var body: some View {
        VStack(spacing: 16) {
            // Prediction Type Selector
            VStack(alignment: .leading, spacing: 12) {
                Text("Predictive Analytics")
                    .font(.headline)
                
                Picker("Prediction Type", selection: $selectedPredictionType) {
                    Text("Habit Success").tag(PredictionType.habitSuccess)
                    Text("Expense Category").tag(PredictionType.expenseCategory)
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            .padding()
            .background(
                #if canImport(UIKit)
                Color(UIColor.systemBackground)
                #else
                Color(.controlBackgroundColor)
                #endif
            )
            .cornerRadius(12)
            
            // Prediction Interface
            switch selectedPredictionType {
            case .habitSuccess:
                HabitPredictionView(prediction: $habitPrediction)
            case .expenseCategory:
                ExpensePredictionView(prediction: $expensePrediction)
            default:
                Text("Prediction type not implemented")
                    .foregroundColor(.secondary)
            }
            
            // Recent Predictions
            RecentPredictionsView()
        }
    }
    
    private enum PredictionType: CaseIterable {
        case habitSuccess
        case expenseCategory
    }
}

@available(iOS 13.0, macOS 10.15, *)
private struct ModelsContent: View {
    @StateObject private var coreMLManager = CoreMLManager.shared
    
    var body: some View {
        VStack(spacing: 16) {
            // Available Models
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Available Models")
                        .font(.headline)
                    
                    Spacer()
                    
                    if coreMLManager.isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                }
                
                LazyVStack(spacing: 8) {
                    ForEach(coreMLManager.availableModels) { model in
                        ModelCard(model: model)
                    }
                }
            }
            .padding()
            .background(
                #if canImport(UIKit)
                Color(UIColor.systemBackground)
                #else
                Color(.controlBackgroundColor)
                #endif
            )
            .cornerRadius(12)
        }
    }
}

// MARK: - Supporting Views

private struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
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
        .background(
            #if canImport(UIKit)
            Color(UIColor.systemBackground)
            #else
            Color(.controlBackgroundColor)
            #endif
        )
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.03), radius: 5, x: 0, y: 2)
    }
}

@available(iOS 13.0, macOS 10.15, *)
private struct AIActivityFeed: View {
    @StateObject private var predictiveEngine = PredictiveAnalyticsEngine.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent AI Activity")
                .font(.headline)
            
            if predictiveEngine.predictions.isEmpty {
                VStack {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 32))
                        .foregroundColor(.gray)
                    Text("No recent AI activity")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(predictiveEngine.predictions.prefix(5)) { prediction in
                        AIActivityItem(prediction: prediction)
                    }
                }
            }
        }
        .padding()
        .background(
            #if canImport(UIKit)
            Color(UIColor.systemBackground)
            #else
            Color(.controlBackgroundColor)
            #endif
        )
        .cornerRadius(12)
    }
}

private struct AIActivityItem: View {
    let prediction: Prediction
    
    var body: some View {
        HStack {
            Image(systemName: iconForPredictionType(prediction.type))
                .foregroundColor(.blue)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(titleForPredictionType(prediction.type))
                    .font(.system(size: 14, weight: .medium))
                
                Text(prediction.timestamp, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text("\(Int(prediction.confidence * 100))%")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.blue)
        }
        .padding(.vertical, 4)
    }
    
    private func iconForPredictionType(_ type: Prediction.PredictionType) -> String {
        switch type {
        case .habitSuccess:
            "checkmark.circle"
        case .expenseCategory:
            "creditcard"
        case .taskPriority:
            "list.bullet"
        case .userBehavior:
            "person.crop.circle"
        }
    }
    
    private func titleForPredictionType(_ type: Prediction.PredictionType) -> String {
        switch type {
        case .habitSuccess:
            "Habit Success Prediction"
        case .expenseCategory:
            "Expense Categorization"
        case .taskPriority:
            "Task Priority Analysis"
        case .userBehavior:
            "User Behavior Analysis"
        }
    }
}

private struct SentimentResultView: View {
    let analysis: SentimentAnalysis
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Sentiment Analysis Results")
                .font(.headline)
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Sentiment")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(analysis.sentiment.rawValue.capitalized)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(colorForSentiment(analysis.sentiment))
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Confidence")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("\(Int(analysis.confidence * 100))%")
                        .font(.title2)
                        .fontWeight(.semibold)
                }
            }
            
            if !analysis.emotions.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Detected Emotions")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                        ForEach(analysis.emotions, id: \.self) { emotion in
                            Text(emotion.rawValue.capitalized)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(12)
                        }
                    }
                }
            }
        }
        .padding()
        .background(
            #if canImport(UIKit)
            Color(UIColor.systemBackground)
            #else
            Color(.controlBackgroundColor)
            #endif
        )
        .cornerRadius(12)
    }
    
    private func colorForSentiment(_ sentiment: Sentiment) -> Color {
        switch sentiment {
        case .positive:
            .green
        case .negative:
            .red
        case .neutral:
            .blue
        }
    }
}

private struct KeywordsResultView: View {
    let keywords: [Keyword]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Extracted Keywords")
                .font(.headline)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                ForEach(keywords.prefix(10), id: \.word) { keyword in
                    HStack {
                        Text(keyword.word)
                            .font(.system(size: 14))
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        Text("\(keyword.frequency)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(
            #if canImport(UIKit)
            Color(UIColor.systemBackground)
            #else
            Color(.controlBackgroundColor)
            #endif
        )
        .cornerRadius(12)
    }
}

private struct LanguageResultView: View {
    let languageInfo: LanguageInfo
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Language Detection")
                .font(.headline)
            
            if let dominantLanguage = languageInfo.dominantLanguage {
                HStack {
                    Text("Detected Language:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(dominantLanguage.rawValue)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Text("\(Int(languageInfo.confidence * 100))%")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
        }
        .padding()
        .background(
            #if canImport(UIKit)
            Color(UIColor.systemBackground)
            #else
            Color(.controlBackgroundColor)
            #endif
        )
        .cornerRadius(12)
    }
}

private struct ImageClassificationResultView: View {
    let result: ImageClassificationResult
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Image Classification Results")
                .font(.headline)
            
            LazyVStack(spacing: 8) {
                ForEach(result.classifications, id: \.identifier) { classification in
                    HStack {
                        Text(classification.identifier)
                            .font(.system(size: 14))
                        
                        Spacer()
                        
                        Text("\(Int(classification.confidence * 100))%")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(
            #if canImport(UIKit)
            Color(UIColor.systemBackground)
            #else
            Color(.controlBackgroundColor)
            #endif
        )
        .cornerRadius(12)
    }
}

private struct TextRecognitionResultView: View {
    let result: TextRecognitionResult
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Text Recognition Results")
                .font(.headline)
            
            if !result.recognizedText.isEmpty {
                ScrollView {
                    Text(result.recognizedText)
                        .font(.system(size: 14, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(8)
                        .background(
                            #if canImport(UIKit)
                            Color(UIColor.systemGray6)
                            #else
                            Color.gray.opacity(0.1)
                            #endif
                        )
                        .cornerRadius(8)
                }
                .frame(maxHeight: 150)
            } else {
                Text("No text found in image")
                    .foregroundColor(.secondary)
                    .italic()
            }
        }
        .padding()
        .background(
            #if canImport(UIKit)
            Color(UIColor.systemBackground)
            #else
            Color(.controlBackgroundColor)
            #endif
        )
        .cornerRadius(12)
    }
}

private struct ModelCard: View {
    let model: AIModel
    @StateObject private var coreMLManager = CoreMLManager.shared
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(model.name)
                    .font(.system(size: 16, weight: .medium))
                
                Text(model.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack {
                    Text(model.type.rawValue.capitalized)
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(6)
                    
                    Text(formatFileSize(model.modelSize))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if model.isLoaded || coreMLManager.loadedModels.keys.contains(model.id) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            } else {
                Button(model.isDownloadable ? "Download" : "Load") {
                    Task {
                        do {
                            _ = try await coreMLManager.loadModel(model.id)
                        } catch {
                            print("Failed to load model: \(error)")
                        }
                    }
                }
                .buttonStyle(.bordered)
                .font(.caption)
                .disabled(coreMLManager.isLoading)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
    }
    
    private func formatFileSize(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useKB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
}

// MARK: - Placeholder Views for Complex Components

private struct HabitPredictionView: View {
    @Binding var prediction: HabitPrediction?
    
    var body: some View {
        VStack {
            Text("Habit Success Prediction")
                .font(.headline)
            
            Button("Generate Prediction") {
                // Simulate prediction generation
                prediction = HabitPrediction(
                    successProbability: Double.random(in: 0.3 ... 0.9),
                    confidence: Double.random(in: 0.6 ... 0.95),
                    factors: [],
                    recommendations: ["Stay consistent", "Track progress daily"],
                    timestamp: Date()
                )
            }
            .buttonStyle(.bordered)
            
            if let pred = prediction {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Success Probability: \(Int(pred.successProbability * 100))%")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Confidence: \(Int(pred.confidence * 100))%")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(
            #if canImport(UIKit)
            Color(UIColor.systemBackground)
            #else
            Color(.controlBackgroundColor)
            #endif
        )
        .cornerRadius(12)
    }
}

private struct ExpensePredictionView: View {
    @Binding var prediction: ExpensePrediction?
    
    var body: some View {
        VStack {
            Text("Expense Category Prediction")
                .font(.headline)
            
            Button("Generate Prediction") {
                // Simulate prediction generation
                prediction = ExpensePrediction(
                    predictedCategory: "Food",
                    confidence: Double.random(in: 0.6 ... 0.95),
                    alternativeCategories: ["Food": 0.8, "Entertainment": 0.2],
                    reasoning: "Based on merchant patterns",
                    timestamp: Date()
                )
            }
            .buttonStyle(.bordered)
            
            if let pred = prediction {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Category: \(pred.predictedCategory)")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Confidence: \(Int(pred.confidence * 100))%")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(pred.reasoning)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(
            #if canImport(UIKit)
            Color(UIColor.systemBackground)
            #else
            Color(.controlBackgroundColor)
            #endif
        )
        .cornerRadius(12)
    }
}

private struct RecentPredictionsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Predictions")
                .font(.headline)
            
            Text("No recent predictions available")
                .foregroundColor(.secondary)
                .italic()
        }
        .padding()
        .background(
            #if canImport(UIKit)
            Color(UIColor.systemBackground)
            #else
            Color(.controlBackgroundColor)
            #endif
        )
        .cornerRadius(12)
    }
}

private struct ImagePickerView: View {
    let onImageSelected: (PlatformImage) -> Void
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack {
            Text("Image Picker Placeholder")
                .font(.headline)
            
            Text("In a real implementation, this would open the system image picker")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }
}

private struct ModelManagerView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var coreMLManager = CoreMLManager.shared
    
    var body: some View {
        NavigationView {
            List {
                Section("Available Models") {
                    ForEach(coreMLManager.availableModels) { model in
                        ModelCard(model: model)
                    }
                }
            }
            .navigationTitle("Model Manager")
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

// MARK: - AI Widget

@available(iOS 13.0, macOS 10.15, *)
public struct AIWidget: View {
    @StateObject private var aiCoordinator = AICoordinator.shared
    @State private var showingDashboard = false
    
    public init() {}
    
    public var body: some View {
        Button(action: {
            showingDashboard = true
        }) {
            HStack(spacing: 8) {
                Image(systemName: aiCoordinator.isInitialized ? "brain.head.profile" : "clock")
                    .foregroundColor(aiCoordinator.isInitialized ? .blue : .orange)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("AI System")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(aiCoordinator.isInitialized ? "Ready" : "Loading")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.primary)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingDashboard) {
            AIDashboard()
        }
    }
}
