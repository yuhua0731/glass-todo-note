import Foundation

public struct BackgroundImageStorage {
    public let directory: URL
    private let fileSystem: BackgroundImageFileSystem

    public init(directory: URL, fileManager: FileManager = .default) {
        self.init(directory: directory, fileSystem: fileManager)
    }

    init(directory: URL, fileSystem: BackgroundImageFileSystem) {
        self.directory = directory
        self.fileSystem = fileSystem
    }

    public static var applicationSupport: BackgroundImageStorage {
        guard let baseDirectory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            preconditionFailure("Application Support directory is unavailable.")
        }
        return BackgroundImageStorage(directory: baseDirectory.appending(path: "GlassTodoNote", directoryHint: .isDirectory))
    }

    public func replaceImage(with sourceURL: URL) throws -> URL {
        try fileSystem.createDirectory(at: directory)
        let imageData = try Data(contentsOf: sourceURL)

        let pathExtension = sourceURL.pathExtension.isEmpty ? "image" : sourceURL.pathExtension.lowercased()
        let destinationURL = directory.appending(path: "background.\(pathExtension)")
        let temporaryURL = directory.appending(path: ".background-\(UUID().uuidString).tmp")

        do {
            try imageData.write(to: temporaryURL)
            try fileSystem.replaceOrMoveItem(at: temporaryURL, to: destinationURL)
            try clear(excluding: destinationURL)
        } catch {
            try? fileSystem.removeItem(at: temporaryURL)
            throw error
        }
        return destinationURL
    }

    public func clear() throws {
        try clear(excluding: nil)
    }

    private func clear(excluding excludedURL: URL?) throws {
        guard let files = try? fileSystem.contentsOfDirectory(at: directory) else {
            return
        }
        for file in files where file.lastPathComponent.hasPrefix("background.") {
            guard file.standardizedFileURL != excludedURL?.standardizedFileURL else { continue }
            try fileSystem.removeItem(at: file)
        }
    }
}

protocol BackgroundImageFileSystem {
    func createDirectory(at url: URL) throws
    func contentsOfDirectory(at url: URL) throws -> [URL]
    func removeItem(at url: URL) throws
    func replaceOrMoveItem(at sourceURL: URL, to destinationURL: URL) throws
}

extension FileManager: BackgroundImageFileSystem {
    func createDirectory(at url: URL) throws {
        try createDirectory(at: url, withIntermediateDirectories: true)
    }

    func contentsOfDirectory(at url: URL) throws -> [URL] {
        try contentsOfDirectory(at: url, includingPropertiesForKeys: nil)
    }

    func replaceOrMoveItem(at sourceURL: URL, to destinationURL: URL) throws {
        if fileExists(atPath: destinationURL.path) {
            _ = try replaceItemAt(destinationURL, withItemAt: sourceURL)
        } else {
            try moveItem(at: sourceURL, to: destinationURL)
        }
    }
}
