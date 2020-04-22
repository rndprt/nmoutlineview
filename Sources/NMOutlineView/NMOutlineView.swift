//
//  NMOutlineView.swift
//
//  Created by Greg Kopel on 11/05/2017.
//  Copyright © 2017 Netmedia. All rights reserved.
//


import UIKit

/*
// MARK: - IndexPath convenience initializer

extension IndexPath {
    init(row index: Int) {
        self.init(row: index, section: 0)
    }
}

// MARK: - NMOutlineView Class
@objc(NMOutlineView)
@IBDesignable @objcMembers open class NMOutlineView: UITableView  {
    // MARK: Properties

    // Datasource for internal tableview
    @IBOutlet @objc dynamic open var datasource: OutlineCoordinatorOwner! {
        didSet {
            // Setup initial state
            oldTableViewDatasource = []
            self.restartDatasource()
        }
    }
    var coordinator : TableViewOutlineCoordinator!
    
    // Type property
    static public var cellIdentifier = "nmOutlineViewCell"
    
    // MARK: Initializers
    
    @objc private func sharedInit() {
    }
    
    
    @objc public override init(frame: CGRect, style: UITableView.Style) {
        super.init(frame: frame, style: style)
        sharedInit()
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
    
    
    open func selectCell(_ cell: NMOutlineViewCell, animated: Bool, scrollPosition: UITableView.ScrollPosition = .top) {
        guard let tableIndexPath = super.indexPath(for: cell) else { return }
        super.selectRow(at: tableIndexPath, animated: animated, scrollPosition: scrollPosition)
    }

    open func deselectCell(_ cell: NMOutlineViewCell, animated: Bool) {
        guard let tableIndexPath = super.indexPath(for: cell) else { return }
        super.deselectRow(at: tableIndexPath, animated: animated)
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
}

private extension IndexPath {
    func hasPrefix(_ indexPath : IndexPath) -> Bool {
        if self.count <= indexPath.count { return false }
        return self[0..<indexPath.count] == indexPath
    }
    func allParents(includeSelf: Bool = false) -> [IndexPath] {
        guard count > 0 else {
            return includeSelf ? [self] : []
        }
        var ips : [IndexPath] = []
        (1..<(count)).forEach {
            ips.append(self[0..<$0])
        }
        if includeSelf {
            ips.append(self)
        }
        return ips
    }
}

*/
