import SwiftUI
import UniformTypeIdentifiers
import PareCore

struct ContentView: View {
    @StateObject private var model = QueueModel()
    @State private var showFileImporter = false
    @State private var showFolderImporter = false
    @State private var showOptions = false
    @State private var isDropTargeted = false
    @State private var copiedNoticeID: UUID?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            dropZone
            optionsRow
            fileList
            statusBar
        }
        .padding(16)
        .fileImporter(
            isPresented: $showFileImporter,
            allowedContentTypes: PareApp.supportedTypes,
            allowsMultipleSelection: true
        ) { result in
            if case .success(let urls) = result {
                model.add(urls: urls)
            }
        }
        .fileImporter(
            isPresented: $showFolderImporter,
            allowedContentTypes: [.folder],
            allowsMultipleSelection: false
        ) { result in
            if case .success(let urls) = result, let folder = urls.first {
                model.outputFolder = folder
            }
        }
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Pare")
                    .font(.title.weight(.semibold))
                Text("Documents in. Clean, token-light Markdown out.")
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button("Choose Files…") { showFileImporter = true }
        }
    }

    private var dropZone: some View {
        VStack(spacing: 6) {
            Image(systemName: "tray.and.arrow.down")
                .font(.system(size: 28))
                .foregroundStyle(isDropTargeted ? Color.accentColor : Color.secondary)
            Text("Drop DOCX, PDF, ODT, RTF, HTML or TXT files here")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 92)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isDropTargeted ? Color.accentColor.opacity(0.08) : Color(nsColor: .controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(
                    isDropTargeted ? Color.accentColor : Color(nsColor: .separatorColor),
                    style: StrokeStyle(lineWidth: 1, dash: [5])
                )
        )
        .contentShape(RoundedRectangle(cornerRadius: 10))
        .onTapGesture { showFileImporter = true }
        .dropDestination(for: URL.self) { urls, _ in
            model.add(urls: urls)
            return true
        } isTargeted: { targeted in
            isDropTargeted = targeted
        }
    }

    private var optionsRow: some View {
        HStack(spacing: 10) {
            Button {
                model.convertAll()
            } label: {
                Label("Convert", systemImage: "arrow.down.doc")
            }
            .buttonStyle(.borderedProminent)
            .disabled(model.isConverting || model.queuedCount == 0)

            if model.isConverting {
                ProgressView()
                    .controlSize(.small)
                Text("Converting…")
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button(model.outputFolder == nil ? "Output: With source files" : "Output: \(model.outputFolder!.lastPathComponent)") {
                showFolderImporter = true
            }
            .controlSize(.small)

            Button {
                showOptions.toggle()
            } label: {
                Label("Options", systemImage: "slider.horizontal.3")
            }
            .controlSize(.small)

            Button {
                model.clear()
            } label: {
                Label("Clear", systemImage: "trash")
            }
            .controlSize(.small)
            .disabled(model.items.isEmpty || model.isConverting)
        }
        if showOptions {
            optionsPanel
        }
    }

    private var optionsPanel: some View {
        VStack(alignment: .leading, spacing: 6) {
            Toggle("Strip repeated headers, footers and page numbers", isOn: $model.options.stripHeadersFooters)
            Toggle("Remove image placeholders", isOn: $model.options.removeImages)
            Toggle("Strip link URLs, keep link text", isOn: $model.options.removeLinkURLs)
            Toggle("Compact blank lines and whitespace", isOn: $model.options.compactWhitespace)
        }
        .font(.callout)
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 8).fill(Color(nsColor: .ControlBackgroundColor)))
    }

    private var fileList: some View {
        List {
            ForEach(model.items) { item in
                row(for: item)
            }
        }
        .listStyle(.inset)
        .overlay {
            if model.items.isEmpty {
                Text("No files yet")
                    .foregroundStyle(.tertiary)
            }
        }
    }

    private func row(for item: QueueModel.Item) -> some View {
        HStack(spacing: 10) {
            statusIcon(for: item)
            VStack(alignment: .leading, spacing: 2) {
                Text(item.url.lastPathComponent)
                    .lineLimit(1)
                    .help(item.url.path)
                HStack(spacing: 6) {
                    if let message = item.errorMessage {
                        Text(message)
                            .foregroundStyle(.red)
                            .lineLimit(2)
                    } else {
                        switch item.status {
                        case .queued:
                            Text("Queued").foregroundStyle(.secondary)
                        case .converting:
                            Text("Converting…").foregroundStyle(.secondary)
                        case .done:
                            statusDetails(for: item)
                        case .failed:
                            Text("Failed").foregroundStyle(.red)
                        }
                    }
                }
                .font(.caption)
            }
            Spacer()
            if item.status == .done {
                Button("Copy") {
                    copyMarkdown(for: item)
                }
                .controlSize(.small)
                Button("Reveal") {
                    if let outputURL = item.outputURL {
                        NSWorkspace.shared.activateFileViewerSelecting([outputURL])
                    }
                }
                .controlSize(.small)
            }
        }
        .padding(.vertical, 2)
    }

    @ViewBuilder
    private func statusDetails(for item: QueueModel.Item) -> some View {
        if let result = item.result {
            Text("\(result.stats.wordCount) words · ~\(result.stats.markdownTokenEstimate) tokens")
            if result.stats.rawTokenEstimate > result.stats.markdownTokenEstimate {
                Text("−\(result.stats.tokenSavingsPercent)% vs raw text")
                    .foregroundStyle(.green)
            }
        }
    }

    private func statusIcon(for item: QueueModel.Item) -> some View {
        switch item.status {
        case .queued:
            Image(systemName: "doc")
                .foregroundStyle(.secondary)
        case .converting:
            Image(systemName: "hourglass")
                .foregroundStyle(.secondary)
        case .done:
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
        case .failed:
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
        }
    }

    private var statusBar: some View {
        HStack(spacing: 14) {
            let done = model.doneItems
            if done.isEmpty {
                Text(model.outputFolder == nil ? "Markdown files are written next to each source file." : "Output folder: \(model.outputFolder!.path)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                let totalTokens = done.compactMap { $0.result?.stats.markdownTokenEstimate }.reduce(0, +)
                let totalSaved = done.compactMap { $0.result?.stats }.reduce(0) { $0 + ($1.rawTokenEstimate - $1.markdownTokenEstimate) }
                Text("\(done.count) file\(done.count == 1 ? "" : "s") · ~\(totalTokens) tokens total · ~\(totalSaved) tokens saved")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
    }

    private func copyMarkdown(for item: QueueModel.Item) {
        guard let markdown = item.result?.markdown else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(markdown, forType: .string)
        copiedNoticeID = item.id
    }
}
