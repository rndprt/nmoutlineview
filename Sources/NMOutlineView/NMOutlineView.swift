//
//  NMOutlineView.swift
//
//  Created by Greg Kopel on 11/05/2017.
//  Copyright © 2017 Netmedia. All rights reserved.
//


import UIKit


// MARK: - IndexPath convenience initializer

extension IndexPath {
    init(row index: Int) {
        self.init(row: index, section: 0)
    }
}


// MARK:- NMOutlineDatasource Protocol
@objc(NMOutlineViewDatasource)
public protocol NMOutlineViewDatasource: UIScrollViewDelegate {
    // Required
    @objc func outlineView(_ outlineView: NMOutlineView, numberOfChildrenOfItem item: Any?) -> Int
    @objc func outlineView(_ outlineView: NMOutlineView, isItemExpandable item: Any) -> Bool
    @objc func outlineView(_ outlineView: NMOutlineView, cellFor item: Any) -> NMOutlineViewCell
    @objc func outlineView(_ outlineView: NMOutlineView, child index: Int, ofItem item: Any?)->Any

    // Selection
    @objc optional func outlineView(_ outlineView: NMOutlineView, shouldHighlight cell: NMOutlineViewCell) -> Bool
    @objc optional func outlineView(_ outlineView: NMOutlineView, didSelect cell: NMOutlineViewCell)
    
    // Expansion
    @objc optional func outlineView(_ outlineView: NMOutlineView, shouldExpandItem item: Any) -> Bool
    @objc optional func outlineView(_ outlineView: NMOutlineView, willExpandItem item: Any)
    @objc optional func outlineView(_ outlineView: NMOutlineView, didExpandItem item: Any)
    @objc optional func outlineView(_ outlineView: NMOutlineView, willCollapseItem item: Any)
    @objc optional func outlineView(_ outlineView: NMOutlineView, didCollapseItem item: Any)

    // Others
    @objc optional func outlineView(_ outlineView: NMOutlineView, heightForItem item: Any) -> CGFloat

    @available(iOS 13, *)
    @objc optional func outlineView(_ outlineView: NMOutlineView, contextMenuConfigurationForCell cell: NMOutlineViewCell, point: CGPoint) -> UIContextMenuConfiguration?
}


// MARK: - NMOutlineView Class
@objc(NMOutlineView)
@IBDesignable @objcMembers open class NMOutlineView: UITableView  {
    // MARK: Properties

    // Datasource for internal tableview
    @IBOutlet @objc dynamic open var datasource: NMOutlineViewDatasource! {
        didSet {
            // Setup initial state
            oldTableViewDatasource = []
            self.restartDatasource()
        }
    }

    private func restartDatasource() {
        tableViewDatasource = []
        if let datasource = datasource {
            let rootItemsCount = datasource.outlineView(self, numberOfChildrenOfItem: nil)
            for index in 0 ..< rootItemsCount {
                let item = datasource.outlineView(self, child: index, ofItem: nil)
                let nmItem = NMNode(withItem: item, at: IndexPath(index: index), ofParent: nil, isExpanded: false)
                tableViewDatasource.append(nmItem)
            }
        }
        super.reloadData()
    }
    
    
    // Single item in the collection
    @objc open class NMNode: NSObject  {
        @objc dynamic public var item: Any
        @objc dynamic public var indexPath: IndexPath
        @objc dynamic public var isExpanded = false
        @objc dynamic public var parent: NMNode?
        @objc dynamic public var level: Int  {
            return indexPath.count - 1
        }
        
        public init(withItem item: Any, at indexPath: IndexPath, ofParent parent: NMNode?, isExpanded expanded:Bool) {
            self.item = item
            self.indexPath = indexPath
            self.isExpanded = expanded
            self.parent = parent
            super.init()
        }
    }
    
    // Type property
    static public var cellIdentifier = "nmOutlineViewCell"

    @IBInspectable @objc public dynamic var maintainExpandedItems: Bool = false
    @IBInspectable @objc public dynamic var maintainSection: Bool = false

    private var oldTableViewDatasource = [NMNode]()
    @objc dynamic private var tableViewDatasource = [NMNode]()
    
    // MARK: Initializers
    
