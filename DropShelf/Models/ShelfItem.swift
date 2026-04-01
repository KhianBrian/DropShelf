import AppKit

struct ShelfItem {
    let id: UUID
    let url: URL

    init(url: URL) {
        self.id = UUID()
        self.url = url
    }

    var name: String { url.lastPathComponent }

    var icon: NSImage { NSWorkspace.shared.icon(forFile: url.path) }

    var isDirectory: Bool {
        (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
    }
}
