import Foundation

enum FileNameSearch {
    static func matches(_ name: String, query: String) -> Bool {
        guard !query.isEmpty else { return true }

        let normalizedQuery = normalize(query)
        guard !normalizedQuery.isEmpty else {
            return name.localizedStandardContains(query)
        }
        let normalizedName = normalize(name)
        return normalizedName.contains(normalizedQuery)
            || compact(normalizedName).contains(compact(normalizedQuery))
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

    private static func compact(_ value: String) -> String {
        value.replacingOccurrences(of: " ", with: "")
    }
}