    @objc private func sharedInit() {
        super.dataSource = self
        super.delegate = self
        self.separatorStyle = .none
        self.separatorInset = .zero
        self.register(NMOutlineViewCell.self, forCellReuseIdentifier: NMOutlineView.cellIdentifier)
        self.register(UINib(nibName: "NMOutlineViewCell", bundle: nil), forCellReuseIdentifier: NMOutlineView.cellIdentifier)
    }
    
    
    @objc public override init(frame: CGRect, style: UITableView.Style) {
        super.init(frame: frame, style: style)
        sharedInit()
        //let cell = NMOutlineViewCell(style: .default, reuseIdentifier: NMOutlineView.cellIdentifier)
        //self.addSubview(cell)
    }
    
    
    @objc required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
    }
    
    
    @objc override open func awakeFromNib() {
        super.awakeFromNib()
        sharedInit()
    }
    
    
    // MARK: NMOutlineView methods
    
    @objc open func dequeReusableCell(withIdentifier identifier: String, style: UITableViewCell.CellStyle) -> NMOutlineViewCell {
        guard let cell = super.dequeueReusableCell(withIdentifier: identifier) as? NMOutlineViewCell
            else { return NMOutlineViewCell(style: style, reuseIdentifier: identifier) }
        return cell
    }
    
    
    @objc open func locationForPress(_ sender: UILongPressGestureRecognizer) -> CGPoint {
        return sender.location(in: self)
    }
    
    
    @objc open func cellAtPoint(_ point: CGPoint) -> NMOutlineViewCell? {
        return super.cellForRow(at: super.indexPathForRow(at: point) ?? IndexPath()) as? NMOutlineViewCell
    }
    
    
    @objc open override func cellForRow(at indexPath: IndexPath) -> NMOutlineViewCell? {
         guard let index = tableViewDatasource.firstIndex(where: {$0.indexPath == indexPath }) else { return nil }
        return super.cellForRow(at: IndexPath(row: index, section: 0)) as? NMOutlineViewCell
    }
    
    open func cellForItem<T: Equatable>(_ item: T) -> NMOutlineViewCell? {
        guard let index = tableViewDatasource.firstIndex(where: {$0.item as? T == item }) else { return nil }
        return super.cellForRow(at: IndexPath(row: index, section: 0)) as? NMOutlineViewCell
    }
    
    open func firstCellForItem(where closure : ((Any)->(Bool)) ) -> NMOutlineViewCell? {
        guard let index = tableViewDatasource.firstIndex(where: { closure($0.item) }) else { return nil }
        return super.cellForRow(at: IndexPath(row: index, section: 0)) as? NMOutlineViewCell
    }

    
    @objc open func indexPathforCell(at point:CGPoint) -> IndexPath? {
        return super.indexPathForRow(at: point)
    }
    
    
    @objc open func indexPath(for cell: NMOutlineViewCell) -> IndexPath? {
        guard let tableIndexPath = super.indexPath(for: cell) else { return nil}
        return tableViewDatasource[tableIndexPath.row].indexPath
    }
    
    open func tableViewIndex(for cell: NMOutlineViewCell) -> Int? {
        guard let tableIndexPath = super.indexPath(for: cell) else { return nil}
        return tableIndexPath.row
    }
    
    open var selectedCell : NMOutlineViewCell? {
        guard let tableIndexPath = super.indexPathForSelectedRow else { return nil }
        return super.cellForRow(at: tableIndexPath) as? NMOutlineViewCell
        
    }
    
    open func selectCell(_ cell: NMOutlineViewCell, animated: Bool, scrollPosition: UITableView.ScrollPosition = .top) {
        guard let tableIndexPath = super.indexPath(for: cell) else { return }
        super.selectRow(at: tableIndexPath, animated: animated, scrollPosition: scrollPosition)
    }

    open func deselectCell(_ cell: NMOutlineViewCell, animated: Bool) {
        guard let tableIndexPath = super.indexPath(for: cell) else { return }
        super.deselectRow(at: tableIndexPath, animated: animated)
    }
    
    open func toggleCellExpansion(_ cell: NMOutlineViewCell) {
        let _: NSObject? = toggleNode(cell.node)
    }
    
    @objc open override func insertRows(at indexPaths: [IndexPath], with animation: UITableView.RowAnimation) {
        var tableIndexPaths = Array<IndexPath>()
        for indexPath in indexPaths {
            if !(tableViewDatasource.contains(where: {$0.indexPath == indexPath})) {
                if let parentIndex = tableViewDatasource.firstIndex(where: { $0.indexPath == indexPath.dropLast() }),
                    let parentNode = tableViewDatasource.first(where: { $0.indexPath == indexPath.dropLast() }),
                    parentNode.isExpanded,
                    indexPath.last ?? Int.max <= datasource.outlineView(self, numberOfChildrenOfItem: parentNode.item) - 1,
                    parentIndex + (indexPath.last ?? Int.max) <= tableViewDatasource.count {
                    let childItem = datasource.outlineView(self, child: indexPath.last!, ofItem: parentNode.item)
                    let item = NMNode(withItem: childItem, at: indexPath, ofParent: parentNode, isExpanded: false)
                    tableViewDatasource.insert(item, at: parentIndex + indexPath.last! + 1)
                    tableIndexPaths.append(IndexPath(row: parentIndex + indexPath.last! + 1))
                }
            }
        }
        super.insertRows(at: tableIndexPaths, with: animation)
    }
    
    
    @objc open override func deleteRows(at indexPaths: [IndexPath], with animation: UITableView.RowAnimation) {
        var tableIndexPaths = Array<IndexPath>()
        for indexPath in indexPaths {
            if let index = tableViewDatasource.firstIndex(where: {$0.indexPath == indexPath}) {
                tableViewDatasource.remove(at: index)
                tableIndexPaths.append(IndexPath(row: index))
            }
        }
        super.deleteRows(at: tableIndexPaths, with: animation)
    }
    
    
    @objc open override func reloadRows(at indexPaths: [IndexPath], with animation: UITableView.RowAnimation = .none) {
        var tableIndexPaths = [IndexPath]()
        for indexPath in indexPaths {
            guard let node = tableViewDatasource.first(where: {$0.indexPath == indexPath }),
                let cell = self.cellForRow(at: indexPath) else { continue }
            if animation != .none ,
                let index = tableViewDatasource.firstIndex(of: node) {
                tableIndexPaths.append(IndexPath(row: index))
            } else {
                if Mirror(reflecting: node.item).displayStyle != .class {
                    node.item = datasource.outlineView(self, child: indexPath.last!, ofItem: node.parent)
                }
                cell.update(with: node.item)
            }
        }
        if !tableIndexPaths.isEmpty {
            super.reloadRows(at: tableIndexPaths, with: animation)
        }
    }
    
    private func reloadItems<T: Equatable>()->T? {
        if !tableViewDatasource.isEmpty && maintainExpandedItems {
            oldTableViewDatasource = tableViewDatasource.filter({$0.isExpanded})
        }
        self.restartDatasource()
        for node in Array(tableViewDatasource) {
            if shouldExpandItem(node.item as? T) {
                let _: T? = self.expandNode(node, isUserInitiated: false)
            }
        }
        oldTableViewDatasource = []
        return nil
    }
    
    private func shouldExpandItem<T: Equatable>(_ item : T) -> Bool {
        if let shouldExpand = datasource.outlineView?(self, shouldExpandItem: item) {
            return shouldExpand && datasource.outlineView(self, isItemExpandable: item)
        }
        if maintainExpandedItems, let previous = oldTableViewDatasource.firstIndex(where: {$0.item as? T == item }) {
            return oldTableViewDatasource[previous].isExpanded
        }
        return false
    }
    
    
    @objc open override func reloadData() {
        let _: NSObject? = self.reloadItems() as NSObject?
    }
    
    
    fileprivate func toggleNode<T:Equatable>(_ node: NMNode)->T? {
        if node.isExpanded {
            return collapseNode(node, isUserInitiated: true)
        } else {
            return expandNode(node, isUserInitiated: true)
        }
    }
    
    fileprivate func expandNode<T:Equatable>(_ node: NMNode, isUserInitiated: Bool)->T? {
        guard let datasource = self.datasource,
            let index = tableViewDatasource.firstIndex(of: node) else { return nil}
        
        if datasource.outlineView(self, isItemExpandable: node.item) {
            if isUserInitiated {
                datasource.outlineView?(self, willExpandItem: node.item)
            }
            node.isExpanded = true
            var childrenCount = datasource.outlineView(self, numberOfChildrenOfItem: node.item)
            let nodeIndexPath = node.indexPath
            while childrenCount > 0 {
                var itemIndexPath = IndexPath(indexes: nodeIndexPath)
                itemIndexPath.append(childrenCount - 1)
                let childItem = datasource.outlineView(self, child: childrenCount - 1, ofItem: node.item)
                let newNode = NMNode(withItem: childItem, at: itemIndexPath, ofParent: node, isExpanded: false)
                tableViewDatasource.insert(newNode, at: index + 1)
                super.insertRows(at: [IndexPath(row: index + 1, section: 0)], with: .fade)
                if shouldExpandItem(childItem as? T) {
                    let _: NSObject? = self.expandNode(newNode, isUserInitiated: false)
                }
                childrenCount -= 1
                if isUserInitiated {
                    datasource.outlineView?(self, didExpandItem: node.item)
                }
            }
        } else {
            print("ERROR: NMOutlineView cell is NOT expandable")
        }

        return nil
    }
    fileprivate func collapseNode<T:Equatable>(_ node: NMNode, isUserInitiated: Bool)->T? {
        guard let datasource = self.datasource,
            let index = tableViewDatasource.firstIndex(of: node) else { return nil}

        if isUserInitiated {
            datasource.outlineView?(self, willCollapseItem: node.item)
        }
        let childrenCount = datasource.outlineView(self, numberOfChildrenOfItem: node.item)
        node.isExpanded = false
        if childrenCount > 0 {
            var tableViewIndexPaths = [IndexPath]()
            var indexes = IndexSet()
            for i in 0..<childrenCount
            {
                let childrenNode = tableViewDatasource[index + i + 1]
                if childrenNode.isExpanded {
                    let _: NSObject? = self.toggleNode(childrenNode)
                }
                 let tableViewIndexPath = IndexPath(row: index + i + 1, section: 0)
                tableViewIndexPaths.append(tableViewIndexPath)
                indexes.insert(index + i + 1)
            }
            if !tableViewIndexPaths.isEmpty {
                while let index = indexes.last {
                    tableViewDatasource.remove(at: index)
                    indexes = IndexSet(indexes.dropLast())
                }
                super.deleteRows(at: tableViewIndexPaths, with: .fade)
            }
            if isUserInitiated {
                datasource.outlineView?(self, didCollapseItem: node.item)
            }

        } else {
            print("ERROR: NMOutlineView cell is NOT collapsable")
        }

        return nil
    }
}

