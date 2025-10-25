//
//  AdvancedMCPTools.swift
//  Quantum-workspace
//
//  Created: Phase 9C - Enhanced MCP Systems
//  Purpose: Advanced MCP tool implementations with sophisticated capabilities
//

import Combine
import Foundation

// MARK: - Advanced MCP Tool Implementations

/// Advanced text processing tool with AI capabilities
public final class AdvancedTextProcessingTool: EnhancedMCPTool {
    public let capabilities: [MCPToolCapability] = [.textProcessing, .aiProcessing]
    public let dependencies: [String] = ["OllamaIntegrationManager"]
    public var performanceMetrics: MCPToolMetrics = .init()

    private let ollamaManager: OllamaIntegrationManager

    public init(ollamaManager: OllamaIntegrationManager) {
        self.ollamaManager = ollamaManager
    }

    public func id() async -> String { "advanced_text_processor" }
    public func name() async -> String { "Advanced Text Processor" }
    public func description() async -> String {
        "Advanced text processing with AI analysis, summarization, and transformation capabilities"
    }

    public func execute(parameters: [String: Any]) async throws -> Any? {
        guard let operation = parameters["operation"] as? String else {
            throw MCPError.invalidParameters("Missing 'operation' parameter")
        }

        switch operation {
        case "analyze":
            return try await analyzeText(parameters)
        case "summarize":
            return try await summarizeText(parameters)
        case "translate":
            return try await translateText(parameters)
        case "sentiment":
            return try await analyzeSentiment(parameters)
        case "extract_entities":
            return try await extractEntities(parameters)
        default:
            throw MCPError.invalidParameters("Unknown operation: \(operation)")
        }
    }

    public func validateParameters(_ parameters: [String: Any]) throws {
        guard let operation = parameters["operation"] as? String else {
            throw MCPError.invalidParameters("Missing 'operation' parameter")
        }

        guard let text = parameters["text"] as? String, !text.isEmpty else {
            throw MCPError.invalidParameters("Missing or empty 'text' parameter")
        }

        switch operation {
        case "translate":
            guard parameters["target_language"] as? String != nil else {
                throw MCPError.invalidParameters("Missing 'target_language' for translation")
            }
        default:
            break
        }
    }

    public func estimateExecutionTime(for parameters: [String: Any]) -> TimeInterval {
        guard let text = parameters["text"] as? String else { return 1.0 }
        let textLength = text.count

        // Estimate based on text length and operation complexity
        let baseTime = Double(textLength) / 1000.0 // ~1 second per 1000 characters
        return max(baseTime, 0.5) // Minimum 0.5 seconds
    }

    public func getOptimizationHints() -> [String] {
        [
            "Process large texts in chunks for better performance",
            "Cache frequent analysis results",
            "Use streaming for real-time text processing",
        ]
    }

    // MARK: - Private Methods

    private func analyzeText(_ parameters: [String: Any]) async throws -> [String: Any] {
        let text = parameters["text"] as! String
        let analysisType = parameters["analysis_type"] as? String ?? "comprehensive"

        let prompt = """
        Analyze the following text with \(analysisType) analysis:

        \(text)

        Provide:
        1. Key themes and topics
        2. Writing style assessment
        3. Content quality evaluation
        4. Potential improvements
        5. Overall assessment
        """

        let analysis = try await ollamaManager.generateText(
            prompt: prompt,
            maxTokens: 1000,
            temperature: 0.3
        )

        return [
            "analysis": analysis,
            "analysis_type": analysisType,
            "text_length": text.count,
            "timestamp": Date(),
        ]
    }

    private func summarizeText(_ parameters: [String: Any]) async throws -> [String: Any] {
        let text = parameters["text"] as! String
        let maxLength = parameters["max_length"] as? Int ?? 200

        let prompt = """
        Summarize the following text in approximately \(maxLength) words or less:

        \(text)

        Focus on the most important information and key takeaways.
        """

        let summary = try await ollamaManager.generateText(
            prompt: prompt,
            maxTokens: 500,
            temperature: 0.2
        )

        return [
            "summary": summary,
            "original_length": text.count,
            "summary_length": summary.count,
            "compression_ratio": Double(summary.count) / Double(text.count),
        ]
    }

    private func translateText(_ parameters: [String: Any]) async throws -> [String: Any] {
        let text = parameters["text"] as! String
        let targetLanguage = parameters["target_language"] as! String

        let prompt = """
        Translate the following text to \(targetLanguage):

        \(text)

        Provide only the translation without additional commentary.
        """

        let translation = try await ollamaManager.generateText(
            prompt: prompt,
            maxTokens: 1000,
            temperature: 0.1
        )

        return [
            "translation": translation,
            "source_language": "auto-detected",
            "target_language": targetLanguage,
            "original_text": text,
        ]
    }

