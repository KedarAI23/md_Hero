import Foundation
import Compression

struct ArchiveEntry {
    let name: String
    let dataOffset: Int
    let compressedSize: Int
    let uncompressedSize: Int
    let method: UInt16
}

public final class ZipArchive {
    private let data: Data
    private let entries: [ArchiveEntry]

    public init?(data: Data) {
        self.data = data
        guard let directory = Self.centralDirectoryEntries(in: data), !directory.isEmpty else {
            return nil
        }
        self.entries = directory
    }

    public convenience init?(url: URL) {
        guard let data = try? Data(contentsOf: url) else { return nil }
        self.init(data: data)
    }

    public func entryNames() -> [String] {
        entries.map { $0.name }
    }

    public func data(forEntry name: String) -> Data? {
        guard let entry = entries.first(where: { $0.name == name }) else { return nil }
        let end = min(entry.dataOffset + entry.compressedSize, data.count)
        guard entry.dataOffset <= end else { return nil }
        let payload = data.subdata(in: entry.dataOffset..<end)

        if entry.method == 0 {
            return payload
        }
        if entry.method == 8 {
            return Self.inflate(payload, outputSize: entry.uncompressedSize)
        }
        return nil
    }

    private static func centralDirectoryEntries(in data: Data) -> [ArchiveEntry]? {
        let bytes = [UInt8](data)
        guard bytes.count > 22, let eocd = findEOCD(bytes) else { return nil }

        let totalEntries = Int(readUInt16(bytes, eocd + 10))
        guard totalEntries > 0 else { return nil }
        var cursor = Int(readUInt32(bytes, eocd + 16))

        var results: [ArchiveEntry] = []
        for _ in 0..<totalEntries {
            guard cursor + 46 <= bytes.count, readUInt32(bytes, cursor) == 0x0201_4b50 else { break }

            let method = readUInt16(bytes, cursor + 10)
            let compressedSize = Int(readUInt32(bytes, cursor + 20))
            let uncompressedSize = Int(readUInt32(bytes, cursor + 24))
            let nameLength = Int(readUInt16(bytes, cursor + 28))
            let extraLength = Int(readUInt16(bytes, cursor + 30))
            let commentLength = Int(readUInt16(bytes, cursor + 32))
            let localOffset = Int(readUInt32(bytes, cursor + 42))

            let nameStart = cursor + 46
            let nameEnd = nameStart + nameLength
            guard nameEnd <= bytes.count else { break }
            let nameBytes = bytes[nameStart..<nameEnd]
            let name = String(bytes: nameBytes, encoding: .utf8)
                ?? String(bytes: nameBytes, encoding: .isoLatin1)
                ?? ""
            cursor = nameEnd + extraLength + commentLength

            guard localOffset + 30 <= bytes.count, readUInt32(bytes, localOffset) == 0x0403_4b50 else {
                continue
            }
            let localNameLength = Int(readUInt16(bytes, localOffset + 26))
            let localExtraLength = Int(readUInt16(bytes, localOffset + 28))
            let dataOffset = localOffset + 30 + localNameLength + localExtraLength
            guard dataOffset + compressedSize <= bytes.count else { continue }

            results.append(
                ArchiveEntry(
                    name: name,
                    dataOffset: dataOffset,
                    compressedSize: compressedSize,
                    uncompressedSize: uncompressedSize,
                    method: method
                )
            )
        }
        return results
    }

    private static func findEOCD(_ bytes: [UInt8]) -> Int? {
        let searchLimit = max(0, bytes.count - 66_000)
        var i = bytes.count - 22
        while i >= searchLimit {
            if readUInt32(bytes, i) == 0x0605_4b50 {
                return i
            }
            i -= 1
        }
        return nil
    }

    private static func readUInt16(_ bytes: [UInt8], _ offset: Int) -> UInt16 {
        guard offset + 2 <= bytes.count else { return 0 }
        return UInt16(bytes[offset]) | (UInt16(bytes[offset + 1]) << 8)
    }

    private static func readUInt32(_ bytes: [UInt8], _ offset: Int) -> UInt32 {
        guard offset + 4 <= bytes.count else { return 0 }
        return UInt32(bytes[offset])
            | (UInt32(bytes[offset + 1]) << 8)
            | (UInt32(bytes[offset + 2]) << 16)
            | (UInt32(bytes[offset + 3]) << 24)
    }

    private static func inflate(_ input: Data, outputSize: Int) -> Data? {
        guard outputSize > 0 else { return Data() }
        guard input.count > 0 else { return nil }

        var destination = Data(count: outputSize)
        let written = destination.withUnsafeMutableBytes { destBuffer -> Int in
            guard let destPointer = destBuffer.bindMemory(to: UInt8.self).baseAddress else { return 0 }
            return input.withUnsafeBytes { sourceBuffer -> Int in
                guard let sourcePointer = sourceBuffer.bindMemory(to: UInt8.self).baseAddress else { return 0 }
                return compression_decode_buffer(
                    destPointer, outputSize,
                    sourcePointer, input.count,
                    nil,
                    COMPRESSION_ZLIB
                )
            }
        }
        guard written > 0 else { return nil }
        destination.count = written
        return destination
    }
}
