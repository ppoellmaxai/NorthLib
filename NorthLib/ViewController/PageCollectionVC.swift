//
//  PageCollectionVC.swift
//
//  Created by Norbert Thies on 10.09.18.
//  Copyright © 2018 Norbert Thies. All rights reserved.
//

import UIKit

fileprivate var countVC = 0

/// An undefined View
open class UndefinedView: UIView {
  public var label = UILabel()
  
  private func setup() {
    backgroundColor = UIColor.red
    label.backgroundColor = UIColor.clear
    label.font = UIFont.boldSystemFont(ofSize: 200)
    label.textColor = UIColor.yellow
    label.textAlignment = .center
    label.adjustsFontSizeToFitWidth = true
    label.text = "?"
    addSubview(label)
    pin(label.centerX, to: self.centerX)
    pin(label.centerY, to: self.centerY)
    pin(label.width, to: self.width, dist: -20)
  }
  
  public override init(frame: CGRect) {
    super.init(frame: frame)
    setup()
  }
  
  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    setup()
  }
}

/// The View to put into one page
public protocol OptionalView {
  var mainView: UIView { get }
  var waitingView: UIView? { get }
  var isAvailable: Bool { get }
  func whenAvailable(closure: @escaping ()->())
  func loadView()
}

public extension OptionalView {
  var activeView: UIView { return isAvailable ? mainView : (waitingView ?? UndefinedView()) }
}

/// Common Views can be optional
extension UIView: OptionalView {
  public var mainView: UIView { return self }
  public var waitingView: UIView? { return nil }
  public var isAvailable: Bool { return true }
  public func whenAvailable(closure: @escaping () -> ()) {}
  public func loadView() {}
}