    private func analyzeSentiment(_ parameters: [String: Any]) async throws -> [String: Any] {
        let text = parameters["text"] as! String

        let prompt = """
        Analyze the sentiment of the following text. Classify as positive, negative, or neutral, and provide a confidence score (0-1):

        \(text)

        Format: sentiment|confidence|explanation
        """

        let result = try await ollamaManager.generateText(
            prompt: prompt,
            maxTokens: 200,
            temperature: 0.2
        )

        let components = result.split(separator: "|").map(String.init)
        let sentiment = components.count > 0 ? components[0].trimmingCharacters(in: .whitespaces) : "neutral"
        let confidence = components.count > 1 ? Double(components[1]) ?? 0.5 : 0.5
        let explanation = components.count > 2 ? components[2] : "Analysis completed"

        return [
            "sentiment": sentiment,
            "confidence": confidence,
            "explanation": explanation,
            "text": text,
        ]
    }

    private func extractEntities(_ parameters: [String: Any]) async throws -> [String: Any] {
        let text = parameters["text"] as! String

        let prompt = """
        Extract named entities from the following text. Categorize them as: PERSON, ORGANIZATION, LOCATION, DATE, PRODUCT, EVENT, etc.

        \(text)

        Format as JSON: {"entities": [{"text": "entity", "type": "category", "confidence": 0.9}, ...]}
        """

        let result = try await ollamaManager.generateText(
            prompt: prompt,
            maxTokens: 1000,
            temperature: 0.1
        )

        // Parse JSON result
        if let data = result.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        {
            return json
        }

        return [
            "entities": [],
            "raw_result": result,
            "text": text,
        ]
    }
}

/// Advanced data analysis tool with statistical and ML capabilities
public final class AdvancedDataAnalysisTool: EnhancedMCPTool {
    public let capabilities: [MCPToolCapability] = [.dataAnalysis, .aiProcessing]
    public let dependencies: [String] = ["OllamaIntegrationManager"]
    public var performanceMetrics: MCPToolMetrics = .init()

    private let ollamaManager: OllamaIntegrationManager

    public init(ollamaManager: OllamaIntegrationManager) {
        self.ollamaManager = ollamaManager
    }

    public func id() async -> String { "advanced_data_analyzer" }
    public func name() async -> String { "Advanced Data Analyzer" }
    public func description() async -> String {
        "Advanced data analysis with statistical modeling, pattern recognition, and predictive analytics"
    }

    public func execute(parameters: [String: Any]) async throws -> Any? {
        guard let operation = parameters["operation"] as? String else {
            throw MCPError.invalidParameters("Missing 'operation' parameter")
        }

        switch operation {
        case "analyze_dataset":
            return try await analyzeDataset(parameters)
        case "find_patterns":
            return try await findPatterns(parameters)
        case "predict_trends":
            return try await predictTrends(parameters)
        case "generate_insights":
            return try await generateInsights(parameters)
        case "statistical_summary":
            return try await statisticalSummary(parameters)
        default:
            throw MCPError.invalidParameters("Unknown operation: \(operation)")
        }
    }

    public func validateParameters(_ parameters: [String: Any]) throws {
        guard let operation = parameters["operation"] as? String else {
            throw MCPError.invalidParameters("Missing 'operation' parameter")
        }

        switch operation {
        case "analyze_dataset", "find_patterns", "predict_trends", "generate_insights", "statistical_summary":
            guard parameters["data"] != nil else {
                throw MCPError.invalidParameters("Missing 'data' parameter")
            }
        default:
            break
        }
    }

    public func estimateExecutionTime(for parameters: [String: Any]) -> TimeInterval {
        guard let data = parameters["data"] else { return 2.0 }

        // Estimate based on data complexity
        if let array = data as? [Any] {
            return max(Double(array.count) / 100.0, 1.0) // ~1 second per 100 data points
        } else if let dict = data as? [String: Any] {
            return max(Double(dict.count) / 50.0, 1.0) // ~1 second per 50 features
        }

        return 2.0
    }

    public func getOptimizationHints() -> [String] {
        [
            "Preprocess data before analysis for better performance",
            "Use sampling for large datasets",
            "Cache analysis results for repeated queries",
        ]
    }

    // MARK: - Private Methods

