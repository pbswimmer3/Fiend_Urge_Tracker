import Foundation
import Security

/// Minimal Keychain wrapper for storing the user's LLM API key.
/// Kept generic so additional secrets can be added without a service rewrite.
enum KeychainService {
    enum Key: String {
        case anthropicAPIKey = "fiend.llm.anthropic.apiKey"
    }

    @discardableResult
    static func set(_ value: String?, for key: Key) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key.rawValue
        ]
        SecItemDelete(query as CFDictionary)

        guard let value, !value.isEmpty,
              let data = value.data(using: .utf8) else {
            return true
        }

        var insert = query
        insert[kSecValueData as String] = data
        insert[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        let status = SecItemAdd(insert as CFDictionary, nil)
        return status == errSecSuccess
    }

    static func get(_ key: Key) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key.rawValue,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess, let data = item as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func hasValue(for key: Key) -> Bool {
        (get(key)?.isEmpty == false)
    }
}
