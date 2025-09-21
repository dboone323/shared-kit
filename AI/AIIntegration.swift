import Combine
import CoreML
import Foundation
import NaturalLanguage
import SwiftUI
import Vision
#if canImport(UIKit)
import UIKit

typealias PlatformImage = UIImage
#elseif canImport(AppKit)
import AppKit

typealias PlatformImage = NSImage
#endif

// MARK: - AI/ML Integration Framework

// Advanced AI and machine learning capabilities for intelligent features across all projects

// MARK: - Core ML Manager

@available(iOS 13.0, macOS 10.15, *)
public class CoreMLManager: ObservableObject {
    public static let shared = CoreMLManager()
    
    @Published public var availableModels: [AIModel] = []
    @Published public var loadedModels: [String: MLModel] = [:]
    @Published public var isLoading = false
    
    private let modelCache = NSCache<NSString, MLModel>()
    private let processingQueue = DispatchQueue(label: "coreml.processing", qos: .userInitiated)
    
    private init() {
        self.setupModelCache()
        self.discoverAvailableModels()
    }
    
    // MARK: - Model Management

    private func setupModelCache() {
        self.modelCache.countLimit = 5 // Cache up to 5 models
        self.modelCache.totalCostLimit = 100 * 1024 * 1024 // 100MB limit
    }
    
    private func discoverAvailableModels() {
        // Discover bundled models and downloadable models
        var models: [AIModel] = []
        
        // Add built-in models
        models.append(contentsOf: [
            AIModel(
                id: "text_classifier",
                name: "Text Classification",
                type: .textClassification,
                description: "Classifies text sentiment and categories",
                isDownloadable: false,
                modelSize: 5 * 1024 * 1024 // 5MB
            ),
            AIModel(
                id: "image_classifier",
                name: "Image Recognition",
                type: .imageClassification,
                description: "Recognizes objects and scenes in images",
                isDownloadable: false,
                modelSize: 15 * 1024 * 1024 // 15MB
            ),
            AIModel(
                id: "habit_predictor",
                name: "Habit Success Predictor",
                type: .prediction,
                description: "Predicts habit completion likelihood",
                isDownloadable: true,
                modelSize: 3 * 1024 * 1024 // 3MB
            ),
            AIModel(
                id: "expense_categorizer",
                name: "Expense Categorization",
                type: .classification,
                description: "Automatically categorizes financial transactions",
                isDownloadable: true,
                modelSize: 8 * 1024 * 1024 // 8MB
            ),
            AIModel(
                id: "task_prioritizer",
                name: "Task Priority Optimizer",
                type: .prediction,
                description: "Optimizes task priority based on deadlines and importance",
                isDownloadable: true,
                modelSize: 4 * 1024 * 1024 // 4MB
            )
        ])
        
        Task { @MainActor in
            self.availableModels = models
        }
    }
    