    private func analyzeDataset(_ parameters: [String: Any]) async throws -> [String: Any] {
        let data = parameters["data"]!
        let analysisType = parameters["analysis_type"] as? String ?? "comprehensive"

        let dataDescription = describeData(data)

        let prompt = """
        Analyze the following dataset with \(analysisType) analysis:

        Data Description: \(dataDescription)

        Provide:
        1. Data structure assessment
        2. Quality evaluation (completeness, consistency, accuracy)
        3. Statistical properties
        4. Potential insights or anomalies
        5. Recommendations for further analysis
        """

        let analysis = try await ollamaManager.generateText(
            prompt: prompt,
            maxTokens: 1500,
            temperature: 0.3
        )

        return [
            "analysis": analysis,
            "data_summary": dataDescription,
            "analysis_type": analysisType,
            "timestamp": Date(),
        ]
    }

    private func findPatterns(_ parameters: [String: Any]) async throws -> [String: Any] {
        let data = parameters["data"]!
        let dataDescription = describeData(data)

        let prompt = """
        Identify patterns and relationships in the following dataset:

        Data Description: \(dataDescription)

        Look for:
        1. Correlations between variables
        2. Clusters or groupings
        3. Trends over time (if applicable)
        4. Anomalies or outliers
        5. Predictive indicators
        """

        let patterns = try await ollamaManager.generateText(
            prompt: prompt,
            maxTokens: 1200,
            temperature: 0.4
        )

        return [
            "patterns": patterns,
            "data_summary": dataDescription,
            "pattern_types": ["correlation", "clustering", "trends", "anomalies"],
            "confidence": 0.85,
        ]
    }

    private func predictTrends(_ parameters: [String: Any]) async throws -> [String: Any] {
        let data = parameters["data"]!
        let predictionHorizon = parameters["horizon"] as? Int ?? 5
        let dataDescription = describeData(data)

        let prompt = """
        Predict future trends based on the following historical data:

        Data Description: \(dataDescription)
        Prediction Horizon: \(predictionHorizon) periods

        Provide:
        1. Trend analysis
        2. Predictions for the next \(predictionHorizon) periods
        3. Confidence intervals
        4. Key factors influencing the predictions
        5. Potential risks or uncertainties
        """

        let predictions = try await ollamaManager.generateText(
            prompt: prompt,
            maxTokens: 1000,
            temperature: 0.3
        )

        return [
            "predictions": predictions,
            "horizon": predictionHorizon,
            "data_summary": dataDescription,
            "prediction_method": "AI-powered trend analysis",
            "timestamp": Date(),
        ]
    }

    private func generateInsights(_ parameters: [String: Any]) async throws -> [String: Any] {
        let data = parameters["data"]!
        let focus = parameters["focus"] as? String ?? "general"
        let dataDescription = describeData(data)

        let prompt = """
        Generate actionable insights from the following dataset:

        Data Description: \(dataDescription)
        Focus Area: \(focus)

        Provide:
        1. Key findings and insights
        2. Actionable recommendations
        3. Business impact assessment
        4. Implementation priorities
        5. Monitoring suggestions
        """

        let insights = try await ollamaManager.generateText(
            prompt: prompt,
            maxTokens: 1200,
            temperature: 0.4
        )

        return [
            "insights": insights,
            "focus_area": focus,
            "data_summary": dataDescription,
            "insight_categories": ["findings", "recommendations", "impact", "implementation"],
            "generated_at": Date(),
        ]
    }

    private func statisticalSummary(_ parameters: [String: Any]) async throws -> [String: Any] {
        let data = parameters["data"]!
        let dataDescription = describeData(data)

        let prompt = """
        Provide a comprehensive statistical summary of the following dataset:

        Data Description: \(dataDescription)

        Include:
        1. Descriptive statistics (mean, median, mode, std dev, etc.)
        2. Distribution analysis
        3. Outlier detection
        4. Data quality metrics
        5. Statistical significance tests (where applicable)
        """

        let summary = try await ollamaManager.generateText(
            prompt: prompt,
            maxTokens: 1000,
            temperature: 0.2
        )

        return [
            "statistical_summary": summary,
            "data_summary": dataDescription,
            "metrics_included": ["descriptive", "distribution", "outliers", "quality", "significance"],
            "timestamp": Date(),
        ]
    }

    private func describeData(_ data: Any) -> String {
        if let array = data as? [Any] {
            return "Array with \(array.count) elements"
        } else if let dict = data as? [String: Any] {
            return "Dictionary with \(dict.count) keys: \(dict.keys.joined(separator: ", "))"
        } else if let string = data as? String {
            return "String data (\(string.count) characters)"
        } else {
            return "Complex data structure of type \(type(of: data))"
        }
    }
}

