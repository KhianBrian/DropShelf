import AppKit

/// The main content view of the shelf window.
/// It acts as a drag-and-drop destination and hosts an NSCollectionView
/// that renders ShelfItemCells.
final class ShelfView: NSView {

    // MARK: - State

    private var items: [ShelfItem] = []

    // MARK: - Subviews

    private var scrollView:      NSScrollView!
    private var collectionView:  NSCollectionView!
    private var emptyLabel:      NSTextField!
    private var clearButton:     NSButton!

    // MARK: - Init

    override init(frame: NSRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    // MARK: - Setup

    private func setup() {
        wantsLayer = true
        layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor

        setupHeader()
        setupCollectionView()
        setupEmptyLabel()
        setupDropTarget()
        updateEmptyState()
    }

    private func setupHeader() {
        let header = NSView()
        header.wantsLayer = true
        header.translatesAutoresizingMaskIntoConstraints = false
        addSubview(header)

        let title = NSTextField(labelWithString: "DropShelf")
        title.font         = .boldSystemFont(ofSize: 13)
        title.textColor    = .labelColor
        title.translatesAutoresizingMaskIntoConstraints = false
        header.addSubview(title)

        clearButton = NSButton(title: "Clear", target: self, action: #selector(clearAll))
        clearButton.bezelStyle = .inline
        clearButton.font       = .systemFont(ofSize: 11)
        clearButton.translatesAutoresizingMaskIntoConstraints = false
        header.addSubview(clearButton)

        let sep = NSBox()
        sep.boxType = .separator
        sep.translatesAutoresizingMaskIntoConstraints = false
        addSubview(sep)

        NSLayoutConstraint.activate([
            header.topAnchor.constraint(equalTo: topAnchor),
            header.leadingAnchor.constraint(equalTo: leadingAnchor),
            header.trailingAnchor.constraint(equalTo: trailingAnchor),
            header.heightAnchor.constraint(equalToConstant: 38),

            title.leadingAnchor.constraint(equalTo: header.leadingAnchor, constant: 12),
            title.centerYAnchor.constraint(equalTo: header.centerYAnchor),

            clearButton.trailingAnchor.constraint(equalTo: header.trailingAnchor, constant: -8),
            clearButton.centerYAnchor.constraint(equalTo: header.centerYAnchor),

            sep.topAnchor.constraint(equalTo: header.bottomAnchor),
            sep.leadingAnchor.constraint(equalTo: leadingAnchor),
            sep.trailingAnchor.constraint(equalTo: trailingAnchor),
            sep.heightAnchor.constraint(equalToConstant: 1),
        ])
    }

    private func setupCollectionView() {
        let layout = NSCollectionViewFlowLayout()
        layout.itemSize              = NSSize(width: 82, height: 95)
        layout.minimumInteritemSpacing = 6
        layout.minimumLineSpacing    = 6
        layout.sectionInset          = NSEdgeInsets(top: 10, left: 8, bottom: 10, right: 8)

        collectionView = NSCollectionView()
        collectionView.collectionViewLayout    = layout
        collectionView.dataSource              = self
        collectionView.delegate               = self
        collectionView.isSelectable           = true
        collectionView.allowsMultipleSelection = false
        collectionView.backgroundColors       = [.clear]
        collectionView.register(ShelfItemCell.self,
                                forItemWithIdentifier: ShelfItemCell.identifier)

        scrollView = NSScrollView()
        scrollView.documentView     = collectionView
        scrollView.hasVerticalScroller = true
        scrollView.drawsBackground  = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(scrollView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: topAnchor, constant: 39),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    private func setupEmptyLabel() {
        emptyLabel = NSTextField(labelWithString: "Shake cursor while dragging\nor drop files here")
        emptyLabel.alignment   = .center
        emptyLabel.textColor   = .tertiaryLabelColor
        emptyLabel.font        = .systemFont(ofSize: 12)
        emptyLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(emptyLabel)

        NSLayoutConstraint.activate([
            emptyLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: centerYAnchor, constant: 20),
            emptyLabel.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 16),
            emptyLabel.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -16),
        ])
    }

    private func setupDropTarget() {
        registerForDraggedTypes([
            .fileURL,
            NSPasteboard.PasteboardType("public.file-url"),
            NSPasteboard.PasteboardType("public.url"),
        ])
    }

    // MARK: - Empty state

    private func updateEmptyState() {
        let empty = items.isEmpty
        emptyLabel.isHidden      = !empty
        collectionView.isHidden  = empty
        clearButton.isEnabled    = !empty
    }

    // MARK: - Public API

    @objc func clearAll() {
        items.removeAll()
        collectionView.reloadData()
        updateEmptyState()
    }

    // MARK: - Drop target highlight

    private func setDropHighlight(_ on: Bool) {
        layer?.borderColor  = on ? NSColor.controlAccentColor.cgColor : nil
        layer?.borderWidth  = on ? 2 : 0
        layer?.cornerRadius = on ? 6 : 0
    }

    // MARK: - NSDraggingDestination

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        setDropHighlight(true)
        return .copy
    }

    override func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
        return .copy
    }

    override func draggingExited(_ sender: NSDraggingInfo?) {
        setDropHighlight(false)
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        setDropHighlight(false)

        let pb = sender.draggingPasteboard
        guard let urls = pb.readObjects(
            forClasses: [NSURL.self],
            options: [.urlReadingFileURLsOnly: true]
        ) as? [URL], !urls.isEmpty else { return false }

        let start = items.count
        items.append(contentsOf: urls.map { ShelfItem(url: $0) })
        collectionView.performBatchUpdates {
            let paths = Set((start ..< items.count).map { IndexPath(item: $0, section: 0) })
            collectionView.insertItems(at: paths)
        }
        updateEmptyState()
        return true
    }

    // MARK: - Item removal

    fileprivate func removeItem(id: UUID) {
        guard let idx = items.firstIndex(where: { $0.id == id }) else { return }
        items.remove(at: idx)
        collectionView.performBatchUpdates {
            collectionView.deleteItems(at: [IndexPath(item: idx, section: 0)])
        }
        updateEmptyState()
    }
}

// MARK: - NSCollectionViewDataSource

extension ShelfView: NSCollectionViewDataSource {

    func collectionView(_ collectionView: NSCollectionView,
                        numberOfItemsInSection section: Int) -> Int {
        items.count
    }

    func collectionView(_ collectionView: NSCollectionView,
                        itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        let cell = collectionView.makeItem(withIdentifier: ShelfItemCell.identifier,
                                           for: indexPath) as! ShelfItemCell
        cell.configure(with: items[indexPath.item])
        cell.delegate = self
        return cell
    }
}

// MARK: - NSCollectionViewDelegate

extension ShelfView: NSCollectionViewDelegate {}

// MARK: - ShelfItemCellDelegate

extension ShelfView: ShelfItemCellDelegate {
    func cellRequestsRemoval(_ cell: ShelfItemCell) {
        guard let id = cell.shelfItem?.id else { return }
        removeItem(id: id)
    }
}
