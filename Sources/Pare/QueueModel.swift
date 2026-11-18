import SwiftUI
import PareCore

@MainActor
final class QueueModel: ObservableObject {
    struct Item: Identifiable {
        let id = UUID()
        let url: URL
        var status: Status = .queued
        var result: ConversionResult?
        var outputURL: URL?
        var manifestURL: URL?
        var errorMessage: String?

        enum Status: Equatable {
            case queued
            case converting
            case done
            case failed
        }
    }

    @Published var items: [Item] = []
    @Published var options = ConvertOptions()
    @Published var outputFolder: URL?
    @Published var isConverting = false

    var queuedCount: Int {
        items.filter { $0.status == .queued }.count
    }

    var doneItems: [Item] {
        items.filter { $0.status == .done }
    }

    func add(urls: [URL]) {
        for url in urls where url.isFileURL {
            let ext = url.pathExtension.lowercased()
            guard DocumentConverter.supportedExtensions.contains(ext) else { continue }
            if !items.contains(where: { $0.url.absoluteString == url.absoluteString })
                && !doneItems.contains(where: { $0.url.absoluteString == url.absoluteString }) {
                items.append(Item(url: url))
            }
        }
    }

    func remove(at offsets: IndexSet) {
        items.remove(atOffsets: offsets)
    }

    func clear() {
        guard !isConverting else { return }
        items.removeAll()
    }

    func convertAll() {
        guard !isConverting, !items.isEmpty else { return }
        isConverting = true
        let options = options
        let folder = outputFolder

        Task.detached(priority: .userInitiated) {
            let snapshot = await self.items.map { ($0.id, $0.url) }
            var writtenNames = Set<String>()

            for (id, url) in snapshot {
                await MainActor.run {
                    self.set(id: id) { $0.status = .converting; $0.errorMessage = nil }
                }
                do {
                    let result = try DocumentConverter.convert(url: url, options: options)
                    let target = DocumentConverter.outputURL(
                        for: url,
                        outputFolder: folder,
                        existingNames: writtenNames
                    )
                    try DocumentConverter.write(result, to: target)
                    try DocumentConverter.writeManifest(
                        for: result,
                        sourceURL: url,
                        markdownURL: target,
                        options: options
                    )
                    writtenNames.insert(target.lastPathComponent)
                    let manifestURL = target.deletingPathExtension().appendingPathExtension("manifest.json")
                    await MainActor.run {
                        self.set(id: id) {
                            $0.status = .done
                            $0.result = result
                            $0.outputURL = target
                            $0.manifestURL = manifestURL
                        }
                    }
                } catch {
                    await MainActor.run {
                        self.set(id: id) {
                            $0.status = .failed
                            $0.errorMessage = error.localizedDescription
                        }
                    }
                }
            }
            await MainActor.run { self.isConverting = false }
        }
    }

    private func set(id: UUID, _ mutate: (inout Item) -> Void) {
        if let index = items.firstIndex(where: { $0.id == id }) {
            mutate(&items[index])
        }
    }
}