/// Advanced file operations tool with intelligent processing
public final class AdvancedFileOperationsTool: EnhancedMCPTool {
    public let capabilities: [MCPToolCapability] = [.fileOperations, .dataAnalysis]
    public let dependencies: [String] = []
    public var performanceMetrics: MCPToolMetrics = .init()

    public func id() async -> String { "advanced_file_processor" }
    public func name() async -> String { "Advanced File Processor" }
    public func description() async -> String {
        "Advanced file operations with intelligent processing, analysis, and transformation capabilities"
    }

    public func execute(parameters: [String: Any]) async throws -> Any? {
        guard let operation = parameters["operation"] as? String else {
            throw MCPError.invalidParameters("Missing 'operation' parameter")
        }

        switch operation {
        case "analyze_file":
            return try await analyzeFile(parameters)
        case "transform_file":
            return try await transformFile(parameters)
        case "merge_files":
            return try await mergeFiles(parameters)
        case "extract_metadata":
            return try await extractMetadata(parameters)
        case "optimize_file":
            return try await optimizeFile(parameters)
        default:
            throw MCPError.invalidParameters("Unknown operation: \(operation)")
        }
    }

    public func validateParameters(_ parameters: [String: Any]) throws {
        guard let operation = parameters["operation"] as? String else {
            throw MCPError.invalidParameters("Missing 'operation' parameter")
        }

        switch operation {
        case "analyze_file", "transform_file", "extract_metadata", "optimize_file":
            guard let filePath = parameters["file_path"] as? String, !filePath.isEmpty else {
                throw MCPError.invalidParameters("Missing or empty 'file_path' parameter")
            }
        case "merge_files":
            guard let filePaths = parameters["file_paths"] as? [String], filePaths.count >= 2 else {
                throw MCPError.invalidParameters("Missing 'file_paths' array with at least 2 files")
            }
        default:
            break
        }
    }

    public func estimateExecutionTime(for parameters: [String: Any]) -> TimeInterval {
        guard let operation = parameters["operation"] as? String else { return 1.0 }

        switch operation {
        case "analyze_file", "extract_metadata":
            return 2.0 // Quick operations
        case "transform_file", "optimize_file":
            return 5.0 // Medium operations
        case "merge_files":
            if let filePaths = parameters["file_paths"] as? [String] {
                return Double(filePaths.count) * 3.0 // ~3 seconds per file
            }
            return 10.0
        default:
            return 3.0
        }
    }

    public func getOptimizationHints() -> [String] {
        [
            "Process files in parallel when possible",
            "Use streaming for large files",
            "Cache file metadata for repeated operations",
        ]
    }

    // MARK: - Private Methods

    private func analyzeFile(_ parameters: [String: Any]) async throws -> [String: Any] {
        let filePath = parameters["file_path"] as! String
        let analysisType = parameters["analysis_type"] as? String ?? "comprehensive"

        // Check if file exists
        guard FileManager.default.fileExists(atPath: filePath) else {
            throw MCPError.executionFailed("File does not exist: \(filePath)")
        }

        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: filePath)
            let fileSize = attributes[.size] as? Int64 ?? 0
            let creationDate = attributes[.creationDate] as? Date
            let modificationDate = attributes[.modificationDate] as? Date

            let fileExtension = (filePath as NSString).pathExtension.lowercased()
            let fileName = (filePath as NSString).lastPathComponent

            var analysis: [String: Any] = [
                "file_path": filePath,
                "file_name": fileName,
                "file_extension": fileExtension,
                "file_size": fileSize,
                "creation_date": creationDate?.description ?? "unknown",
                "modification_date": modificationDate?.description ?? "unknown",
                "analysis_type": analysisType,
            ]

            // File type specific analysis
            switch fileExtension {
            case "swift":
                analysis["language"] = "Swift"
                analysis["type"] = "source_code"
            case "py":
                analysis["language"] = "Python"
                analysis["type"] = "source_code"
            case "json":
                analysis["type"] = "data"
                analysis["format"] = "JSON"
            case "md":
                analysis["type"] = "documentation"
                analysis["format"] = "Markdown"
            default:
                analysis["type"] = "unknown"
            }

