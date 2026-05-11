import Foundation

/// Protocol so we can swap providers (OpenAI, on-device, etc.) without touching callers.
protocol LLMService {
    func dailyDigest(habitName: String, daysClean: Int, recentTags: [String], topCorrelation: String?) async throws -> String
}

enum LLMError: Error, LocalizedError {
    case missingKey
    case httpError(Int, String)
    case decoding

    var errorDescription: String? {
        switch self {
        case .missingKey: return "Add your Anthropic API key in Settings to enable the counselor."
        case .httpError(let code, let body): return "Request failed (\(code)): \(body)"
        case .decoding: return "Couldn't read the response."
        }
    }
}

/// Default implementation: talks directly to the Anthropic Messages API with the user's
/// own key. We hit the API from the device, so the key never leaves their phone.
struct AnthropicCounselor: LLMService {
    var model: String = "claude-sonnet-4-6"
    var session: URLSession = .shared

    func dailyDigest(habitName: String, daysClean: Int, recentTags: [String], topCorrelation: String?) async throws -> String {
        guard let key = KeychainService.get(.anthropicAPIKey), !key.isEmpty else {
            throw LLMError.missingKey
        }

        let system = """
        You are a compassionate, evidence-aware addiction counselor giving a short daily digest. \
        Stay warm, specific, and concrete. Never moralize. Never diagnose. \
        If anything sounds like a medical or safety emergency, suggest professional help. \
        Keep the response under 220 words. Use 3 short sections: \
        "Today you might feel:", "What others on day \(daysClean) often say:", and "Try this:". \
        Use plain prose, no markdown headers, no asterisks, no emojis.
        """

        var userPrompt = "I am quitting \(habitName). I am on day \(daysClean) clean."
        if !recentTags.isEmpty {
            userPrompt += " My most recent emotional tags include: \(recentTags.joined(separator: ", "))."
        }
        if let corr = topCorrelation {
            userPrompt += " Pattern I've noticed: \(corr)"
        }
        userPrompt += " Please write today's digest."

        let payload: [String: Any] = [
            "model": model,
            "max_tokens": 600,
            "system": system,
            "messages": [
                ["role": "user", "content": userPrompt]
            ]
        ]

        var request = URLRequest(url: URL(string: "https://api.anthropic.com/v1/messages")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(key, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (data, response) = try await session.data(for: request)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard (200..<300).contains(status) else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw LLMError.httpError(status, body)
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let content = json["content"] as? [[String: Any]] else {
            throw LLMError.decoding
        }
        let text = content.compactMap { $0["text"] as? String }.joined(separator: "\n\n")
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
