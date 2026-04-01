import AppKit

// MARK: - Stack Layout

/// Fans items like a deck of cards stacked in the centre of the view.
final class StackLayout: NSCollectionViewLayout {

    private var cache: [NSCollectionViewLayoutAttributes] = []

    override func prepare() {
        super.prepare()
        guard let cv = collectionView else { return }
        let count = cv.numberOfItems(inSection: 0)
        let size  = NSSize(width: 80, height: 80)
        let cx    = cv.bounds.midX
        let cy    = cv.bounds.midY + 10

        cache = (0..<count).map { i in
            let attr   = NSCollectionViewLayoutAttributes(
                forItemWith: IndexPath(item: i, section: 0))
            let spread = CGFloat(i) - CGFloat(count - 1) / 2.0
            let xShift = spread * 6
            attr.frame = CGRect(
                x: cx - size.width  / 2 + xShift,
                y: cy - size.height / 2,
                width:  size.width,
                height: size.height)
            attr.zIndex = i
            return attr
        }
    }

    override var collectionViewContentSize: NSSize {
        collectionView?.bounds.size ?? .zero
    }

    override func layoutAttributesForElements(in rect: NSRect)
        -> [NSCollectionViewLayoutAttributes] { cache }

    override func layoutAttributesForItem(at indexPath: IndexPath)
        -> NSCollectionViewLayoutAttributes? {
        guard indexPath.item < cache.count else { return nil }
        return cache[indexPath.item]
    }

    override func shouldInvalidateLayout(forBoundsChange newBounds: NSRect) -> Bool { true }
}

// MARK: - ShelfView

final class ShelfView: NSView {

    // MARK: - State

    private var items: [ShelfItem] = []

    // MARK: - Subviews

    private var collectionView: NSCollectionView!
    private var emptyLabel:     NSTextField!
    private var countBadge:     NSTextField!
    private var clearButton:    NSButton!

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
        title.font      = .boldSystemFont(ofSize: 13)
        title.textColor = .labelColor
        title.translatesAutoresizingMaskIntoConstraints = false
        header.addSubview(title)

        countBadge = NSTextField(labelWithString: "")
        countBadge.font            = .boldSystemFont(ofSize: 10)
        countBadge.textColor       = .white
        countBadge.alignment       = .center
        countBadge.wantsLayer      = true
        countBadge.isHidden        = true
        countBadge.translatesAutoresizingMaskIntoConstraints = false
        header.addSubview(countBadge)

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

            title.centerXAnchor.constraint(equalTo: header.centerXAnchor),
            title.centerYAnchor.constraint(equalTo: header.centerYAnchor),

            countBadge.leadingAnchor.constraint(equalTo: title.trailingAnchor, constant: 4),
            countBadge.centerYAnchor.constraint(equalTo: header.centerYAnchor),
            countBadge.widthAnchor.constraint(greaterThanOrEqualToConstant: 18),
            countBadge.heightAnchor.constraint(equalToConstant: 18),

            clearButton.trailingAnchor.constraint(equalTo: header.trailingAnchor, constant: -8),
            clearButton.centerYAnchor.constraint(equalTo: header.centerYAnchor),

            sep.topAnchor.constraint(equalTo: header.bottomAnchor),
            sep.leadingAnchor.constraint(equalTo: leadingAnchor),
            sep.trailingAnchor.constraint(equalTo: trailingAnchor),
            sep.heightAnchor.constraint(equalToConstant: 1),
        ])
    }

    private func setupCollectionView() {
        collectionView = NSCollectionView()
        collectionView.collectionViewLayout    = StackLayout()
        collectionView.dataSource              = self
        collectionView.delegate               = self
        collectionView.isSelectable           = true
        collectionView.allowsMultipleSelection = true
        collectionView.backgroundColors       = [.clear]
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.register(ShelfItemCell.self,
                                forItemWithIdentifier: ShelfItemCell.identifier)
        addSubview(collectionView)

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: topAnchor, constant: 39),
            collectionView.leadingAnchor.constraint(equalTo: leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: bottomAnchor),
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
        ])
    }

    // MARK: - Empty state

    private func updateEmptyState() {
        let empty = items.isEmpty
        emptyLabel.isHidden     = !empty
        collectionView.isHidden = empty
        clearButton.isEnabled   = !empty

        countBadge.isHidden     = empty || items.count < 2
        countBadge.stringValue  = "\(items.count)"
        countBadge.layer?.backgroundColor = NSColor.controlAccentColor.cgColor
        countBadge.layer?.cornerRadius    = 9
    }

    // MARK: - Public API

    @objc func clearAll() {
        items.removeAll()
        collectionView.reloadData()
        updateEmptyState()
    }

    // MARK: - Drop highlight

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

    override func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation { .copy }

    override func draggingExited(_ sender: NSDraggingInfo?) { setDropHighlight(false) }

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
            let paths = Set((start..<items.count).map { IndexPath(item: $0, section: 0) })
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
                        numberOfItemsInSection section: Int) -> Int { items.count }

    func collectionView(_ collectionView: NSCollectionView,
                        itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        let cell  = collectionView.makeItem(withIdentifier: ShelfItemCell.identifier,
                                            for: indexPath) as! ShelfItemCell
        let count = items.count
        let spread = CGFloat(indexPath.item) - CGFloat(count - 1) / 2.0
        let angle  = spread * 0.06
        cell.configure(with: items[indexPath.item], angle: angle)
        cell.delegate = self
        return cell
    }
}

// MARK: - NSCollectionViewDelegate

extension ShelfView: NSCollectionViewDelegate {}

// MARK: - Drag-all from ShelfView

extension ShelfView {

    fileprivate func beginDragAll(event: NSEvent) {
        guard !items.isEmpty else { return }
        let dragItems = items.map { item -> NSDraggingItem in
            let di = NSDraggingItem(pasteboardWriter: item.url as NSURL)
            di.setDraggingFrame(NSRect(x: 0, y: 0, width: 64, height: 64),
                                contents: item.icon)
            return di
        }
        let session = beginDraggingSession(with: dragItems, event: event, source: self)
        session.animatesToStartingPositionsOnCancelOrFail = true
    }
}

extension ShelfView: NSDraggingSource {

    func draggingSession(_ session: NSDraggingSession,
                         sourceOperationMaskFor context: NSDraggingContext) -> NSDragOperation {
        context == .outsideApplication ? .copy : .move
    }

    func draggingSession(_ session: NSDraggingSession,
                         endedAt screenPoint: NSPoint,
                         operation: NSDragOperation) {
        guard operation != [] else { return }
        items.removeAll()
        collectionView.reloadData()
        updateEmptyState()
    }
}

// MARK: - ShelfItemCellDelegate

extension ShelfView: ShelfItemCellDelegate {
    func cellRequestsRemoval(_ cell: ShelfItemCell) {
        guard let id = cell.shelfItem?.id else { return }
        removeItem(id: id)
    }

    func cellBeganDrag(_ cell: ShelfItemCell, event: NSEvent) {
        beginDragAll(event: event)
    }
}
