import Foundation
import UniformTypeIdentifiers

struct ItemClassification: Equatable, Sendable {
  enum Category: String, Sendable {
    case folder = "Folder"
    case application = "Application"
    case archive = "Archive"
    case video = "Video"
    case audio = "Audio"
    case image = "Image"
    case document = "Document"
    case developer = "Developer file"
    case other = "Other"
  }

  let category: Category

  static func classify(_ item: ScanItem) -> ItemClassification {
    if item.kind == .folder {
      let category: Category = item.url.pathExtension.lowercased() == "app" ? .application : .folder
      return ItemClassification(category: category)
    }

    let fileExtension = item.url.pathExtension.lowercased()
    if developerExtensions.contains(fileExtension) {
      return ItemClassification(category: .developer)
    }

    guard let type = UTType(filenameExtension: fileExtension) else {
      return ItemClassification(category: .other)
    }

    let category: Category
    if type.conforms(to: .archive) {
      category = .archive
    } else if type.conforms(to: .movie) {
      category = .video
    } else if type.conforms(to: .audio) {
      category = .audio
    } else if type.conforms(to: .image) {
      category = .image
    } else if type.conforms(to: .text) || type.conforms(to: .pdf) || type.conforms(to: .spreadsheet)
    {
      category = .document
    } else {
      category = .other
    }
    return ItemClassification(category: category)
  }

  private static let developerExtensions: Set<String> = [
    "c", "cc", "cpp", "css", "dart", "go", "h", "hpp", "html", "java", "js", "json",
    "kt", "kts", "m", "mm", "php", "py", "rb", "rs", "sh", "sql", "swift", "ts", "tsx", "yaml",
    "yml",
  ]
}