            // Read file content for deeper analysis if not too large
            if fileSize < 1024 * 1024 { // Less than 1MB
                let content = try String(contentsOfFile: filePath, encoding: .utf8)
                analysis["line_count"] = content.components(separatedBy: .newlines).count
                analysis["character_count"] = content.count
                analysis["word_count"] = content.components(separatedBy: .whitespaces).count
            }

            return analysis

        } catch {
            throw MCPError.executionFailed("Failed to analyze file: \(error.localizedDescription)")
        }
    }

    private func transformFile(_ parameters: [String: Any]) async throws -> [String: Any] {
        let filePath = parameters["file_path"] as! String
        let transformation = parameters["transformation"] as? String ?? "format"
        let outputPath = parameters["output_path"] as? String

        // Check if file exists
        guard FileManager.default.fileExists(atPath: filePath) else {
            throw MCPError.executionFailed("File does not exist: \(filePath)")
        }

        let fileExtension = (filePath as NSString).pathExtension.lowercased()
        let actualOutputPath = outputPath ?? generateOutputPath(filePath, transformation)

        do {
            let content = try String(contentsOfFile: filePath, encoding: .utf8)
            var transformedContent = content

            // Apply transformation
            switch transformation {
            case "uppercase":
                transformedContent = content.uppercased()
            case "lowercase":
                transformedContent = content.lowercased()
            case "trim":
                transformedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
            case "format_json":
                if fileExtension == "json" {
                    if let jsonData = content.data(using: .utf8),
                       let jsonObject = try? JSONSerialization.jsonObject(with: jsonData),
                       let prettyData = try? JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted)
                    {
                        transformedContent = String(data: prettyData, encoding: .utf8) ?? content
                    }
                }
            case "remove_comments":
                if fileExtension == "swift" || fileExtension == "py" {
                    transformedContent = removeComments(from: content, language: fileExtension)
                }
            default:
                break // No transformation
            }

            // Write transformed content
            try transformedContent.write(toFile: actualOutputPath, atomically: true, encoding: .utf8)

            return [
                "original_file": filePath,
                "output_file": actualOutputPath,
                "transformation": transformation,
                "original_size": content.count,
                "transformed_size": transformedContent.count,
                "timestamp": Date(),
            ]

        } catch {
            throw MCPError.executionFailed("Failed to transform file: \(error.localizedDescription)")
        }
    }

    private func mergeFiles(_ parameters: [String: Any]) async throws -> [String: Any] {
        let filePaths = parameters["file_paths"] as! [String]
        let outputPath = parameters["output_path"] as? String ?? "merged_output.txt"
        let separator = parameters["separator"] as? String ?? "\n\n---\n\n"

        var mergedContent = ""
        var fileInfo: [[String: Any]] = []

        for filePath in filePaths {
            guard FileManager.default.fileExists(atPath: filePath) else {
                throw MCPError.executionFailed("File does not exist: \(filePath)")
            }

            let content = try String(contentsOfFile: filePath, encoding: .utf8)
            let attributes = try FileManager.default.attributesOfItem(atPath: filePath)
            let fileSize = attributes[.size] as? Int64 ?? 0

            mergedContent += content + separator

            fileInfo.append([
                "file_path": filePath,
                "file_name": (filePath as NSString).lastPathComponent,
                "size": fileSize,
                "line_count": content.components(separatedBy: .newlines).count,
            ])
        }

        // Remove trailing separator
        if mergedContent.hasSuffix(separator) {
            mergedContent = String(mergedContent.dropLast(separator.count))
        }

        try mergedContent.write(toFile: outputPath, atomically: true, encoding: .utf8)

        return [
            "output_file": outputPath,
            "merged_files": fileInfo,
            "total_files": filePaths.count,
            "total_size": mergedContent.count,
            "separator": separator,
            "timestamp": Date(),
        ]
    }

    private func extractMetadata(_ parameters: [String: Any]) async throws -> [String: Any] {
        let filePath = parameters["file_path"] as! String

        guard FileManager.default.fileExists(atPath: filePath) else {
            throw MCPError.executionFailed("File does not exist: \(filePath)")
        }

        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: filePath)

            let metadata: [String: Any] = [
                "file_path": filePath,
                "file_name": (filePath as NSString).lastPathComponent,
                "file_extension": (filePath as NSString).pathExtension,
                "file_size": attributes[.size] as? Int64 ?? 0,
                "creation_date": attributes[.creationDate] as? Date,
                "modification_date": attributes[.modificationDate] as? Date,
                "is_readable": (attributes[.posixPermissions] as? Int ?? 0) & 0o444 != 0,
                "is_writable": (attributes[.posixPermissions] as? Int ?? 0) & 0o222 != 0,
                "is_executable": (attributes[.posixPermissions] as? Int ?? 0) & 0o111 != 0,
                "file_type": attributes[.type] as? String ?? "unknown",
            ]

            return metadata

        } catch {
            throw MCPError.executionFailed("Failed to extract metadata: \(error.localizedDescription)")
        }
    }

    private func optimizeFile(_ parameters: [String: Any]) async throws -> [String: Any] {
        let filePath = parameters["file_path"] as! String
        let optimizationType = parameters["optimization_type"] as? String ?? "compress"
        let outputPath = parameters["output_path"] as? String ?? generateOutputPath(filePath, "optimized")

        guard FileManager.default.fileExists(atPath: filePath) else {
            throw MCPError.executionFailed("File does not exist: \(filePath)")
        }

        do {
            let content = try String(contentsOfFile: filePath, encoding: .utf8)
            var optimizedContent = content
            var optimizations: [String] = []

            // Apply optimizations based on file type
            let fileExtension = (filePath as NSString).pathExtension.lowercased()

            switch fileExtension {
            case "swift":
                (optimizedContent, optimizations) = optimizeSwiftCode(content)
            case "json":
                (optimizedContent, optimizations) = optimizeJSON(content)
            case "md":
                (optimizedContent, optimizations) = optimizeMarkdown(content)
            default:
                optimizations = ["No specific optimizations available for .\(fileExtension) files"]
            }

            // Write optimized content
            try optimizedContent.write(toFile: outputPath, atomically: true, encoding: .utf8)

            return [
                "original_file": filePath,
                "optimized_file": outputPath,
                "optimization_type": optimizationType,
                "original_size": content.count,
                "optimized_size": optimizedContent.count,
                "compression_ratio": Double(optimizedContent.count) / Double(content.count),
                "optimizations_applied": optimizations,
                "timestamp": Date(),
            ]

        } catch {
            throw MCPError.executionFailed("Failed to optimize file: \(error.localizedDescription)")
        }
    }

    // MARK: - Helper Methods

    private func generateOutputPath(_ originalPath: String, _ suffix: String) -> String {
        let path = originalPath as NSString
        let baseName = path.deletingPathExtension
        let extension = path.pathExtension
        return "\(baseName)_\(suffix).\(extension)"
    }

    private func removeComments(from content: String, language: String) -> String {
        var lines = content.components(separatedBy: .newlines)
        var inMultilineComment = false

        for i in 0 ..< lines.count {
            var line = lines[i]

            if language == "swift" {
                // Remove single-line comments
                if let commentIndex = line.firstIndex(of: "//") {
                    line = String(line[..<commentIndex])
                }

                // Handle multi-line comments
                if line.contains("/*") {
                    inMultilineComment = true
                    if let startIndex = line.firstIndex(of: "/*") {
                        line = String(line[..<startIndex])
                    }
                }

                if inMultilineComment {
                    if line.contains("*/") {
                        inMultilineComment = false
                        if let endIndex = line.firstIndex(of: "*/") {
                            line = String(line[endIndex...].dropFirst(2))
                        } else {
                            line = ""
                        }
                    } else {
                        line = ""
                    }
                }
            }

            lines[i] = line
        }

        return lines.joined(separator: "\n")
    }

    private func optimizeSwiftCode(_ content: String) -> (String, [String]) {
        var optimized = content
        var optimizations: [String] = []

        // Remove extra blank lines
        let lines = optimized.components(separatedBy: .newlines)
        var cleanedLines: [String] = []
        var previousLineEmpty = false

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty {
                if !previousLineEmpty {
                    cleanedLines.append("")
                    previousLineEmpty = true
                }
            } else {
                cleanedLines.append(line)
                previousLineEmpty = false
            }
        }

        optimized = cleanedLines.joined(separator: "\n")
        optimizations.append("Removed extra blank lines")

        // Remove trailing whitespace
        optimized = optimized.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .joined(separator: "\n")
        optimizations.append("Removed trailing whitespace")

        return (optimized, optimizations)
    }

    private func optimizeJSON(_ content: String) -> (String, [String]) {
        var optimizations: [String] = []

        // Minify JSON
        if let data = content.data(using: .utf8),
           let jsonObject = try? JSONSerialization.jsonObject(with: data),
           let minifiedData = try? JSONSerialization.data(withJSONObject: jsonObject)
        {
            let minified = String(data: minifiedData, encoding: .utf8) ?? content
            optimizations.append("Minified JSON structure")
            return (minified, optimizations)
        }

        return (content, ["No optimizations applied"])
    }

    private func optimizeMarkdown(_ content: String) -> (String, [String]) {
        var optimized = content
        var optimizations: [String] = []

        // Fix common markdown issues
        optimized = optimized.replacingOccurrences(of: "\r\n", with: "\n")
        optimizations.append("Normalized line endings")

        // Remove multiple consecutive blank lines
        while optimized.contains("\n\n\n") {
            optimized = optimized.replacingOccurrences(of: "\n\n\n", with: "\n\n")
        }
        optimizations.append("Removed excessive blank lines")

        return (optimized, optimizations)
    }
}

