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
    var pageView: UIView?
  }
  
  open var collectionView: UICollectionView!

  open var provider: ((Int)->OptionalView)? = nil
  
  /// inset from top/bottom/left/right as factor to min(width,height)
  open var inset = 0.025
  
  fileprivate var initialIndex: Int?
  fileprivate var lastIndex: Int?
  fileprivate var prevIndex: Int?  // index of previous page (scrolling from)
  fileprivate var nextIndex: Int?  // index of next page (scrolling to)
  fileprivate var cvSize: CGSize { return self.collectionView.bounds.size }
  fileprivate var onDisplayClosure: ((Int)->())?

  open var index: Int? {
    get {
      let wbounds = self.view.bounds
      let center = CGPoint(x: wbounds.midX, y: wbounds.midY) + collectionView.contentOffset
      let ipath = collectionView.indexPathForItem(at:center)
      return ipath?.item
    }
    set {
      if let v = newValue {
        if let idx = self.index { 
          if v > idx+1 { scrollto(v-1, animated:false) }
          else if v < idx-1 { scrollto(v+1, animated:false) }
          delay(seconds: 0.2) { self.scrollto(v,animated: true) }
        }
        else { initialIndex = v }
      }
    }
  }
  
  open var count: Int = 0 {
    didSet { if collectionView != nil { collectionView.reloadData() } }
  }
  
  private var reuseIdent: String = { countVC += 1; return "PageCell\(countVC)" }()
  
  public init() { super.init(nibName: nil, bundle: nil) }
  
  public required init?(coder: NSCoder) { super.init(coder: coder) }
  
  public func onDisplay(closure: ((Int)->())?) {
    onDisplayClosure = closure
  }
  
  private func displaying(index: Int) {
    if let closure = onDisplayClosure { closure(index) }
  }
  
  open func viewProvider(provider: @escaping (Int)->OptionalView) {
    self.provider = provider
  }
  
  open func scrollto(_ index: Int, animated: Bool = false) {
    let ipath = IndexPath(item: index, section: 0)
    collectionView.scrollToItem(at: ipath, at: .centeredHorizontally, animated: animated)
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
      self?.center()
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
      if let idx = initialIndex { initialIndex = nil; scrollto(idx) }
      if let provider = self.provider {
        let page = provider(indexPath.item)
        let isAvailable = page.isAvailable
        let activeView = isAvailable ? page.mainView : (page.waitingView ?? UndefinedView())
        if let pageView = cell.pageView {
          pageView.removeFromSuperview()
        }
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
    nextIndex = forItemAt.item
    if prevIndex == nil { displaying(index: nextIndex!) }
  }
  
  public func collectionView(_ view: UICollectionView, didEndDisplaying: UICollectionViewCell, 
                             forItemAt: IndexPath) {
    prevIndex = forItemAt.item
    if let n = nextIndex, prevIndex != n { displaying(index: n) }
    nextIndex = nil
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
  
  public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout,
                             sizeForItemAt indexPath: IndexPath) -> CGSize {
    return cellsize
  }
  
  public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout,
                           insetForSectionAt section: Int) -> UIEdgeInsets {
    let m = margin
    return UIEdgeInsets(top: m, left: m, bottom: m, right: m)
  }
  
  public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout,
                              minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
    return 0
  }
  
  public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
    return 2*margin
  }
  
  // MARK: - UIScrollViewDelegate
 
  fileprivate func center() {
    var idx: Int?
    if let i = index { idx = i }
    else if let l = lastIndex { idx = l }
    if let i = idx { self.scrollto(i, animated: true) }
  }
  
  fileprivate var isDecelerating = false
  
  public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
    isDecelerating = false
  }
  
  public func scrollViewDidScroll(_ scrollView: UIScrollView) {
    if let idx = index { lastIndex = idx }
  }

  public func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
    isDecelerating = true
  }

  public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
    //center()
  }
  
  public func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
    //if !isDecelerating { center() }
  }
  
} // PageCollectionVC

