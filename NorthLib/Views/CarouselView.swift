//
//  CarouselView.swift
//
//  Created by Norbert Thies on 06.04.20.
//  Copyright © 2020 Norbert Thies. All rights reserved.
//

import UIKit

/**
 A CarouselView is a UICollectionView subclass presenting a number of views in a
 carousel like fashion.
 
 The Carousel presents a list of views (called pages) that are scrollable horizontally. 
 Its width determines the width of the pages:
   - let cwidth be the width of the Carousel
   - let relativeInset (adjustable) be a factor to cwidth which defines the 
     spacing between pages
   - then the spacing swidth = relativeInset * cwidth
   - let relativePageWidth (adjustable) be a factor to cwidth which defines the 
     width of a page
   - then the page width pwidth = relativePageWidth * cwidth
 */

open class CarouselView: UICollectionView, UICollectionViewDelegate, 
  UICollectionViewDataSource, UIScrollViewDelegate {
  
  /// relative spacing between pages (in relation to the Carousel's width)
  open var relativeInset: CGFloat = 0.005
  /// relative size of one page (in relation to the Carousel's width)
  open var relativePageWidth: CGFloat = 0.7
  /// use rounded corners
  open var roundedCorners: Bool = false
  /// scroll from left to right or vice versa
  open var scrollFromLeftToRight: Bool = false {
    didSet { 
      if scrollFromLeftToRight {
        transform = CGAffineTransform(rotationAngle: CGFloat.pi)
      }
      else { transform = .identity }
    }
  }
  
  fileprivate static var countView = 0  // #CarouselViews instantiated
  fileprivate static var reuseIdent: String = { countView += 1; return "PageCell\(countView)" }()
  
  /// The collection view cell getting presented in a page like fashion
  class PageCell: UICollectionViewCell {
    /// The page to display
    var page: OptionalView?
    /// The view to display
    var pageView: UIView? { return page?.activeView }
    /// Index of view in list of collection view cells
    var index: Int?
    
    /// Request view from provider and put it into a PageCell
    func update(carousel: CarouselView, idx: Int) {
      if let provider = carousel.provider {
        if let pv = pageView { pv.removeFromSuperview() }
        let page = provider(idx, self.page)
        let isAvailable = page.isAvailable
        if carousel.roundedCorners { 
          let cradius = 0.03 * contentView.bounds.size.height
          contentView.layer.cornerRadius = cradius
          contentView.clipsToBounds = true
        }
        if carousel.scrollFromLeftToRight {
          page.activeView.transform = CGAffineTransform(rotationAngle: -CGFloat.pi)
        }
        contentView.addSubview(page.activeView)
        pin(page.activeView, to: contentView)
        self.index = idx
        self.page = page
        if isAvailable { page.loadView() }
        else {
          let iPath = IndexPath(item: idx, section: 0)
          page.whenAvailable { carousel.reloadItems(at: [iPath]) }
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
  
  // The Layout driving the Carousel
  class CarouselLayout: UICollectionViewLayout, DoesLog {
    var carousel: CarouselView { collectionView as! CarouselView }
    var count: Int { carousel.numberOfItems(inSection: 0) }
    let scaleFactor: CGFloat = 0.2
    var scale: CGFloat = 0.9      // factor to scale every cell with
    var inset: CGFloat = 0        // inset of first/last cell from edge
    var size = CGSize()           // size of one cell
    var spacing: CGFloat = 0      // spacing between cells
    // width of cell including spacing
    var cellWidth: CGFloat { size.width + spacing }
    // width of complete content
    var contentWidth: CGFloat { CGFloat(count) * cellWidth }
    // layout attributes
    var attributes: [UICollectionViewLayoutAttributes] = []
    
    func position2index(_ position: CGFloat) -> Int {
      let pos = position - inset
      var idx: CGFloat
      if scale =~ 1.0 {
        idx = position/cellWidth
      }
      else {
        let nearest = -(1 - pos*(1-scale)/cellWidth)
        idx = nearest.log(base: scale)
      }
      return Int(round(idx))
    }
    
    func totalWidth(position: CGFloat) -> CGFloat{
      let n = count
      if scale =~ 1.0 {
        return 2*inset + CGFloat(n)*cellWidth
      }
      else {
        let i = position2index(position)
        let s = scale
        let w = cellWidth
        // The compiler is unable to type-check this expression in reasonable time; 
        // try breaking up the expression into distinct sub-expressions:
        // return w * ( (2 - s**i - s**(n-i)) / (1-s) + 1)
        let a = 2 - s**i - s**(n-i)
        let b = 1-s
        return w * (a/b + 1)
      }
    }
    
    func position2attributes(position: CGFloat) -> [UICollectionViewLayoutAttributes] {
      let count = self.count
//      let i = position2index(position)
      let arr = Array<UICollectionViewLayoutAttributes>(repeating: UICollectionViewLayoutAttributes(), count: count)
      return arr
    }
    
    // Setup layout attributes
    func reset() {
      guard let carousel = collectionView as? CarouselView 
        else { return }
      if attributes.count == 0 {
        let count = carousel.numberOfItems(inSection: 0)
        let csize = carousel.bounds.size
        let cwidth = csize.width
        size.width = cwidth * carousel.relativePageWidth
        size.height = csize.height
        spacing = cwidth * carousel.relativeInset
        let centerY = size.height/2
        var x: CGFloat = 0
        let offset: CGFloat = carousel.contentOffset.x + carousel.center.x
        for i in 0..<count {
          let ipath = IndexPath(item: i, section: 0)
          let attr = UICollectionViewLayoutAttributes(forCellWith: ipath)
          attr.size = size
          let centerX = x + size.width/2
          attr.center = CGPoint(x: centerX, y: centerY)
          let dist = abs(offset - centerX)
          let distInWidth = dist/size.width
          let scale = max(0.1, 1 - (scaleFactor*distInWidth))
          //debug("offset: \(offset), dist: \(dist), scale: \(scale)")
          attr.transform = CGAffineTransform.identity.scaledBy(x: scale, y: scale)
          //////////
          attr.size = CGSize(width: size.width * scale, height: size.height)
          attr.center = CGPoint(x: x + attr.size.width/2, y: centerY)
          //////////
          attributes += attr
          x += cellWidth
        }
      }
    }
    
    // Return content size
    override var collectionViewContentSize: CGSize {
      guard let carousel = collectionView as? CarouselView else { return .zero }
      reset()
      return CGSize(width: contentWidth, height: carousel.frame.height)
    }
    
    // Return attributes in rectangular area
    override func layoutAttributesForElements(in rect: CGRect) -> 
      [UICollectionViewLayoutAttributes]? {
      reset()
      return attributes.filter { rect.intersects($0.frame) }
    }
    
    // Return attributes for a specific item
    override func layoutAttributesForItem(at indexPath: IndexPath) -> 
      UICollectionViewLayoutAttributes? {
        reset()
        return attributes[indexPath.item]
    }
    
    // invalidate layout upon bounds change or user scrolling
    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
      true
    }
    override func invalidateLayout(with context: UICollectionViewLayoutInvalidationContext) {
      if context.invalidateEverything || context.invalidateDataSourceCounts {
        attributes = []
       }
      attributes = []
      super.invalidateLayout(with: context)
    }
    
  } // CarouselLayout
  
  // The layout object
  private var layout = CarouselLayout()
  
  // A closure providing the optional views to display
  private var provider: ((Int, OptionalView?)->OptionalView)? = nil
  
  /// Defines the closure which delivers the views to display
  open func viewProvider(provider: @escaping (Int, OptionalView?)->OptionalView) {
    self.provider = provider
  }
    
  // Setup the CarouselView
  private func setup() {
    backgroundColor = UIColor.white
    contentInsetAdjustmentBehavior = .never
    register(PageCell.self, forCellWithReuseIdentifier: CarouselView.reuseIdent)
    delegate = self
    dataSource = self
    if scrollFromLeftToRight {
      debug("fromLeft")
      transform = CGAffineTransform(rotationAngle: CGFloat.pi)
    }
  }
  
  public init(frame: CGRect) {
    super.init(frame: frame, collectionViewLayout: layout)
    setup()
  }
  
  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    setup()
  }
  
  public convenience init() { self.init(frame: CGRect()) }
  
  fileprivate var _index: Int?
  fileprivate var isInitialized = false
  fileprivate var initialIndex: Int? = nil
  
  // initialize with initialIndex when scroll view is ready
  fileprivate func initialize() {
    if !isInitialized {
      isInitialized = true
      if let idx = initialIndex { self.index = idx }
    }
  }
  
  /// Index of current page, change it to scroll to a certain cell
  open var index: Int? {
    get { return _index }
    set(idx) { 
      if let idx = idx, idx != _index { 
        if isInitialized {
          _index = idx
          scrollto(idx)
          if let closure = onDisplayClosure { closure(idx) }
        }
        else { initialIndex = idx }
      } 
    }
  }
  
  fileprivate var _count: Int = 0
  
  /// Define and change the number of views to display, will reload data
  open var count: Int {
    get { return _count }
    set { 
      _count = newValue
      reloadData()
    }
  }
  
  fileprivate var onDisplayClosure: ((Int)->())?
  
  /// Define closure to call when a cell is displayed in the center
  public func onDisplay(closure: ((Int)->())?) {
    onDisplayClosure = closure
  }
  
  // updateDisplaying is called when the scrollview has been scrolled which
  // might have changed the view currently visible
  private func updateDisplaying(_ idx: Int) { 
    if _index != idx {
      _index = idx
      if let closure = onDisplayClosure { closure(idx) }
    }
  }
  
  // Scroll to the cell at position index
  fileprivate func scrollto(_ idx: Int, animated: Bool = false) {
    debug("scrolling to: \(idx)")
    let ipath = IndexPath(item: idx, section: 0)
    scrollToItem(at: ipath, at: .centeredHorizontally, animated: animated)
  }

  // MARK: - UICollectionViewDataSource
  
  open func numberOfSections(in collectionView: UICollectionView) -> Int {
    return 1
  }
  
  open func collectionView(_ collectionView: UICollectionView, 
                           numberOfItemsInSection section: Int) -> Int {
    initialize()
    return self.count
  }
  
  open func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: 
      CarouselView.reuseIdent, for: indexPath) as? PageCell {
      let itemIndex = indexPath.item
      cell.update(carousel: self, idx: itemIndex)
      return cell
    }
    return PageCell()
  }
  
  // MARK: - UIScrollViewDelegate
  
  // While scrolling update page index
  public func scrollViewDidScroll(_ scrollView: UIScrollView) {
    let pageIndex = Int(round(scrollView.contentOffset.x/layout.cellWidth))
    if pageIndex != _index { updateDisplaying(pageIndex) }  
  }
  
  // When dragging stops, position collection view to a complete page  
  public func scrollViewWillEndDragging(_ scrollView: UIScrollView, 
                                        withVelocity velocity: CGPoint, 
                                        targetContentOffset: UnsafeMutablePointer<CGPoint>) {
    var offset = targetContentOffset.pointee
    let cellwidth = layout.cellWidth
    let idx = round((offset.x + scrollView.contentInset.left) / cellwidth)
    offset = CGPoint(x: idx*cellwidth - scrollView.contentInset.left,
                     y: scrollView.contentInset.top)
    targetContentOffset.pointee = offset
  }

  
} // CarouselView

