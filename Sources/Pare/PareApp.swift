import SwiftUI
import UniformTypeIdentifiers
import PareCore

@main
struct PareApp: App {
    static let supportedTypes: [UTType] = {
        var types: [UTType] = [.pdf, .rtf, .html, .plainText, .text]
        types += [
            UTType("org.openxmlformats.wordprocessingml.document"),
            UTType("org.oasis-open.opendocument.text"),
            UTType("com.microsoft.word.docx")
        ].compactMap { $0 }
        return types
    }()

    var body: some Scene {
        WindowGroup("md_Hero") {
            ContentView()
                .frame(minWidth: 640, minHeight: 520)
        }
        .windowResizability(.contentMinSize)
    }
}
