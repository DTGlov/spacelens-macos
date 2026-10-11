import Foundation

struct AuthorizedScanScope: Equatable, Sendable {
    let rootURL: URL

    init(rootURL: URL) {
        self.rootURL = rootURL.standardizedFileURL.resolvingSymlinksInPath()
    }

    func contains(_ candidateURL: URL) -> Bool {
        let candidate = candidateURL.standardizedFileURL.resolvingSymlinksInPath()
        let rootComponents = rootURL.pathComponents
        let candidateComponents = candidate.pathComponents
        return candidateComponents.starts(with: rootComponents)
    }

    func breadcrumbs(to destinationURL: URL) -> [URL] {
        let destination = destinationURL.standardizedFileURL.resolvingSymlinksInPath()
        guard contains(destination) else { return [] }

        let relativeComponents = destination.pathComponents.dropFirst(rootURL.pathComponents.count)
        return relativeComponents.reduce(into: [rootURL]) { urls, component in
            guard let parent = urls.last else { return }
            urls.append(parent.appending(path: component, directoryHint: .isDirectory))
        }
    }
}
