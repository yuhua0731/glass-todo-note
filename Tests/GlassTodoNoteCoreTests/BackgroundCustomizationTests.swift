import Foundation
import Testing
@testable import GlassTodoNoteCore

struct BackgroundCustomizationTests {
    @Test func backgroundModesExposeDesktopOptions() {
        #expect(BackgroundMode.allCases.map(\.rawValue) == ["preset", "solidColor", "image"])
        #expect(BackgroundMode.solidColor.title == "Solid Color")
        #expect(BackgroundMode.image.title == "Local Image")
    }

    @Test func storedBackgroundColorNormalizesHexValues() {
        #expect(StoredBackgroundColor.normalizedHex("#123456") == "#123456")
        #expect(StoredBackgroundColor.normalizedHex("abcDEF") == "#ABCDEF")
        #expect(StoredBackgroundColor.normalizedHex("bad") == StoredBackgroundColor.defaultHex)
        #expect(StoredBackgroundColor.normalizedHex("#GGGGGG") == StoredBackgroundColor.defaultHex)
    }

    @Test func backgroundImageStorageCopiesSelectedImageAndClearsOldFiles() throws {
        let root = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        let storage = BackgroundImageStorage(directory: root)
        let firstSource = root.appending(path: "first.png")
        let secondSource = root.appending(path: "second.jpg")

        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        try Data([1, 2, 3]).write(to: firstSource)
        try Data([4, 5, 6]).write(to: secondSource)

        let firstStored = try storage.replaceImage(with: firstSource)
        #expect(firstStored.lastPathComponent == "background.png")
        #expect(try Data(contentsOf: firstStored) == Data([1, 2, 3]))

        let secondStored = try storage.replaceImage(with: secondSource)
        #expect(secondStored.lastPathComponent == "background.jpg")
        #expect(try Data(contentsOf: secondStored) == Data([4, 5, 6]))
        #expect(!FileManager.default.fileExists(atPath: firstStored.path))

        try storage.clear()
        #expect(!FileManager.default.fileExists(atPath: secondStored.path))
    }

    @Test func backgroundImageStorageCanReplaceWithAlreadyStoredImage() throws {
        let root = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        let storage = BackgroundImageStorage(directory: root)
        let source = root.appending(path: "source.png")

        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        try Data([7, 8, 9]).write(to: source)

        let stored = try storage.replaceImage(with: source)
        let restored = try storage.replaceImage(with: stored)

        #expect(restored == stored)
        #expect(try Data(contentsOf: restored) == Data([7, 8, 9]))
    }

    @Test func backgroundImageStorageKeepsExistingImageWhenReplacementWriteFails() throws {
        let root = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        let fileSystem = FailingReplacementFileSystem()
        let storage = BackgroundImageStorage(directory: root, fileSystem: fileSystem)
        let oldImage = root.appending(path: "background.png")
        let newSource = root.appending(path: "new.png")

        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        try Data([1, 2, 3]).write(to: oldImage)
        try Data([4, 5, 6]).write(to: newSource)

        do {
            _ = try storage.replaceImage(with: newSource)
            Issue.record("Expected replacement to fail.")
        } catch {
            #expect(try Data(contentsOf: oldImage) == Data([1, 2, 3]))
        }
    }
}

private final class FailingReplacementFileSystem: BackgroundImageFileSystem {
    private let fileManager = FileManager.default

    func createDirectory(at url: URL) throws {
        try fileManager.createDirectory(at: url, withIntermediateDirectories: true)
    }

    func contentsOfDirectory(at url: URL) throws -> [URL] {
        try fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)
    }

    func removeItem(at url: URL) throws {
        try fileManager.removeItem(at: url)
    }

    func replaceOrMoveItem(at sourceURL: URL, to destinationURL: URL) throws {
        throw CocoaError(.fileWriteUnknown)
    }
}