////
////  PageCollectionVC.swift
////
////  Created by Norbert Thies on 10.09.18.
////  Copyright © 2018 Norbert Thies. All rights reserved.
////
//
//import UIKit
//
//fileprivate var countVC = 0
//
//
//open class PageCollectionVC: UIViewController, UICollectionViewDelegate,
//  UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UIScrollViewDelegate {
//
//  /// The Cell that is presented as scrollable collection view item  
//  class PageCell: UICollectionViewCell {
//    
//    /// The page to display
//    var page: OptionalView?
//    /// The View to display
//    var pageView: UIView? { return page?.activeView }
//    /// Index of View in collection view
//    var index: Int?
//    
//    /// Request view from provider and put it into a PageCell
//    func update(pcvc: PageCollectionVC, idx: Int) {
//      if let provider = pcvc.provider {
//        if let pv = pageView { pv.removeFromSuperview() }
//        let page = provider(idx, self.page)
//        let isAvailable = page.isAvailable
//        self.contentView.addSubview(page.activeView)
//        pin(page.activeView, to: self.contentView)
//        self.index = idx
//        self.page = page
//        if isAvailable { page.loadView() }
//        else {
//          let iPath = IndexPath(item: idx, section: 0)
//          page.whenAvailable { pcvc.collectionView.reloadItems(at: [iPath]) }
//        }
//      }
//    }
//    
//    override init(frame: CGRect) {
//      super.init(frame: frame)
//    }
//    required init?(coder: NSCoder) {
//      super.init(coder: coder)
//    }
//  } // PageCell
//  
//  /// The collection view displaying OptionalViews
//  open var collectionView: UICollectionView!
//  
//  /// The Layout object determining the size of the cells
//  open var cvLayout: UICollectionViewFlowLayout!
//
//  /// A closure providing the optional views to display
//  open var provider: ((Int, OptionalView?)->OptionalView)? = nil
//  
//  /// inset from top/bottom/left/right as factor to min(width,height)
//  open var inset = 0.025
//
//  // The raw cell size (without bounds)
//  private var rawCellsize: CGSize { return self.collectionView.bounds.size }
//  
//  // The default margin of cells (ie. left/right/top/bottom insets)
//  private var margin: CGFloat {
//    let s = rawCellsize
//    return min(s.height, s.width) * CGFloat(inset)
//  }
//  
//  // The size of a cell is defined by the collection views bounds minus margins
//  private var cellsize: CGSize {
//    let s = rawCellsize
//    return CGSize(width: s.width - 2*margin, height: s.height - 2*margin)
//  }
//  
//  // View which is currently displayed
//  public var currentView: OptionalView?
//  
//  private var _index: Int?
//  
//  /// Index of current view, change it to scroll to a certain cell
//  open var index: Int? {
//    get { return _index }
//    set(idx) { 
//      if let idx = idx { 
//        _index = idx
//        scrollto(idx)
//        if let closure = onDisplayClosure { closure(idx) }
//      } 
//    }
//  }
//
//  fileprivate var _count: Int = 0
//  
//  /// Define and change the number of views to display, will reload data
//  open var count: Int {
//    get { return _count }
//    set { 
//      _count = newValue
//      collectionView.reloadData()
//    }
//  }
//  
//  private var reuseIdent: String = { countVC += 1; return "PageCell\(countVC)" }()
//  
//  public init() { super.init(nibName: nil, bundle: nil) }
//  
//  public required init?(coder: NSCoder) { super.init(coder: coder) }
//
//  fileprivate var onDisplayClosure: ((Int)->())?
//  
//  /// Define closure to call when a cell is newly displayed  
//  public func onDisplay(closure: ((Int)->())?) {
//    onDisplayClosure = closure
//  }
// 
//  // updateDisplaying is called when the scrollview has been scrolled which
//  // might have changed the view currently visible
//  private func updateDisplaying(_ idx: Int) { 
//    if _index != idx {
//      _index = idx
//      if let closure = onDisplayClosure { closure(idx) }
//    }
//  }
//  
//  /// Defines the closure which delivers the views to display
//  open func viewProvider(provider: @escaping (Int, OptionalView?)->OptionalView) {
//    self.provider = provider
//  }
// 
//  
//  // Scroll to the cell at position index
//  fileprivate var isInitializing = true
//  fileprivate var initialIndex: Int? = nil
//  fileprivate func scrollto(_ index: Int, animated: Bool = false) {
//    if isInitializing { initialIndex = index }
//    else {
//      let ipath = IndexPath(item: index, section: 0)
//      collectionView.scrollToItem(at: ipath, at: .centeredHorizontally, animated: animated)
//    }
//  }
//
//  // MARK: - Life Cycle
//
//  override open func loadView() {
//    super.loadView()
//    cvLayout = UICollectionViewFlowLayout()
//    cvLayout.scrollDirection = .horizontal
//    collectionView = UICollectionView(frame: .zero, collectionViewLayout: cvLayout)
//    let m = margin
//    collectionView.contentInset = UIEdgeInsets(top: m, left: m, bottom: m, right: m)
//    collectionView.backgroundColor = UIColor.white
//    collectionView.contentInsetAdjustmentBehavior = .never
//    self.view.addSubview(collectionView)
//    pin(collectionView.top, to: self.view.topGuide())
//    pin(collectionView.bottom, to: self.view.bottom)
//    pin(collectionView.left, to: self.view.left)
//    pin(collectionView.right, to: self.view.right)
//    collectionView.register(PageCell.self, forCellWithReuseIdentifier: reuseIdent)
//    collectionView.delegate = self
//    collectionView.dataSource = self
//    collectionView.isPagingEnabled = true
//  }
//  
//  open override func viewDidLoad() {
//    super.viewDidLoad()
//    if count != 0 { collectionView.reloadData() }
//  }
//  
//  // TODO: transition/rotation better with collectionViewLayout subclass as described in:
//  // https://www.matrixprojects.net/p/uicollectionviewcell-dynamic-width/
//  open override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
//    super.willTransition(to: newCollection, with: coordinator)
//    coordinator.animate(alongsideTransition: nil) { [weak self] ctx in
//      self?.collectionView.collectionViewLayout.invalidateLayout()
//    }
//  }
//  
//  // MARK: - UICollectionViewDataSource
//  
//  open func numberOfSections(in collectionView: UICollectionView) -> Int {
//    return 1
//  }
//  
//  open func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
//    return self.count
//  }
//  
//  open func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
//    if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdent,
//                  for: indexPath) as? PageCell {
//      let idx = indexPath.item
//      cell.update(pcvc: self, idx: idx)
//      if isInitializing {
//        isInitializing = false
//        if initialIndex! != idx { scrollto(initialIndex!) }
//      } 
//      return cell
//    }
//    return PageCell()
//  }
//  
//  // MARK: - UICollectionViewDelegate
//  
//  // ...
//  
//  // MARK: - UICollectionViewDelegateFlowLayout
//    
//  public func collectionView(_ collectionView: UICollectionView, 
//    layout collectionViewLayout: UICollectionViewLayout,
//    sizeForItemAt indexPath: IndexPath) -> CGSize {
//    return cellsize
//  }
//  
//  public func collectionView(_ collectionView: UICollectionView, 
//    layout collectionViewLayout: UICollectionViewLayout,
//    insetForSectionAt section: Int) -> UIEdgeInsets {
//    let m = margin
//    return UIEdgeInsets(top: m, left: m, bottom: m, right: m)
//  }
//  
//  public func collectionView(_ collectionView: UICollectionView, 
//    layout collectionViewLayout: UICollectionViewLayout,
//    minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
//    return 0
//  }
//  
//  public func collectionView(_ collectionView: UICollectionView, 
//    layout collectionViewLayout: UICollectionViewLayout, 
//    minimumLineSpacingForSectionAt section: Int) -> CGFloat {
//    return 2*margin
//  }
//  
//  // MARK: - UIScrollViewDelegate
// 
//  // When dragging stops, position collection view to a complete page  
////  public func scrollViewWillEndDragging(_ scrollView: UIScrollView, 
////    withVelocity velocity: CGPoint, 
////    targetContentOffset: UnsafeMutablePointer<CGPoint>) {
////    var offset = targetContentOffset.pointee
////    let cellwidth = rawCellsize.width
////    let idx = round((offset.x + scrollView.contentInset.left) / cellwidth)
////    offset = CGPoint(x: idx*cellwidth - scrollView.contentInset.left,
////                     y: scrollView.contentInset.top)
////    targetContentOffset.pointee = offset
////    updateDisplaying(Int(idx))
////  }
// 
//  // While scrolling update page index
//  public func scrollViewDidScroll(_ scrollView: UIScrollView) {
//    let pageIndex = Int(round(scrollView.contentOffset.x/view.bounds.size.width))
//    if pageIndex != _index { updateDisplaying(pageIndex) }  
//  }
//  
//} // PageCollectionVC