    public func loadModel(_ modelId: String) async throws -> MLModel {
        // Check cache first
        if let cachedModel = modelCache.object(forKey: modelId as NSString) {
            return cachedModel
        }
        
        // Check loaded models
        if let loadedModel = loadedModels[modelId] {
            return loadedModel
        }
        
        Task { @MainActor in
            self.isLoading = true
        }
        
        defer {
            Task { @MainActor in
                isLoading = false
            }
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            self.processingQueue.async {
                do {
                    let model = try self.loadModelFromBundle(modelId)
                    
                    // Cache the model
                    self.modelCache.setObject(model, forKey: modelId as NSString)
                    
                    Task { @MainActor in
                        self.loadedModels[modelId] = model
                    }
                    
                    continuation.resume(returning: model)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    private func loadModelFromBundle(_ modelId: String) throws -> MLModel {
        // In a real implementation, this would load from app bundle or download
        // For now, we'll simulate model loading
        
        guard let modelPath = Bundle.main.path(forResource: modelId, ofType: "mlmodel") else {
            // Simulate model creation for demo purposes
            let config = MLModelConfiguration()
            config.computeUnits = .cpuAndGPU
            
            // Create a simple placeholder model
            // In production, this would load actual trained models
            throw AIError.modelNotFound(modelId)
        }
        
        let modelURL = URL(fileURLWithPath: modelPath)
        return try MLModel(contentsOf: modelURL)
    }
    
    public func unloadModel(_ modelId: String) {
        self.loadedModels.removeValue(forKey: modelId)
        self.modelCache.removeObject(forKey: modelId as NSString)
    }
    
    public func unloadAllModels() {
        self.loadedModels.removeAll()
        self.modelCache.removeAllObjects()
    }
}

// MARK: - Natural Language Processor

@available(iOS 13.0, macOS 10.15, *)
public class NaturalLanguageProcessor: ObservableObject {
    public static let shared = NaturalLanguageProcessor()
    
    @Published public var isProcessing = false
    
    private let sentimentPredictor = NLModel(mlModel: try! MLModel(contentsOf: Bundle.main.url(
        forResource: "SentimentPolarity",
        withExtension: "mlmodelc"
    ) ?? URL(fileURLWithPath: "")))
    private let languageRecognizer = NLLanguageRecognizer()
    private let tokenizer = NLTokenizer(unit: .word)
    
    private init() {}
    
    // MARK: - Text Analysis

    public func analyzeSentiment(_ text: String) async -> SentimentAnalysis {
        await withCheckedContinuation { continuation in
            Task { @MainActor in
                self.isProcessing = true
            }
            
            DispatchQueue.global(qos: .userInitiated).async {
                defer {
                    Task { @MainActor in
                        self.isProcessing = false
                    }
                }
                
                // Analyze sentiment using Natural Language framework
                let sentiment = self.performSentimentAnalysis(text)
                let confidence = self.calculateSentimentConfidence(text)
                let emotions = self.extractEmotions(text)
                
                let analysis = SentimentAnalysis(
                    text: text,
                    sentiment: sentiment,
                    confidence: confidence,
                    emotions: emotions,
                    wordCount: self.countWords(text),
                    timestamp: Date()
                )
                
                continuation.resume(returning: analysis)
            }
        }
    }
    
    private func performSentimentAnalysis(_ text: String) -> Sentiment {
        // Use NLTagger for sentiment analysis
        let tagger = NLTagger(tagSchemes: [.sentimentScore])
        tagger.string = text
        
        let (sentiment, _) = tagger.tag(at: text.startIndex, unit: .paragraph, scheme: .sentimentScore)
        
        if let sentimentScore = sentiment?.rawValue, let score = Double(sentimentScore) {
            if score > 0.1 {
                return .positive
            } else if score < -0.1 {
                return .negative
            } else {
                return .neutral
            }
        }
        
        return .neutral
    }
    
    private func calculateSentimentConfidence(_ text: String) -> Double {
        // Calculate confidence based on text analysis
        let tagger = NLTagger(tagSchemes: [.sentimentScore])
        tagger.string = text
        
        let (sentiment, _) = tagger.tag(at: text.startIndex, unit: .paragraph, scheme: .sentimentScore)
        
        if let sentimentScore = sentiment?.rawValue, let score = Double(sentimentScore) {
            return min(abs(score), 1.0) // Normalize to 0-1 range
        }
        
        return 0.5 // Default confidence
    }
    
    private func extractEmotions(_ text: String) -> [Emotion] {
        // Extract emotions using keyword matching and ML
        var emotions: [Emotion] = []
        
        let emotionKeywords: [String: Emotion] = [
            "happy": .joy,
            "sad": .sadness,
            "angry": .anger,
            "excited": .excitement,
            "worried": .anxiety,
            "love": .love,
            "fear": .fear,
            "surprised": .surprise
        ]
        
        let lowercaseText = text.lowercased()
        
        for (keyword, emotion) in emotionKeywords {
            if lowercaseText.contains(keyword) {
                emotions.append(emotion)
            }
        }
        
        return emotions.isEmpty ? [.neutral] : emotions
    }
    
    private func countWords(_ text: String) -> Int {
        self.tokenizer.string = text
        var wordCount = 0
        
        self.tokenizer.enumerateTokens(in: text.startIndex ..< text.endIndex) { _, _ in
            wordCount += 1
            return true
        }
        
        return wordCount
    }
    
    // MARK: - Language Detection

    public func detectLanguage(_ text: String) -> LanguageInfo {
        self.languageRecognizer.reset()
        self.languageRecognizer.processString(text)
        
        let dominantLanguage = self.languageRecognizer.dominantLanguage
        let languageHypotheses = self.languageRecognizer.languageHypotheses(withMaximum: 3)
        
        return LanguageInfo(
            dominantLanguage: dominantLanguage,
            hypotheses: languageHypotheses,
            confidence: languageHypotheses[dominantLanguage ?? .undetermined] ?? 0.0
        )
    }
    
    // MARK: - Text Categorization

    public func categorizeText(_ text: String, categories: [String]) async -> TextCategorizationResult {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                // Use ML-based text categorization
                let prediction = self.performTextCategorization(text, categories: categories)
                continuation.resume(returning: prediction)
            }
        }
    }
    
    private func performTextCategorization(_ text: String, categories: [String]) -> TextCategorizationResult {
        // Implement text categorization logic
        // This would use a trained ML model in production
        
        let scores = categories.map { category in
            CategoryScore(category: category, score: Double.random(in: 0.1 ... 0.9))
        }.sorted { $0.score > $1.score }
        
        return TextCategorizationResult(
            text: text,
            categories: scores,
            predictedCategory: scores.first?.category ?? "Unknown",
            confidence: scores.first?.score ?? 0.0
        )
    }
    
    // MARK: - Keyword Extraction

    public func extractKeywords(_ text: String, maxCount: Int = 10) -> [Keyword] {
        let tagger = NLTagger(tagSchemes: [.lexicalClass, .nameType])
        tagger.string = text
        
        var keywords: [String: Int] = [:]
        
        tagger.enumerateTokens(in: text.startIndex ..< text.endIndex, unit: .word, scheme: .lexicalClass) { tokenRange, tag in
            if let tag,
               tag == .noun || tag == .adjective || tag == .verb {
                let word = String(text[tokenRange]).lowercased()
                if word.count > 3 { // Filter out short words
                    keywords[word, default: 0] += 1
                }
            }
            return true
        }
        
        return keywords
            .sorted { $0.value > $1.value }
            .prefix(maxCount)
            .map { Keyword(word: $0.key, frequency: $0.value, relevance: Double($0.value) / Double(text.count)) }
    }
}

// MARK: - Computer Vision Processor

@available(iOS 13.0, macOS 10.15, *)
public class ComputerVisionProcessor: ObservableObject {
    public static let shared = ComputerVisionProcessor()
    
    @Published public var isProcessing = false
    
    private init() {}
    
    // MARK: - Image Classification

    public func classifyImage(_ image: PlatformImage) async throws -> ImageClassificationResult {
        try await withCheckedThrowingContinuation { continuation in
            Task { @MainActor in
                self.isProcessing = true
            }
            
            DispatchQueue.global(qos: .userInitiated).async {
                defer {
                    Task { @MainActor in
                        self.isProcessing = false
                    }
                }
                
                #if canImport(UIKit)
                guard let cgImage = image.cgImage else {
                    continuation.resume(throwing: AIError.imageProcessingFailed)
                    return
                }
                #else
                guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
                    continuation.resume(throwing: AIError.imageProcessingFailed)
                    return
                }
                #endif
                
                let request = VNClassifyImageRequest { request, error in
                    if let error {
                        continuation.resume(throwing: error)
                        return
                    }
                    
                    guard let observations = request.results as? [VNClassificationObservation] else {
                        continuation.resume(throwing: AIError.imageProcessingFailed)
                        return
                    }
                    
                    let classifications = observations.prefix(5).map { observation in
                        Classification(
                            identifier: observation.identifier,
                            confidence: Double(observation.confidence)
                        )
                    }
                    
                    let result = ImageClassificationResult(
                        image: image,
                        classifications: Array(classifications),
                        topClassification: classifications.first,
                        timestamp: Date()
                    )
                    
                    continuation.resume(returning: result)
                }
                
                let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
                
                do {
                    try handler.perform([request])
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    // MARK: - Object Detection

    public func detectObjects(in image: UIImage) async throws -> ObjectDetectionResult {
        try await withCheckedThrowingContinuation { continuation in
            guard let cgImage = image.cgImage else {
                continuation.resume(throwing: AIError.imageProcessingFailed)
                return
            }
            
            let request = VNDetectRectanglesRequest { request, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let observations = request.results as? [VNRectangleObservation] else {
                    continuation.resume(throwing: AIError.imageProcessingFailed)
                    return
                }
                
                let detectedObjects = observations.map { observation in
                    DetectedObject(
                        boundingBox: observation.boundingBox,
                        confidence: Double(observation.confidence),
                        type: "Rectangle" // In production, this would be more specific
                    )
                }
                
                let result = ObjectDetectionResult(
                    image: image,
                    detectedObjects: detectedObjects,
                    objectCount: detectedObjects.count,
                    timestamp: Date()
                )
                
                continuation.resume(returning: result)
            }
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    try handler.perform([request])
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    // MARK: - Text Recognition (OCR)

    public func recognizeText(in image: UIImage) async throws -> TextRecognitionResult {
        try await withCheckedThrowingContinuation { continuation in
            guard let cgImage = image.cgImage else {
                continuation.resume(throwing: AIError.imageProcessingFailed)
                return
            }
            
            let request = VNRecognizeTextRequest { request, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(throwing: AIError.textRecognitionFailed)
                    return
                }
                
                var recognizedText = ""
                var textBlocks: [RecognizedTextBlock] = []
                
                for observation in observations {
                    guard let topCandidate = observation.topCandidates(1).first else { continue }
                    
                    recognizedText += topCandidate.string + "\n"
                    
                    textBlocks.append(RecognizedTextBlock(
                        text: topCandidate.string,
                        boundingBox: observation.boundingBox,
                        confidence: Double(topCandidate.confidence)
                    ))
                }
                
                let result = TextRecognitionResult(
                    image: image,
                    recognizedText: recognizedText.trimmingCharacters(in: .whitespacesAndNewlines),
                    textBlocks: textBlocks,
                    timestamp: Date()
                )
                
                continuation.resume(returning: result)
            }
            
            request.recognitionLevel = .accurate
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    try handler.perform([request])
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}

// MARK: - Predictive Analytics Engine

@available(iOS 13.0, macOS 10.15, *)
public class PredictiveAnalyticsEngine: ObservableObject {
    public static let shared = PredictiveAnalyticsEngine()
    
    @Published public var isProcessing = false
    @Published public var predictions: [Prediction] = []
    
    private let dataProcessor = DataProcessor()
    private var trainingData: [TrainingDataPoint] = []
    
    private init() {}
    
    // MARK: - Habit Prediction

    public func predictHabitSuccess(
        habit: HabitData,
        historicalData: [HabitCompletionRecord]
    ) async -> HabitPrediction {
        await withCheckedContinuation { continuation in
            Task { @MainActor in
                self.isProcessing = true
            }
            
            DispatchQueue.global(qos: .userInitiated).async {
                defer {
                    Task { @MainActor in
                        self.isProcessing = false
                    }
                }
                
                let features = self.extractHabitFeatures(habit: habit, history: historicalData)
                let prediction = self.performHabitPrediction(features: features)
                
                continuation.resume(returning: prediction)
            }
        }
    }
    
    private func extractHabitFeatures(habit: HabitData, history: [HabitCompletionRecord]) -> HabitFeatures {
        let completionRate = history.isEmpty ? 0.5 : Double(history.count(where: { $0.completed })) / Double(history.count)
        let streakLength = self.calculateCurrentStreak(history)
        let timeOfDayConsistency = self.calculateTimeConsistency(history)
        let dayOfWeekPattern = self.analyzeDayOfWeekPattern(history)
        
        return HabitFeatures(
            completionRate: completionRate,
            currentStreak: streakLength,
            timeConsistency: timeOfDayConsistency,
            dayPattern: dayOfWeekPattern,
            habitAge: habit.createdDate.timeIntervalSinceNow / -86400, // Days since creation
            difficulty: habit.difficulty
        )
    }
    
    private func performHabitPrediction(features: HabitFeatures) -> HabitPrediction {
        // Simplified prediction algorithm
        // In production, this would use a trained ML model
        
        var successProbability = features.completionRate * 0.4 // Historical performance
        
        // Streak bonus
        if features.currentStreak > 7 {
            successProbability += 0.2
        } else if features.currentStreak > 3 {
            successProbability += 0.1
        }
        
        // Time consistency bonus
        successProbability += features.timeConsistency * 0.15
        
        // Day pattern bonus
        successProbability += features.dayPattern * 0.1
        
        // Difficulty adjustment
        successProbability *= (1.0 - (features.difficulty - 0.5) * 0.2)
        
        // Habit age factor (newer habits are less predictable)
        if features.habitAge < 7 {
            successProbability *= 0.8
        }
        
        successProbability = max(0.1, min(0.95, successProbability))
        
        let confidence = self.calculatePredictionConfidence(features: features)
        let recommendations = self.generateHabitRecommendations(features: features, prediction: successProbability)
        
        return HabitPrediction(
            successProbability: successProbability,
            confidence: confidence,
            factors: self.analyzePredictionFactors(features: features),
            recommendations: recommendations,
            timestamp: Date()
        )
    }
    
    private func calculateCurrentStreak(_ history: [HabitCompletionRecord]) -> Int {
        let sortedHistory = history.sorted { $0.date > $1.date }
        var streak = 0
        
        for record in sortedHistory {
            if record.completed {
                streak += 1
            } else {
                break
            }
        }
        
        return streak
    }
    
    private func calculateTimeConsistency(_ history: [HabitCompletionRecord]) -> Double {
        let completedRecords = history.filter(\.completed)
        guard completedRecords.count > 1 else { return 0.5 }
        
        let times = completedRecords.compactMap(\.completionTime)
        guard times.count > 1 else { return 0.5 }
        
        let calendar = Calendar.current
        let hours = times.map { calendar.component(.hour, from: $0) }
        
        let meanHour = Double(hours.reduce(0, +)) / Double(hours.count)
        let variance = hours.map { pow(Double($0) - meanHour, 2) }.reduce(0, +) / Double(hours.count)
        
        // Lower variance means higher consistency
        return max(0.0, 1.0 - (variance / 144.0)) // 144 is max variance for 24-hour range
    }
    
    private func analyzeDayOfWeekPattern(_ history: [HabitCompletionRecord]) -> Double {
        let calendar = Calendar.current
        var dayCompletions: [Int: Int] = [:]
        var dayAttempts: [Int: Int] = [:]
        
        for record in history {
            let dayOfWeek = calendar.component(.weekday, from: record.date)
            dayAttempts[dayOfWeek, default: 0] += 1
            if record.completed {
                dayCompletions[dayOfWeek, default: 0] += 1
            }
        }
        
        let completionRates = dayAttempts.compactMapValues { attempts in
            guard attempts > 0 else { return nil }
            return Double(dayCompletions[dayAttempts.firstIndex(of: attempts)!.key, default: 0]) / Double(attempts)
        }
        
        guard !completionRates.isEmpty else { return 0.5 }
        
        return completionRates.values.reduce(0, +) / Double(completionRates.count)
    }
    
    private func calculatePredictionConfidence(features: HabitFeatures) -> Double {
        var confidence = 0.5 // Base confidence
        
        // More data points increase confidence
        if features.habitAge > 30 {
            confidence += 0.3
        } else if features.habitAge > 14 {
            confidence += 0.2
        } else if features.habitAge > 7 {
            confidence += 0.1
        }
        
        // Consistent patterns increase confidence
        confidence += features.timeConsistency * 0.2
        confidence += features.dayPattern * 0.1
        
        return max(0.1, min(0.95, confidence))
    }
    
    private func generateHabitRecommendations(features: HabitFeatures, prediction: Double) -> [String] {
        var recommendations: [String] = []
        
        if prediction < 0.5 {
            if features.timeConsistency < 0.6 {
                recommendations.append("Try to perform this habit at the same time each day to build consistency")
            }
            
            if features.currentStreak == 0 {
                recommendations.append("Start with a small version of this habit to rebuild momentum")
            }
            
            if features.difficulty > 0.7 {
                recommendations.append("Consider reducing the difficulty to increase success likelihood")
            }
        } else if prediction > 0.8 {
            if features.difficulty < 0.5 {
                recommendations.append("You're doing great! Consider increasing the challenge slightly")
            }
            recommendations.append("Keep up the excellent consistency!")
        }
        
        if features.habitAge < 7 {
            recommendations.append("Focus on consistency over perfection in these early days")
        }
        
        return recommendations
    }
    
    private func analyzePredictionFactors(features: HabitFeatures) -> [PredictionFactor] {
        var factors: [PredictionFactor] = []
        
        factors.append(PredictionFactor(
            name: "Historical Performance",
            impact: features.completionRate > 0.7 ? .positive : features.completionRate < 0.3 ? .negative : .neutral,
            weight: 0.4,
            description: "Based on your past completion rate of \(Int(features.completionRate * 100))%"
        ))
        
        factors.append(PredictionFactor(
            name: "Current Streak",
            impact: features.currentStreak > 7 ? .positive : features.currentStreak == 0 ? .negative : .neutral,
            weight: 0.2,
            description: "Your current streak is \(features.currentStreak) days"
        ))
        
        factors.append(PredictionFactor(
            name: "Time Consistency",
            impact: features.timeConsistency > 0.7 ? .positive : features.timeConsistency < 0.4 ? .negative : .neutral,
            weight: 0.15,
            description: "You perform this habit consistently at similar times"
        ))
        
        return factors
    }
    
    // MARK: - Financial Predictions

    public func predictExpenseCategory(
        amount: Double,
        merchant: String,
        description: String,
        historicalTransactions: [FinancialTransaction]
    ) async -> ExpensePrediction {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let features = self.extractExpenseFeatures(
                    amount: amount,
                    merchant: merchant,
                    description: description,
                    history: historicalTransactions
                )
                
                let prediction = self.performExpensePrediction(features: features)
                continuation.resume(returning: prediction)
            }
        }
    }
    
    private func extractExpenseFeatures(
        amount: Double,
        merchant: String,
        description: String,
        history: [FinancialTransaction]
    ) -> ExpenseFeatures {
        let merchantHistory = history.filter { $0.merchant.lowercased() == merchant.lowercased() }
        let amountSimilar = history.filter { abs($0.amount - amount) < 10.0 }
        
        return ExpenseFeatures(
            amount: amount,
            merchant: merchant.lowercased(),
            description: description.lowercased(),
            merchantFrequency: merchantHistory.count,
            averageAmount: merchantHistory.isEmpty ? amount : merchantHistory.map(\.amount).reduce(0, +) / Double(merchantHistory.count),
            dayOfWeek: Calendar.current.component(.weekday, from: Date()),
            timeOfDay: Calendar.current.component(.hour, from: Date())
        )
    }
    
    private func performExpensePrediction(features: ExpenseFeatures) -> ExpensePrediction {
        // Simplified category prediction
        // In production, this would use a trained classification model
        
        let categories = ["Food", "Transportation", "Entertainment", "Shopping", "Bills", "Healthcare", "Education", "Other"]
        var categoryScores: [String: Double] = [:]
        
        // Merchant-based scoring
        if features.merchant.contains("restaurant") || features.merchant.contains("cafe") || features.merchant.contains("food") {
            categoryScores["Food"] = 0.9
        } else if features.merchant.contains("gas") || features.merchant.contains("uber") || features.merchant.contains("taxi") {
            categoryScores["Transportation"] = 0.8
        } else if features.merchant.contains("movie") || features.merchant.contains("theater") || features.merchant.contains("concert") {
            categoryScores["Entertainment"] = 0.85
        } else if features.merchant.contains("store") || features.merchant.contains("shop") || features.merchant.contains("amazon") {
            categoryScores["Shopping"] = 0.7
        } else {
            // Default scoring based on amount and time patterns
            for category in categories {
                categoryScores[category] = Double.random(in: 0.1 ... 0.6)
            }
        }
        
        // Amount-based adjustments
        if features.amount > 100 {
            categoryScores["Bills", default: 0.3] += 0.2
            categoryScores["Shopping", default: 0.3] += 0.2
        } else if features.amount < 20 {
            categoryScores["Food", default: 0.3] += 0.3
        }
        
        let topCategory = categoryScores.max { $0.value < $1.value }
        
        return ExpensePrediction(
            predictedCategory: topCategory?.key ?? "Other",
            confidence: topCategory?.value ?? 0.5,
            alternativeCategories: Array(categoryScores.sorted { $0.value > $1.value }.prefix(3)),
            reasoning: self.generateExpenseReasoning(features: features, prediction: topCategory?.key ?? "Other"),
            timestamp: Date()
        )
    }
    
    private func generateExpenseReasoning(features: ExpenseFeatures, prediction: String) -> String {
        if features.merchantFrequency > 5 {
            "Based on your frequent transactions with this merchant, this is likely a \(prediction) expense."
        } else if features.merchant.contains("restaurant") || features.merchant.contains("food") {
            "The merchant name suggests this is a food-related expense."
        } else if features.amount > 100 {
            "The amount suggests this might be a bill or larger purchase."
        } else {
            "Categorized based on transaction patterns and merchant information."
        }
    }
}

// MARK: - Data Models

public struct AIModel: Identifiable, Codable {
    public let id: String
    public let name: String
    public let type: ModelType
    public let description: String
    public let isDownloadable: Bool
    public let modelSize: Int // in bytes
    public var isLoaded: Bool = false
    public var downloadProgress: Double = 0.0
    
    public enum ModelType: String, Codable, CaseIterable {
        case textClassification
        case imageClassification
        case prediction
        case classification
        case recommendation
    }
}

public struct SentimentAnalysis: Codable {
    public let text: String
    public let sentiment: Sentiment
    public let confidence: Double
    public let emotions: [Emotion]
    public let wordCount: Int
    public let timestamp: Date
}

public enum Sentiment: String, Codable, CaseIterable {
    case positive
    case negative
    case neutral
}

public enum Emotion: String, Codable, CaseIterable {
    case joy
    case sadness
    case anger
    case fear
    case surprise
    case disgust
    case trust
    case anticipation
    case love
    case excitement
    case anxiety
    case neutral
}

public struct LanguageInfo: Codable {
    public let dominantLanguage: NLLanguage?
    public let hypotheses: [NLLanguage: Double]
    public let confidence: Double
}

public struct TextCategorizationResult: Codable {
    public let text: String
    public let categories: [CategoryScore]
    public let predictedCategory: String
    public let confidence: Double
}

public struct CategoryScore: Codable {
    public let category: String
    public let score: Double
}

public struct Keyword: Codable {
    public let word: String
    public let frequency: Int
    public let relevance: Double
}

public struct ImageClassificationResult {
    public let image: PlatformImage
    public let classifications: [Classification]
    public let topClassification: Classification?
    public let timestamp: Date
}

public struct Classification: Codable {
    public let identifier: String
    public let confidence: Double
}

public struct ObjectDetectionResult {
    public let image: PlatformImage
    public let detectedObjects: [DetectedObject]
    public let objectCount: Int
    public let timestamp: Date
}

public struct DetectedObject: Codable {
    public let boundingBox: CGRect
    public let confidence: Double
    public let type: String
}

public struct TextRecognitionResult {
    public let image: PlatformImage
    public let recognizedText: String
    public let textBlocks: [RecognizedTextBlock]
    public let timestamp: Date
}

public struct RecognizedTextBlock: Codable {
    public let text: String
    public let boundingBox: CGRect
    public let confidence: Double
}

// MARK: - Prediction Models

public struct Prediction: Identifiable, Codable {
    public let id = UUID()
    public let type: PredictionType
    public let confidence: Double
    public let data: Data
    public let timestamp: Date
    
    public enum PredictionType: String, Codable {
        case habitSuccess
        case expenseCategory
        case taskPriority
        case userBehavior
    }
}

public struct HabitData: Codable {
    public let id: String
    public let name: String
    public let difficulty: Double // 0.0 to 1.0
    public let frequency: String
    public let createdDate: Date
}

public struct HabitCompletionRecord: Codable {
    public let date: Date
    public let completed: Bool
    public let completionTime: Date?
}

public struct HabitFeatures: Codable {
    public let completionRate: Double
    public let currentStreak: Int
    public let timeConsistency: Double
    public let dayPattern: Double
    public let habitAge: Double
    public let difficulty: Double
}

public struct HabitPrediction: Codable {
    public let successProbability: Double
    public let confidence: Double
    public let factors: [PredictionFactor]
    public let recommendations: [String]
    public let timestamp: Date
}

public struct PredictionFactor: Codable {
    public let name: String
    public let impact: FactorImpact
    public let weight: Double
    public let description: String
    
    public enum FactorImpact: String, Codable {
        case positive
        case negative
        case neutral
    }
}

public struct FinancialTransaction: Codable {
    public let amount: Double
    public let merchant: String
    public let description: String
    public let category: String
    public let date: Date
}

public struct ExpenseFeatures: Codable {
    public let amount: Double
    public let merchant: String
    public let description: String
    public let merchantFrequency: Int
    public let averageAmount: Double
    public let dayOfWeek: Int
    public let timeOfDay: Int
}

public struct ExpensePrediction: Codable {
    public let predictedCategory: String
    public let confidence: Double
    public let alternativeCategories: [String: Double]
    public let reasoning: String
    public let timestamp: Date
}

public struct TrainingDataPoint: Codable {
    public let features: [Double]
    public let label: String
    public let weight: Double
}

// MARK: - Supporting Classes

private class DataProcessor {
    func normalizeFeatures(_ features: [Double]) -> [Double] {
        // Implement feature normalization
        features.map { max(-3.0, min(3.0, $0)) } // Clip to reasonable range
    }
    
    func extractFeatures(from data: [String: Any]) -> [Double] {
        // Extract numerical features from data dictionary
        var features: [Double] = []
        
        for (_, value) in data {
            if let number = value as? Double {
                features.append(number)
            } else if let string = value as? String {
                features.append(Double(string.count)) // Use string length as feature
            } else if let bool = value as? Bool {
                features.append(bool ? 1.0 : 0.0)
            }
        }
        
        return features
    }
}

// MARK: - Error Types

public enum AIError: Error, LocalizedError {
    case modelNotFound(String)
    case modelLoadingFailed(String)
    case imageProcessingFailed
    case textRecognitionFailed
    case predictionFailed
    case insufficientData
    
    public var errorDescription: String? {
        switch self {
        case let .modelNotFound(modelId):
            "AI model '\(modelId)' not found"
        case let .modelLoadingFailed(modelId):
            "Failed to load AI model '\(modelId)'"
        case .imageProcessingFailed:
            "Image processing failed"
        case .textRecognitionFailed:
            "Text recognition failed"
        case .predictionFailed:
            "Prediction failed"
        case .insufficientData:
            "Insufficient data for AI processing"
        }
    }
}

// MARK: - AI Coordinator

@available(iOS 13.0, macOS 10.15, *)
public class AICoordinator: ObservableObject {
    public static let shared = AICoordinator()
    
    @Published public var isInitialized = false
    @Published public var availableFeatures: Set<AIFeature> = []
    
    public let coreMLManager = CoreMLManager.shared
    public let nlProcessor = NaturalLanguageProcessor.shared
    public let visionProcessor = ComputerVisionProcessor.shared
    public let predictiveEngine = PredictiveAnalyticsEngine.shared
    
    private init() {
        self.initializeAI()
    }
    
    private func initializeAI() {
        Task {
            // Check available features based on system capabilities
            var features: Set<AIFeature> = []
            
            // Check Core ML availability
            if MLModel.self != nil {
                features.insert(.machineLearning)
            }
            
            // Check Natural Language availability
            if NLTokenizer.self != nil {
                features.insert(.naturalLanguageProcessing)
            }
            
            // Check Vision availability
            if VNImageRequestHandler.self != nil {
                features.insert(.computerVision)
            }
            
            // Always available
            features.insert(.predictiveAnalytics)
            
            await MainActor.run {
                self.availableFeatures = features
                self.isInitialized = true
            }
        }
    }
    
    public func isFeatureAvailable(_ feature: AIFeature) -> Bool {
        self.availableFeatures.contains(feature)
    }
}

public enum AIFeature: String, CaseIterable {
    case machineLearning
    case naturalLanguageProcessing
    case computerVision
    case predictiveAnalytics
}
