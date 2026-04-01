import AppKit

protocol ShelfItemCellDelegate: AnyObject {
    func cellRequestsRemoval(_ cell: ShelfItemCell)
}

final class ShelfItemCell: NSCollectionViewItem {

    static let identifier = NSUserInterfaceItemIdentifier("ShelfItemCell")

    weak var delegate: ShelfItemCellDelegate?
    private(set) var shelfItem: ShelfItem?

    // MARK: - Subviews

    private let iconView    = NSImageView()
    private let nameLabel   = NSTextField()
    private let deleteBtn   = NSButton()
    private var trackArea:  NSTrackingArea?

    // MARK: - View lifecycle

    override func loadView() {
        let v = NSView()
        v.wantsLayer = true
        view = v
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupSubviews()
    }

    // MARK: - Layout

    private func setupSubviews() {
        view.layer?.cornerRadius = 8
        view.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor

        iconView.imageScaling = .scaleProportionallyUpOrDown
        iconView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(iconView)

        nameLabel.isEditable   = false
        nameLabel.isBordered   = false
        nameLabel.drawsBackground = false
        nameLabel.alignment    = .center
        nameLabel.font         = .systemFont(ofSize: 11)
        nameLabel.lineBreakMode = .byTruncatingMiddle
        nameLabel.maximumNumberOfLines = 2
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(nameLabel)

        deleteBtn.bezelStyle = .circular
        deleteBtn.isBordered = false
        deleteBtn.image = NSImage(systemSymbolName: "xmark.circle.fill",
                                  accessibilityDescription: "Remove")
        deleteBtn.contentTintColor = .secondaryLabelColor
        deleteBtn.isHidden  = true
        deleteBtn.target    = self
        deleteBtn.action    = #selector(removeSelf)
        deleteBtn.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(deleteBtn)

        NSLayoutConstraint.activate([
            iconView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            iconView.topAnchor.constraint(equalTo: view.topAnchor, constant: 8),
            iconView.widthAnchor.constraint(equalToConstant: 52),
            iconView.heightAnchor.constraint(equalToConstant: 52),

            nameLabel.topAnchor.constraint(equalTo: iconView.bottomAnchor, constant: 4),
            nameLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 4),
            nameLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -4),
            nameLabel.bottomAnchor.constraint(lessThanOrEqualTo: view.bottomAnchor, constant: -4),

            deleteBtn.topAnchor.constraint(equalTo: view.topAnchor, constant: 2),
            deleteBtn.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -2),
            deleteBtn.widthAnchor.constraint(equalToConstant: 18),
            deleteBtn.heightAnchor.constraint(equalToConstant: 18),
        ])
    }

    // MARK: - Configure

    func configure(with item: ShelfItem) {
        shelfItem = item
        iconView.image      = item.icon
        nameLabel.stringValue = item.name
    }

    // MARK: - Hover feedback

    override func viewDidLayout() {
        super.viewDidLayout()
        refreshTrackingArea()
    }

    private func refreshTrackingArea() {
        if let t = trackArea { view.removeTrackingArea(t) }
        trackArea = NSTrackingArea(rect: view.bounds,
                                   options: [.mouseEnteredAndExited, .activeAlways],
                                   owner: self, userInfo: nil)
        view.addTrackingArea(trackArea!)
    }

    override func mouseEntered(with event: NSEvent) {
        deleteBtn.isHidden = false
        view.layer?.backgroundColor = NSColor.selectedControlColor
            .withAlphaComponent(0.25).cgColor
    }

    override func mouseExited(with event: NSEvent) {
        deleteBtn.isHidden = true
        view.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
    }

    // MARK: - Removal

    @objc private func removeSelf() {
        delegate?.cellRequestsRemoval(self)
    }

    // MARK: - Context menu

    override func rightMouseDown(with event: NSEvent) {
        guard shelfItem != nil else { return }
        let menu = NSMenu()
        menu.addItem(withTitle: "Open",
                     action: #selector(openFile), keyEquivalent: "").target = self
        menu.addItem(withTitle: "Reveal in Finder",
                     action: #selector(revealInFinder), keyEquivalent: "").target = self
        menu.addItem(.separator())
        menu.addItem(withTitle: "Remove from Shelf",
                     action: #selector(removeSelf), keyEquivalent: "").target = self
        NSMenu.popUpContextMenu(menu, with: event, for: view)
    }

    @objc private func openFile() {
        guard let url = shelfItem?.url else { return }
        NSWorkspace.shared.open(url)
    }

    @objc private func revealInFinder() {
        guard let url = shelfItem?.url else { return }
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }

    // MARK: - Drag source

    override func mouseDragged(with event: NSEvent) {
        guard let item = shelfItem else { return }
        let dragItem = NSDraggingItem(pasteboardWriter: item.url as NSURL)
        dragItem.setDraggingFrame(
            NSRect(origin: .zero, size: NSSize(width: 52, height: 52)),
            contents: item.icon
        )
        let session = view.beginDraggingSession(with: [dragItem], event: event, source: self)
        session.animatesToStartingPositionsOnCancelOrFail = true
    }
}

// MARK: - NSDraggingSource

extension ShelfItemCell: NSDraggingSource {

    func draggingSession(_ session: NSDraggingSession,
                         sourceOperationMaskFor context: NSDraggingContext) -> NSDragOperation {
        context == .outsideApplication ? .copy : .move
    }

    func draggingSession(_ session: NSDraggingSession,
                         endedAt screenPoint: NSPoint,
                         operation: NSDragOperation) {
        // Remove from shelf after any successful drop
        if operation != [] {
            DispatchQueue.main.async { self.delegate?.cellRequestsRemoval(self) }
        }
    }
}