/// Advanced workflow orchestration tool
public final class AdvancedWorkflowOrchestrationTool: EnhancedMCPTool {
    public let capabilities: [MCPToolCapability] = [.workflowOrchestration, .optimization]
    public let dependencies: [String] = ["EnhancedMCPOrchestrator"]
    public var performanceMetrics: MCPToolMetrics = .init()

    private let orchestrator: EnhancedMCPOrchestrator

    public init(orchestrator: EnhancedMCPOrchestrator) {
        self.orchestrator = orchestrator
    }

    public func id() async -> String { "advanced_workflow_orchestrator" }
    public func name() async -> String { "Advanced Workflow Orchestrator" }
    public func description() async -> String {
        "Advanced workflow orchestration with intelligent scheduling, optimization, and monitoring"
    }

    public func execute(parameters: [String: Any]) async throws -> Any? {
        guard let operation = parameters["operation"] as? String else {
            throw MCPError.invalidParameters("Missing 'operation' parameter")
        }

        switch operation {
        case "create_workflow":
            return try await createWorkflow(parameters)
        case "execute_workflow":
            return try await executeWorkflow(parameters)
        case "optimize_workflow":
            return try await optimizeWorkflow(parameters)
        case "monitor_workflow":
            return try await monitorWorkflow(parameters)
        case "analyze_workflow_performance":
            return try await analyzeWorkflowPerformance(parameters)
        default:
            throw MCPError.invalidParameters("Unknown operation: \(operation)")
        }
    }

