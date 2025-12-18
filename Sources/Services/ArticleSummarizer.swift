//
//  ArticleSummarizer.swift
//  Sources
//
//  Created on 12/18/25.
//

import Foundation
import FoundationModels

/// Service responsible for generating AI summaries of article content using Apple Foundation Models
@MainActor
class ArticleSummarizer {
    /// Shared singleton instance
    static let shared = ArticleSummarizer()
    
    /// The system language model for text generation
    private let model = SystemLanguageModel.default
    
    /// Current availability status of the model
    var availability: SystemLanguageModel.Availability {
        model.availability
    }
    
    /// Check if the model is available for use
    var isAvailable: Bool {
        model.isAvailable
    }
    
    private init() {}
    
    /// Generate a summary for the given article text
    /// - Parameter articleText: The full text content of the article
    /// - Returns: A concise summary string
    /// - Throws: Errors related to model availability or generation
    func generateSummary(for articleText: String) async throws -> String {
        // Check model availability
        guard isAvailable else {
            throw SummarizationError.modelUnavailable(availability)
        }
        
        // Check for empty content
        let trimmedText = articleText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else {
            throw SummarizationError.emptyContent
        }
        
        // Check if article is too short to summarize
        let wordCount = trimmedText.split(separator: " ").count
        if wordCount < 50 {
            throw SummarizationError.contentTooShort
        }
        
        // Handle long articles by chunking if necessary
        let maxCharsPerRequest = 12000 // ~4000 tokens
        if trimmedText.count > maxCharsPerRequest {
            return try await summarizeLongArticle(trimmedText)
        }
        
        // Create session with summarization instructions
        let instructions = """
        You are a helpful assistant that creates concise summaries of articles.
        Summarize the key points in 2-3 sentences. Be accurate and preserve the main message.
        Focus on the most important information and maintain a neutral tone.
        """
        
        let session = LanguageModelSession(instructions: instructions)
        
        // Create the prompt
        let prompt = """
        Summarize this article in 2-3 sentences:
        
        \(trimmedText)
        """
        
        // Generate the summary
        do {
            let response = try await session.respond(to: prompt)
            let summary = response.content.trimmingCharacters(in: .whitespacesAndNewlines)
            
            guard !summary.isEmpty else {
                throw SummarizationError.emptyResponse
            }
            
            return summary
        } catch let error as LanguageModelSession.GenerationError {
            switch error {
            case .exceededContextWindowSize:
                // Retry with chunking
                return try await summarizeLongArticle(trimmedText)
            default:
                throw SummarizationError.generationFailed(error)
            }
        }
    }
    
    /// Handle summarization of long articles by breaking them into chunks
    private func summarizeLongArticle(_ text: String) async throws -> String {
        let chunkSize = 10000
        var summaries: [String] = []
        
        // Split into chunks
        var currentIndex = text.startIndex
        while currentIndex < text.endIndex {
            let endIndex = text.index(currentIndex, offsetBy: chunkSize, limitedBy: text.endIndex) ?? text.endIndex
            let chunk = String(text[currentIndex..<endIndex])
            
            // Summarize this chunk
            let instructions = """
            You are a helpful assistant that creates concise summaries.
            Summarize the key points of this text section in 1-2 sentences.
            """
            
            let session = LanguageModelSession(instructions: instructions)
            let prompt = "Summarize this section:\n\n\(chunk)"
            
            let response = try await session.respond(to: prompt)
            summaries.append(response.content)
            
            currentIndex = endIndex
        }
        
        // If we have multiple summaries, combine them
        if summaries.count > 1 {
            let combinedSummaries = summaries.joined(separator: " ")
            
            let finalInstructions = """
            You are a helpful assistant that creates concise summaries.
            Combine these section summaries into a cohesive 2-3 sentence summary of the entire article.
            """
            
            let finalSession = LanguageModelSession(instructions: finalInstructions)
            let finalPrompt = "Combine these summaries into a final summary:\n\n\(combinedSummaries)"
            
            let finalResponse = try await finalSession.respond(to: finalPrompt)
            return finalResponse.content.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        return summaries.first ?? ""
    }
    
    /// Extract plain text from HTML content
    func extractPlainText(from html: String) -> String {
        // Remove HTML tags using a simple regex approach
        // This is a basic implementation - could be enhanced with proper HTML parsing
        var text = html
        
        // Remove script and style tags with their content
        text = text.replacingOccurrences(of: "<script[^>]*>[\\s\\S]*?</script>", with: "", options: .regularExpression)
        text = text.replacingOccurrences(of: "<style[^>]*>[\\s\\S]*?</style>", with: "", options: .regularExpression)
        
        // Remove all HTML tags
        text = text.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
        
        // Decode HTML entities
        text = text.replacingOccurrences(of: "&nbsp;", with: " ")
        text = text.replacingOccurrences(of: "&amp;", with: "&")
        text = text.replacingOccurrences(of: "&lt;", with: "<")
        text = text.replacingOccurrences(of: "&gt;", with: ">")
        text = text.replacingOccurrences(of: "&quot;", with: "\"")
        text = text.replacingOccurrences(of: "&#39;", with: "'")
        text = text.replacingOccurrences(of: "&apos;", with: "'")
        
        // Clean up whitespace
        text = text.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        return text
    }
    
    /// Get a user-friendly error message for the current availability status
    func availabilityMessage() -> String {
        switch availability {
        case .available:
            return "AI summaries are available"
        case .unavailable(.deviceNotEligible):
            return "AI summaries are not available on this device"
        case .unavailable(.appleIntelligenceNotEnabled):
            return "Enable Apple Intelligence in System Settings to use AI summaries"
        case .unavailable(.modelNotReady):
            return "AI model is downloading. Please try again later."
        case .unavailable:
            return "AI summaries are currently unavailable"
        }
    }
}

// MARK: - Errors

enum SummarizationError: LocalizedError {
    case modelUnavailable(SystemLanguageModel.Availability)
    case emptyContent
    case contentTooShort
    case emptyResponse
    case generationFailed(Error)
    
    var errorDescription: String? {
        switch self {
        case .modelUnavailable(let availability):
            switch availability {
            case .unavailable(.deviceNotEligible):
                return "AI summaries are not available on this device"
            case .unavailable(.appleIntelligenceNotEnabled):
                return "Enable Apple Intelligence in System Settings"
            case .unavailable(.modelNotReady):
                return "AI model is downloading. Please try again later."
            case .unavailable:
                return "AI summaries are currently unavailable"
            case .available:
                return "Model is available but generation failed"
            }
        case .emptyContent:
            return "No content available to summarize"
        case .contentTooShort:
            return "Article is too short to summarize"
        case .emptyResponse:
            return "Failed to generate summary"
        case .generationFailed(let error):
            return "Failed to generate summary: \(error.localizedDescription)"
        }
    }
}
