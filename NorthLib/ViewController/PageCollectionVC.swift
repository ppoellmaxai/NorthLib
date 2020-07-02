//
//  PageCollectionVC.swift
//
//  Created by Norbert Thies on 10.09.18.
//  Copyright © 2018 Norbert Thies. All rights reserved.
//

import UIKit

fileprivate var countVC = 0


open class PageCollectionVC: UIViewController, UICollectionViewDelegate,
  UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UIScrollViewDelegate {

  /// The Cell that is presented as scrollable collection view item  
  class PageCell: UICollectionViewCell {
    
    /// The page to display
    var page: OptionalView?
    /// The View to display
    var pageView: UIView? { return page?.activeView }
    /// Index of View in collection view
    var index: Int?
    
    /// Request view from provider and put it into a PageCell
    func update(pcvc: PageCollectionVC, idx: Int) {
      if let provider = pcvc.provider {
        if let pv = pageView { pv.removeFromSuperview() }
        let page = provider(idx, self.page)
        let isAvailable = page.isAvailable
        self.contentView.addSubview(page.activeView)
        pin(page.activeView, to: self.contentView)
        self.index = idx
        self.page = page
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
    required init?(coder: NSCoder) {
      super.init(coder: coder)
    }
  } // PageCell
  
  /// The collection view displaying OptionalViews
  open var collectionView: UICollectionView!
  
  /// The Layout object determining the size of the cells
  open var cvLayout: UICollectionViewFlowLayout!

  /// A closure providing the optional views to display
  open var provider: ((Int, OptionalView?)->OptionalView)? = nil
  
  /// inset from top/bottom/left/right as factor to min(width,height)
  open var inset = 0.025
  
  /// Pin collection view to top safe area?
  open var pinTopToSafeArea = true

  // The raw cell size (without bounds)
  private var rawCellsize: CGSize { return self.collectionView.bounds.size }
  
  // The default margin of cells (ie. left/right/top/bottom insets)
  private var margin: CGFloat {
    let s = rawCellsize
    return min(s.height, s.width) * CGFloat(inset)
  }
  
  // The size of a cell is defined by the collection views bounds minus margins
  private var cellsize: CGSize {
    let s = rawCellsize
    return CGSize(width: s.width - 2*margin, height: s.height - 2*margin)
  }
  
  /// Returns the optional view at a given index (if that view is visible)
  open func optionalView(at idx: Int) -> OptionalView? {
    var cell = collectionView.cellForItem(at: IndexPath(item: idx, section: 0))
               as? PageCell
    if cell == nil { cell = _lastCellRequested }
    return cell?.page
  }

  // View which is currently displayed
  public var currentView: OptionalView? { 
    if let i = index { return optionalView(at: i) }
    else { return nil }
  }
  
  private var _index: Int?
  private var _nextIndex: Int?
  
  /// Index of current view, change it to scroll to a certain cell
  open var index: Int? {
    get { return _index }
    set(idx) { 
      if let idx = idx { 
        _index = idx
        _nextIndex = idx
        scrollto(idx)
      } 
    }
  }

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

  fileprivate var onDisplayClosures: [(Int)->()] = []
  
  /// Define closure to call when a cell is newly displayed  
  public func onDisplay(closure: @escaping (Int)->()) {
    onDisplayClosures += closure
  }
  
  /// Call all onDisplay closures
  fileprivate func callOnDisplay(idx: Int) 
    { for cl in onDisplayClosures { cl(idx) } }
 
  // updateDisplaying is called when the scrollview has been scrolled which
  // might have changed the view currently visible
  private func updateDisplaying(_ idx: Int) { 
    if _index != idx {
      _index = idx
      callOnDisplay(idx: idx)
    }
  }
  
  /// Defines the closure which delivers the views to display
  open func viewProvider(provider: @escaping (Int, OptionalView?)->OptionalView) {
    self.provider = provider
  }
 
  
  // Scroll to the cell at position index
  fileprivate var isInitializing = true
  fileprivate var initialIndex: Int? = nil
  fileprivate func scrollto(_ index: Int, animated: Bool = false) {
    if !isInitializing { 
      let ipath = IndexPath(item: index, section: 0)
      collectionView.scrollToItem(at: ipath, at: .centeredHorizontally, animated: animated)
    }
  }

  // MARK: - Life Cycle

  override open func loadView() {
    super.loadView()
    cvLayout = UICollectionViewFlowLayout()
    cvLayout.scrollDirection = .horizontal
    collectionView = UICollectionView(frame: .zero, collectionViewLayout: cvLayout)
    let m = margin
    collectionView.contentInset = UIEdgeInsets(top: m, left: m, bottom: m, right: m)
    collectionView.backgroundColor = UIColor.white
    collectionView.contentInsetAdjustmentBehavior = .never
    self.view.addSubview(collectionView)
    if self.pinTopToSafeArea { pin(collectionView.top, to: self.view.topGuide()) }
    else { pin(collectionView.top, to: self.view.top) }
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
  
  fileprivate var _lastCellRequested: PageCell?
  
  open func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdent,
                  for: indexPath) as? PageCell {
      let idx = indexPath.item
      if isInitializing {
        isInitializing = false
        if let next = _nextIndex, next != idx { 
          scrollto(next) 
          return cell
        }
      } 
      cell.update(pcvc: self, idx: idx)
      _lastCellRequested = cell
      if let next = _nextIndex {
        _nextIndex = nil
        callOnDisplay(idx: next)
      }
      return cell
    }
    return PageCell()
  }
  
  // MARK: - UICollectionViewDelegate
  
  // ...
  
  // MARK: - UICollectionViewDelegateFlowLayout
    
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
 
  // When dragging stops, position collection view to a complete page  
//  public func scrollViewWillEndDragging(_ scrollView: UIScrollView, 
//    withVelocity velocity: CGPoint, 
//    targetContentOffset: UnsafeMutablePointer<CGPoint>) {
//    var offset = targetContentOffset.pointee
//    let cellwidth = rawCellsize.width
//    let idx = round((offset.x + scrollView.contentInset.left) / cellwidth)
//    offset = CGPoint(x: idx*cellwidth - scrollView.contentInset.left,
//                     y: scrollView.contentInset.top)
//    targetContentOffset.pointee = offset
//    updateDisplaying(Int(idx))
//  }
 
  // While scrolling update page index
  public func scrollViewDidScroll(_ scrollView: UIScrollView) {
    let pageIndex = Int(round(scrollView.contentOffset.x/view.bounds.size.width))
    if pageIndex != _index { updateDisplaying(pageIndex) }  
  }
  
} // PageCollectionVC