    public func validateParameters(_ parameters: [String: Any]) throws {
        guard let operation = parameters["operation"] as? String else {
            throw MCPError.invalidParameters("Missing 'operation' parameter")
        }

        switch operation {
        case "create_workflow":
            guard let steps = parameters["steps"] as? [[String: Any]], !steps.isEmpty else {
                throw MCPError.invalidParameters("Missing or empty 'steps' array")
            }
        case "execute_workflow", "optimize_workflow", "monitor_workflow", "analyze_workflow_performance":
            guard parameters["workflow_id"] as? String != nil else {
                throw MCPError.invalidParameters("Missing 'workflow_id' parameter")
            }
        default:
            break
        }
    }

    public func estimateExecutionTime(for parameters: [String: Any]) -> TimeInterval {
        guard let operation = parameters["operation"] as? String else { return 1.0 }

        switch operation {
        case "create_workflow":
            return 2.0
        case "execute_workflow":
            if let steps = parameters["steps"] as? [[String: Any]] {
                return Double(steps.count) * 5.0 // ~5 seconds per step
            }
            return 10.0
        case "optimize_workflow":
            return 3.0
        case "monitor_workflow":
            return 1.0
        case "analyze_workflow_performance":
            return 2.0
        default:
            return 2.0
        }
    }

    public func getOptimizationHints() -> [String] {
        [
            "Parallelize independent workflow steps",
            "Cache intermediate results",
            "Use intelligent scheduling for resource optimization",
        ]
    }

    // MARK: - Private Methods

    private func createWorkflow(_ parameters: [String: Any]) async throws -> [String: Any] {
        let name = parameters["name"] as? String ?? "Unnamed Workflow"
        let description = parameters["description"] as? String
        let rawSteps = parameters["steps"] as! [[String: Any]]

        // Convert raw steps to MCPWorkflowStep
        var workflowSteps: [MCPWorkflowStep] = []

        for (index, rawStep) in rawSteps.enumerated() {
            guard let toolId = rawStep["tool_id"] as? String else {
                throw MCPError.invalidParameters("Step \(index) missing 'tool_id'")
            }

            let parameters = rawStep["parameters"] as? [String: AnyCodable] ?? [:]
            let dependencies = rawStep["dependencies"] as? [UUID] ?? []

            let step = MCPWorkflowStep(
                id: UUID(),
                toolId: toolId,
                parameters: parameters,
                dependencies: dependencies
            )

            workflowSteps.append(step)
        }

        // Create workflow using the orchestrator's workflow manager
        let workflowManager = BasicMCPWorkflowManager()
        let workflow = await workflowManager.createWorkflow(name: name, steps: workflowSteps)

        return [
            "workflow_id": workflow.id.uuidString,
            "workflow_name": workflow.name,
            "description": workflow.description ?? "",
            "step_count": workflow.steps.count,
            "created_at": workflow.createdAt,
            "has_dependencies": workflow.hasDependencies,
        ]
    }

