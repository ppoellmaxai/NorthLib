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
  
  open var collectionView: UICollectionView!

  open var provider: ((Int)->OptionalView)? = nil
  
  /// inset from top/bottom/left/right as factor to min(width,height)
  open var inset = 0.025
  
  fileprivate var index2scrollTo: Int?  // index of page to scroll to
  fileprivate var cvSize: CGSize { return self.collectionView.bounds.size }
  fileprivate var onDisplayClosure: ((Int, UIView?)->())?
  
  // Cell which is currently displayed
  private var currentCell: PageCell?

  private func indexPath(cell: PageCell?) -> IndexPath?{ 
    if let c = cell { return collectionView.indexPath(for: c) }
    return nil
  }
  
  /// IndexPath of current cell
  open var indexPath: IndexPath? { return indexPath(cell: currentCell) }

  /// Index of current cell
  open var index: Int? {
    get { if let cell = currentCell { return cell.index } else { return nil } }
    set(idx) { if let i = idx { scrollto(i) } }
  }
  
  private var visibleCells: Set<PageCell> = []

  /// View currently displayed
  open var currentView: UIView? { 
    return currentCell?.pageView
  }
  
  fileprivate var _count: Int = 0
  open var count: Int {
    get { return _count }
    set { 
      _count = newValue
      collectionView.reloadData()
      index = 0
    }
  }
  
  private var reuseIdent: String = { countVC += 1; return "PageCell\(countVC)" }()
  
  public init() { super.init(nibName: nil, bundle: nil) }
  
  public required init?(coder: NSCoder) { super.init(coder: coder) }
  
  public func onDisplay(closure: ((Int, UIView?)->())?) {
    onDisplayClosure = closure
  }
  
  private func updateDisplaying() {
//    if let i = index2scrollTo { 
//      index2scrollTo = nil
//      scrollto(i)
//      return
//    }
    debug("visible cells: \(visibleCells.map{$0.index})")
    if visibleCells.count == 1 {
      let vis = visibleCells.first!
      if vis !== currentCell {
        debug("displaying page #\(vis.index!)")
        currentCell = vis
        if let closure = onDisplayClosure { closure(vis.index!, currentCell?.pageView) }
      }
    }
  }
  
  open func viewProvider(provider: @escaping (Int)->OptionalView) {
    self.provider = provider
  }
  
  open func scrollto(_ index: Int, animated: Bool = false) {
    if currentCell != nil {
      let ipath = IndexPath(item: index, section: 0)
      collectionView.scrollToItem(at: ipath, at: .centeredHorizontally, animated: animated)
    }
    else { index2scrollTo = index }
  }

  // MARK: - Life Cycle

  override open func loadView() {
    super.loadView()
    let flowLayout = UICollectionViewFlowLayout()
    flowLayout.scrollDirection = .horizontal
    collectionView = UICollectionView(frame: .zero, collectionViewLayout: flowLayout)
    collectionView.backgroundColor = UIColor.white
    collectionView.translatesAutoresizingMaskIntoConstraints = false
    self.view.addSubview(collectionView)
    NSLayoutConstraint.activate([
      collectionView.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor),
      collectionView.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor),
      collectionView.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.trailingAnchor),
      collectionView.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor),
      ])
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
      if let provider = self.provider {
        let page = provider(idx)
        let isAvailable = page.isAvailable
        let activeView = isAvailable ? page.mainView : (page.waitingView ?? UndefinedView())
        if let pageView = cell.pageView {
          pageView.removeFromSuperview()
        }
        cell.pageView = activeView
        cell.index = idx
        cell.contentView.addSubview(activeView)
        pin(activeView, to: cell.contentView)
        if isAvailable { page.loadView() }
        else {
          page.whenAvailable { collectionView.reloadItems(at: [indexPath]) }
        }
        return cell
      }
    }
    return PageCell()
  }
  
  // MARK: - UICollectionViewDelegate
  
  public func collectionView(_ view: UICollectionView, willDisplay: UICollectionViewCell, 
                             forItemAt: IndexPath) {
    visibleCells.update(with: willDisplay as! PageCell)
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
      if cell !== currentCell {
        visibleCells = [cells[0]] 
        updateDisplaying()
      }
    }
  }
  
  public func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
  }
  
} // PageCollectionVC

