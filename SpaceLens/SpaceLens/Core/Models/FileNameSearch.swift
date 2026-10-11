import Foundation

enum FileNameSearch {
    static func matches(_ name: String, query: String) -> Bool {
        guard !query.isEmpty else { return true }

        let normalizedQuery = normalize(query)
        guard !normalizedQuery.isEmpty else {
            return name.localizedStandardContains(query)
        }
        return normalize(name).contains(normalizedQuery)
    }

    private static func normalize(_ value: String) -> String {
        value
            .folding(
                options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive],
                locale: .current
            )
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }
}
