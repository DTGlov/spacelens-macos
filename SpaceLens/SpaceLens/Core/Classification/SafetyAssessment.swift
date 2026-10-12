import Foundation

struct SafetyAssessment: Equatable, Sendable {
  enum Level: String, Sendable {
    case knownReproducible = "Known reproducible"
    case reviewCarefully = "Review carefully"
    case protectedOrUnknown = "Protected or unknown"
  }

  let level: Level
  let reason: String

  static func assess(_ item: ScanItem, classification: ItemClassification) -> SafetyAssessment {
    let components = item.url.standardizedFileURL.pathComponents
    let isUserLocation = components.starts(with: ["/", "Users"])
    let isApplicationsLocation = components.count > 1 && components[1] == "Applications"

    if item.kind == .symbolicLink {
      return protected(
        "This is a symbolic link. SpaceLens cannot verify what removing it could affect.")
    }
    if isProtectedSystemLocation(components) {
      return protected(
        "This item is in a macOS system location and may be required by the system or installed software."
      )
    }
    if containsSensitiveConfiguration(components) {
      return protected(
        "This location may contain credentials, configuration, or source-control metadata.")
    }
    if isRecognizedCache(components) {
      return SafetyAssessment(
        level: .knownReproducible,
        reason:
          "This item is inside an application cache. Its app can recreate it, but may need to download or rebuild data."
      )
    }
    if isRecognizedBuildOutput(components) {
      return SafetyAssessment(
        level: .knownReproducible,
        reason:
          "This item is Xcode build output. Xcode can rebuild it when the project is built again."
      )
    }
    if components.contains("Downloads") {
      return review(
        "This item is in Downloads. Confirm that you no longer need it before moving it to Trash.")
    }
    if classification.category == .archive, isUserLocation {
      return review(
        "Archives may be replaceable, but can also be the only copy of important files.")
    }
    if classification.category == .application, isUserLocation || isApplicationsLocation {
      return review(
        "Removing an application can also affect documents, settings, or workflows that depend on it."
      )
    }
    if isUserLocation {
      return review(
        "This appears to be user-owned content. SpaceLens cannot determine whether it is personally important."
      )
    }

    return protected("SpaceLens cannot confidently determine how this item is used.")
  }

  private static func review(_ reason: String) -> SafetyAssessment {
    SafetyAssessment(level: .reviewCarefully, reason: reason)
  }

  private static func protected(_ reason: String) -> SafetyAssessment {
    SafetyAssessment(level: .protectedOrUnknown, reason: reason)
  }

  private static func isProtectedSystemLocation(_ components: [String]) -> Bool {
    let protectedRoots = ["System", "Library", "bin", "sbin", "usr", "private"]
    return components.count > 1 && protectedRoots.contains(components[1])
  }

  private static func containsSensitiveConfiguration(_ components: [String]) -> Bool {
    let sensitiveComponents: Set<String> = [
      ".git", ".gnupg", ".ssh", "Keychains", "MobileSync",
    ]
    return !sensitiveComponents.isDisjoint(with: components)
  }

  private static func isRecognizedCache(_ components: [String]) -> Bool {
    components.containsAdjacent("Library", "Caches")
  }

  private static func isRecognizedBuildOutput(_ components: [String]) -> Bool {
    components.containsSequence(["Library", "Developer", "Xcode", "DerivedData"])
  }
}

extension Array where Element == String {
  fileprivate func containsAdjacent(_ first: String, _ second: String) -> Bool {
    containsSequence([first, second])
  }

  fileprivate func containsSequence(_ sequence: [String]) -> Bool {
    guard !sequence.isEmpty, sequence.count <= count else { return false }
    return indices.dropLast(sequence.count - 1).contains { startIndex in
      Array(self[startIndex..<(startIndex + sequence.count)]) == sequence
    }
  }
}