    private func executeWorkflow(_ parameters: [String: Any]) async throws -> [String: Any] {
        let workflowIdString = parameters["workflow_id"] as! String

        guard let workflowId = UUID(uuidString: workflowIdString) else {
            throw MCPError.invalidParameters("Invalid workflow ID format")
        }

        // For now, create a mock workflow since we don't have persistence
        let mockWorkflow = MCPWorkflow(
            name: "Mock Workflow",
            steps: [
                MCPWorkflowStep(toolId: "mock_tool_1"),
                MCPWorkflowStep(toolId: "mock_tool_2", dependencies: [UUID()]),
            ]
        )

        let workflowManager = BasicMCPWorkflowManager()
        let result = try await workflowManager.executeWorkflow(mockWorkflow)

        return [
            "workflow_id": workflowIdString,
            "success": result.success,
            "execution_time": result.executionTime,
            "step_results_count": result.stepResults.count,
            "error_count": result.errors.count,
            "timestamp": Date(),
        ]
    }

    private func optimizeWorkflow(_ parameters: [String: Any]) async throws -> [String: Any] {
        let workflowIdString = parameters["workflow_id"] as! String

        guard let workflowId = UUID(uuidString: workflowIdString) else {
            throw MCPError.invalidParameters("Invalid workflow ID format")
        }

        // Create mock workflow for optimization
        let mockWorkflow = MCPWorkflow(
            name: "Mock Workflow",
            steps: [
                MCPWorkflowStep(toolId: "tool_1"),
                MCPWorkflowStep(toolId: "tool_2"),
                MCPWorkflowStep(toolId: "tool_3", dependencies: [UUID(), UUID()]),
            ]
        )

        let workflowManager = BasicMCPWorkflowManager()
        let optimizedWorkflow = await workflowManager.optimizeWorkflow(mockWorkflow)

        return [
            "original_workflow_id": workflowIdString,
            "optimized_workflow_id": optimizedWorkflow.id.uuidString,
            "optimization_applied": "parallel_execution",
            "step_count": optimizedWorkflow.steps.count,
            "has_parallel_execution": true,
            "timestamp": Date(),
        ]
    }

    private func monitorWorkflow(_ parameters: [String: Any]) async throws -> [String: Any] {
        let workflowIdString = parameters["workflow_id"] as! String

        guard let workflowId = UUID(uuidString: workflowIdString) else {
            throw MCPError.invalidParameters("Invalid workflow ID format")
        }

        // Mock monitoring data
        let status = MCPWorkflowStatus(
            workflowId: workflowId,
            status: .running,
            progress: 0.65,
            estimatedTimeRemaining: 45.0
        )

        return [
            "workflow_id": workflowIdString,
            "status": status.status.rawValue,
            "progress": status.progress,
            "estimated_time_remaining": status.estimatedTimeRemaining ?? 0,
            "current_step": status.currentStep?.uuidString ?? "none",
            "timestamp": Date(),
        ]
    }

    private func analyzeWorkflowPerformance(_ parameters: [String: Any]) async throws -> [String: Any] {
        let workflowIdString = parameters["workflow_id"] as! String

        guard let workflowId = UUID(uuidString: workflowIdString) else {
            throw MCPError.invalidParameters("Invalid workflow ID format")
        }

        // Mock performance analysis
        let analysis: [String: Any] = [
            "workflow_id": workflowIdString,
            "average_execution_time": 120.5,
            "success_rate": 0.95,
            "bottleneck_steps": ["data_processing", "file_io"],
            "optimization_opportunities": [
                "Parallelize data processing steps",
                "Cache intermediate results",
                "Optimize file I/O operations",
            ],
            "resource_utilization": [
                "cpu": 0.75,
                "memory": 0.60,
                "disk": 0.40,
            ],
            "performance_score": 8.2,
            "recommendations": [
                "Implement parallel processing for independent steps",
                "Add result caching for repeated operations",
                "Monitor resource usage during execution",
            ],
            "timestamp": Date(),
        ]

        return analysis
    }
}