// MARK: - Internal TableView datasource/delegate
extension NMOutlineView: UITableViewDataSource, UITableViewDelegate {
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        datasource?.scrollViewDidScroll?(scrollView)
    }
    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        datasource?.scrollViewDidEndDragging?(scrollView, willDecelerate: decelerate)
    }

    @objc public func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    
    @objc public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableViewDatasource.count
    }
    
    
    @objc public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let datasource = self.datasource else {
            print("ERROR: no NMOutlineView datasource defined.")
            return NMOutlineViewCell(style: .default, reuseIdentifier: "ErrorCell")
        }
        let node = tableViewDatasource[indexPath.row]
        let theCell = datasource.outlineView(self, cellFor: node.item)
        theCell.isExpanded = node.isExpanded
        theCell.node = node
        theCell.nmIndentationLevel = node.level
        theCell.toggleButton.isHidden = !datasource.outlineView(self, isItemExpandable: node.item)
        theCell.onToggle = { (sender) in
            let _:NSObject? = self.toggleNode(node)
        }
        theCell.update(with: node.item)
        return theCell
    }
    
    
    @objc public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let datasource = self.datasource else {
            print("ERROR: no NMOutlineView datasource defined.")
            return
        }
        guard let cell = super.cellForRow(at: indexPath) as? NMOutlineViewCell
            else {
                print("ERROR: unable to find cell at NMOutlineView.tableView IndexPath")
                return
        }
        datasource.outlineView?(self, didSelect: cell)
    }
    
    @objc public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let rowHeight = tableView.rowHeight
        guard let datasource = self.datasource else {
            print("ERROR: no NMOutlineView datasource defined.")
            return rowHeight
        }
        return datasource.outlineView?(self, heightForItem: tableViewDatasource[indexPath.row].item) ?? rowHeight
    }

    @objc public func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        guard let datasource = self.datasource else {
            print("ERROR: no NMOutlineView datasource defined.")
            return true
        }
        guard let cell = super.cellForRow(at: indexPath) as? NMOutlineViewCell
            else {
                print("ERROR: unable to find cell at NMOutlineView.tableView IndexPath")
                return true
        }
        return datasource.outlineView?(self, shouldHighlight: cell) ?? true
    }
    
    @available(iOS 13, *)
    public func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        guard let datasource = self.datasource else {
            print("ERROR: no NMOutlineView datasource defined.")
            return nil
        }
        guard let cell = super.cellForRow(at: indexPath) as? NMOutlineViewCell
            else {
                print("ERROR: unable to find cell at NMOutlineView.tableView IndexPath")
                return nil
        }
        return datasource.outlineView?(self, contextMenuConfigurationForCell: cell, point: point)
    }
}


