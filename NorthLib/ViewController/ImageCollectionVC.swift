//
//  ImageCollectionViewController.swift
//  NorthLib
//
//  Created by Ringo Müller on 02.06.20.
//  Copyright © 2020 Norbert Thies. All rights reserved.
//

import Foundation
import UIKit

// MARK: - ImageCollectionVC
open class ImageCollectionVC: PageCollectionVC, ImageCollectionVCSpec {
  // MARK: Properties
  private var onHighResImgNeededClosure: ((OptionalImage, @escaping (Bool) -> ()) -> ())?
  private var onHighResImgNeededZoomFactor: CGFloat = 1.1
  private var onXClosure: (()->())? = nil
  private var onTapClosure : ((OptionalImage, Double, Double) -> ())? = nil
  private var fallbackOnXClosure: (()->())? = nil
  private var scrollToIndexPathAfterLayoutSubviews : IndexPath?
  public private(set) var xButton = Button<CircledXView>()
  public private(set) var pageControl = UIPageControl()
  public var pageControlMaxDotsCount: Int = 3 {
    didSet{ updatePageControllDots() }
  }
  public var images: [OptionalImage] = []{
    didSet{ updatePageControllDots() }
  }
  /** the default way to initialize/render the PageCollectionVC is to set its count
   this triggers collectionView.reloadData()
   this will be done automatic in ImageCollectionViewController->viewDidLoad
   To get rid of this default behaviour, we overwrite the Count Setter
   */
  override open var count: Int {
    get { return self.images.count }
    set { /**Not used, not allowed**/ }
  }
  
  // MARK: Life Cycle
  open override func viewDidLoad() {
    super.viewDidLoad()
    self.inset = 0.0
    prepareCollectionView()
    setupXButton()
    setupPageControl()
    setupViewProvider()
    xButton.isHidden = false
    xButton.onPress {_ in
      if let closure = self.onXClosure {
        closure()
      }
      else {
        self.defaultOnXHandler()
      }
    }
    onDisplay { (idx) in
      if self.pageControlMaxDotsCount != 0 {
        self.pageControl.currentPage
          = Int(round(Float(idx) * Float(self.pageControlMaxDotsCount) / Float(self.count)))
      }
      else {
        self.pageControl.currentPage = idx
      }
      guard let cell
        = self.collectionView(self.collectionView, cellForItemAt: IndexPath(item: idx, section: 0))
          as? PageCell, let ziv = cell.page as? ZoomedImageView else { return }
      self.applyHandlerToZoomedImageView(ziv)
    }
    //initially render CollectionView
    self.collectionView.reloadData()
  }
  
  // MARK: Layout
  open override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    if let iPath = scrollToIndexPathAfterLayoutSubviews {
      collectionView?.scrollToItem(at: iPath, at: .centeredHorizontally, animated: false)
      scrollToIndexPathAfterLayoutSubviews = nil
    }
  }
  
  open override func viewWillLayoutSubviews() {
    super.viewWillLayoutSubviews()
    /* FIX the Issue:
     The behavior of the UICollectionViewFlowLayout is not defined because:
     the item height must be less than the height of the UICollectionView
     minus the section insets top and bottom values,
     minus the content insets top and bottom values.
     */
    collectionView.collectionViewLayout.invalidateLayout()
  }
  
  open override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
    super.viewWillTransition(to: size, with: coordinator)
    scrollToIndexPathAfterLayoutSubviews = collectionView?.indexPathsForVisibleItems.first
  }
  
//  // MARK: UIScrollViewDelegate
//  public override func scrollViewDidScroll(_ scrollView: UIScrollView) {
//    super.scrollViewDidScroll(scrollView)
//    if pageControlMaxDotsCount != 0 {
//      let pageWidth = scrollView.frame.width
//      let currentPage = Int((scrollView.contentOffset.x + pageWidth / 2) / pageWidth)
//      self.pageControl.currentPage = Int(round(Float(currentPage) * Float(pageControlMaxDotsCount) / Float(self.count)))
//    }
//    else {
//      let witdh = scrollView.frame.width - (scrollView.contentInset.left*2)
//      let index = scrollView.contentOffset.x / witdh
//      let roundedIndex = round(index)
//      self.pageControl.currentPage = Int(roundedIndex)
//    }
//  }
} // PageCollectionVC

// MARK: - OptionalImageItem: Closures
extension ImageCollectionVC{
  public func onHighResImgNeeded(zoomFactor: CGFloat = 1.1,
                                 closure: ((OptionalImage, @escaping (Bool) -> ()) -> ())?){
    self.onHighResImgNeededClosure = closure
    self.onHighResImgNeededZoomFactor = zoomFactor
  }
}

// MARK: - Helper: ViewProvider
extension ImageCollectionVC {
  func setupViewProvider(){
    viewProvider { [weak self] (index, oview) in
      print("view provider called for index: ", index)
      guard let strongSelf = self else { return UIView() }
      if let ziv = oview as? ZoomedImageView {
        ziv.optionalImage = strongSelf.images[index]
        strongSelf.applyHandlerToZoomedImageView(ziv)
        return ziv
      }
      else {
        let ziv = ZoomedImageView(optionalImage: strongSelf.images[index])
        strongSelf.applyHandlerToZoomedImageView(ziv)
        return ziv
      }
    }
  }
}

// MARK: - Demo/Test Helper
extension ImageCollectionVC {
  func applyHandlerToZoomedImageView(_ ziv: ZoomedImageViewSpec) {
    ziv.onHighResImgNeeded(zoomFactor: self.onHighResImgNeededZoomFactor,
                           closure: self.onHighResImgNeededClosure)
    print("settet on tap: ", onTapClosure != nil)
    ziv.onTap(closure: onTapClosure)
    ///Test if AddMenu in ZoomedImageView works here
    ///ToDo: may add this also to  Specifications.swift => ImageCollectionVCSpec
    ///to have a setter outside
    /// This Demo Code would add Menu Items on Reuse, so the menu length increases on reuse
    if let _ziv = ziv as? ZoomedImageView {
      _ziv.addMenuItem(title: "Test", icon: "", closure: { _ in
        print("Works on new TODO Put this to ICVC....")
      })
    }
  }
}


// MARK: - Helper
extension ImageCollectionVC {
  func prepareCollectionView() {
    self.collectionView.backgroundColor = UIColor.black
    self.collectionView.showsHorizontalScrollIndicator = false
    self.collectionView.showsVerticalScrollIndicator = false
    self.collectionView.delegate = self
  }
  
  private func updatePageControllDots() {
    if pageControlMaxDotsCount == 0 || self.count < pageControlMaxDotsCount {
      self.pageControl.numberOfPages = self.count
    } else {
      self.pageControl.numberOfPages = pageControlMaxDotsCount
    }
  }
}

// MARK: - Handler
extension ImageCollectionVC {
  public func onX(closure: @escaping () -> ()) {
    self.onXClosure = closure
  }
  
  public func onTap(closure: ((OptionalImage, Double, Double) -> ())?) {
    onTapClosure = closure
    for case let cell as PageCell in self.collectionView.visibleCells {
      if let ziv = cell.page?.activeView as? ZoomedImageView {
        /// add/remove onTap to currently visible Cell
        ziv.onTap(closure: closure)
      }
    }
  }
  
  func defaultOnXHandler() {
    if let nc = self.navigationController {
      nc.popViewController(animated: true)
    }
    else if let pvc = self.presentingViewController {
      pvc.dismiss(animated: true, completion: nil)
    }
  }
}