open class PageCollectionVC: UIViewController, UICollectionViewDelegate,
  UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UIScrollViewDelegate {
  
  class PageCell: UICollectionViewCell {
    
    /// The View to display
    var pageView: UIView?
    /// Index of View in collection view
    var index: Int?
    
    /// Request view from provider and put it into a PageCell
    func update(pcvc: PageCollectionVC, idx: Int) {
      if let provider = pcvc.provider {
        let page = provider(idx)
        let isAvailable = page.isAvailable
        let activeView = page.activeView
        if let pageView = self.pageView {
          pageView.removeFromSuperview()
        }
        self.pageView = activeView
        self.index = idx
        self.contentView.addSubview(activeView)
        pin(activeView, to: self.contentView)
        if isAvailable { page.loadView() }
        else {
          let iPath = IndexPath(item: idx, section: 0)
          page.whenAvailable { pcvc.collectionView.reloadItems(at: [iPath]) }
        }
      }
    }
    
    override init(frame: CGRect) {
      super.init(frame: frame)
    }
    init(view: UIView, index: Int) { 
      self.pageView = view
      self.index = index
      super.init(frame: CGRect())
    }    
    required init?(coder: NSCoder) {
      super.init(coder: coder)
    }
  }
  
  /// The collection view displaying OptionalViews
  open var collectionView: UICollectionView!

  /// A closure providing the optional views to display
  open var provider: ((Int)->OptionalView)? = nil
  
  /// inset from top/bottom/left/right as factor to min(width,height)
  open var inset = 0.025
  
  fileprivate var index2scrollTo: Int?  // index of page to scroll to
  fileprivate var cvSize: CGSize { return self.collectionView.bounds.size }
  fileprivate var onDisplayClosure: ((Int, OptionalView?)->())?
  
  // View which is currently displayed
  public var currentView: OptionalView?
  
  private var _index: Int?
  
  /// Index of current view, change it to scroll to a certain cell
  open var index: Int? {
    get { return _index }
    set(idx) { 
      if let idx = idx { 
        if let provider = self.provider {
          _index = idx
          currentView = provider(idx)
          scrollto(idx)
          if let closure = onDisplayClosure { closure(idx, currentView) }
        }
      } 
    }
  }

//  private func indexPath(cell: PageCell?) -> IndexPath?{ 
//    if let c = cell { return collectionView.indexPath(for: c) }
//    return nil
//  }
//  
//  /// IndexPath of current cell
//  open var indexPath: IndexPath? { return indexPath(cell: currentCell) }

  
  private var visibleCells: Set<PageCell> = []

  fileprivate var _count: Int = 0
  
  /// Define and change the number of views to display, will reload data
  open var count: Int {
    get { return _count }
    set { 
      _count = newValue
      collectionView.reloadData()
    }
  }
  
  private var reuseIdent: String = { countVC += 1; return "PageCell\(countVC)" }()
  
  public init() { super.init(nibName: nil, bundle: nil) }
  
  public required init?(coder: NSCoder) { super.init(coder: coder) }
  
  public func onDisplay(closure: ((Int, OptionalView?)->())?) {
    onDisplayClosure = closure
  }
 
  // updateDisplaying is called when the scrollview has been scrolled which
  // might have changed the view currently visible
  private func updateDisplaying() {
    debug("visible cells: \(visibleCells.map{$0.index})")
    if visibleCells.count == 1 {
      let vis = visibleCells.first!
      if vis.index != _index {
        debug("displaying page #\(vis.index!)")
        currentView = vis.pageView
        _index = vis.index
        if let closure = onDisplayClosure { closure(vis.index!, currentView) }
      }
      else {
        debug("Index of visible cell = \(vis.index ?? -1) - equal to current index (no update)")
      }
    }
    else { debug("#visible cells: \(visibleCells.count) (no update)") }
  }
  
  /// Defines the closure to deliver the views to display
  open func viewProvider(provider: @escaping (Int)->OptionalView) {
    self.provider = provider
  }
 
  /// Scroll to the view which index is given
  fileprivate func scrollto(_ index: Int, animated: Bool = false) {
    index2scrollTo = index
    if currentView != nil {
      let ipath = IndexPath(item: index, section: 0)
      collectionView.scrollToItem(at: ipath, at: .centeredHorizontally, animated: animated)
    }
  }

  // MARK: - Life Cycle

  override open func loadView() {
    super.loadView()
    let flowLayout = UICollectionViewFlowLayout()
    flowLayout.scrollDirection = .horizontal
    collectionView = UICollectionView(frame: .zero, collectionViewLayout: flowLayout)
    collectionView.backgroundColor = UIColor.white
    collectionView.contentInsetAdjustmentBehavior = .never
    self.view.addSubview(collectionView)
    pin(collectionView.top, to: self.view.topGuide())
    pin(collectionView.bottom, to: self.view.bottom)
    pin(collectionView.left, to: self.view.left)
    pin(collectionView.right, to: self.view.right)
    collectionView.register(PageCell.self, forCellWithReuseIdentifier: reuseIdent)
    collectionView.delegate = self
    collectionView.dataSource = self
    collectionView.isPagingEnabled = true
  }
  
  open override func viewDidLoad() {
    super.viewDidLoad()
    if count != 0 { collectionView.reloadData() }
  }
  
  // TODO: transition/rotation better with collectionViewLayout subclass as described in:
  // https://www.matrixprojects.net/p/uicollectionviewcell-dynamic-width/
  open override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
    super.willTransition(to: newCollection, with: coordinator)
    coordinator.animate(alongsideTransition: nil) { [weak self] ctx in
      self?.collectionView.collectionViewLayout.invalidateLayout()
    }
  }
  
  // MARK: - UICollectionViewDataSource
  
  open func numberOfSections(in collectionView: UICollectionView) -> Int {
    return 1
  }
  
  open func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return self.count
  }
  
  open func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdent,
                                                     for: indexPath) as? PageCell {
      let idx = indexPath.item
      cell.update(pcvc: self, idx: idx)
      if let i2s = index2scrollTo {
        if i2s == idx { index2scrollTo = nil }
        else {
          collectionView.scrollToItem(at: IndexPath(item: i2s, section: 0), 
            at: .centeredHorizontally, animated: false)
        }
      }
      else {
        if currentView == nil {
          currentView = cell.pageView
          _index = idx
        }
      }
      return cell
    }
    return PageCell()
  }
  
  // MARK: - UICollectionViewDelegate
  
  public func collectionView(_ view: UICollectionView, willDisplay: UICollectionViewCell, 
                             forItemAt: IndexPath) {
    visibleCells.insert(willDisplay as! PageCell)
    updateDisplaying()
  }
  
  public func collectionView(_ view: UICollectionView, didEndDisplaying: UICollectionViewCell, 
                             forItemAt: IndexPath) {
    visibleCells.remove(didEndDisplaying as! PageCell)
    updateDisplaying()
  }
  
  // MARK: - UICollectionViewDelegateFlowLayout
  
  private var margin: CGFloat {
    let s = cvSize
    return min(s.height, s.width) * CGFloat(inset)
  }
  
  private var cellsize: CGSize {
    let s = cvSize
    return CGSize(width: s.width - 2*margin, height: s.height - 2*margin)
  }
  
  public func collectionView(_ collectionView: UICollectionView, 
    layout collectionViewLayout: UICollectionViewLayout,
    sizeForItemAt indexPath: IndexPath) -> CGSize {
    return cellsize
  }
  
  public func collectionView(_ collectionView: UICollectionView, 
    layout collectionViewLayout: UICollectionViewLayout,
    insetForSectionAt section: Int) -> UIEdgeInsets {
    let m = margin
    return UIEdgeInsets(top: m, left: m, bottom: m, right: m)
  }
  
  public func collectionView(_ collectionView: UICollectionView, 
    layout collectionViewLayout: UICollectionViewLayout,
    minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
    return 0
  }
  
  public func collectionView(_ collectionView: UICollectionView, 
    layout collectionViewLayout: UICollectionViewLayout, 
    minimumLineSpacingForSectionAt section: Int) -> CGFloat {
    return 2*margin
  }
  
  // MARK: - UIScrollViewDelegate
 
  
  public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
  }
  
  public func scrollViewDidScroll(_ scrollView: UIScrollView) {
  }

  public func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
  }

  public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
    let cells = collectionView.visibleCells as! [PageCell]
    if cells.count == 1 { 
      let cell = cells[0]
      if cell.index != _index {
        visibleCells = [cells[0]] 
        debug("*** Action: Scrolling ended")
        updateDisplaying()
      }
    }
  }
  
  public func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
  }
  
} // PageCollectionVC

