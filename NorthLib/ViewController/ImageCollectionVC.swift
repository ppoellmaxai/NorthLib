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
  public var menu: [(title: String, icon: String, closure: (String)->())] = []
  // MARK: Properties
  private var onHighResImgNeededClosure: ((OptionalImage, @escaping (Bool) -> ()) -> ())?
  private var onHighResImgNeededZoomFactor: CGFloat = 1.1
  private var onXClosure: (()->())? = nil
  private var onTapClosure : ((OptionalImage, Double, Double) -> ())? = nil
  private var fallbackOnXClosure: (()->())? = nil
  private var scrollToIndexPathAfterLayoutSubviews : IndexPath?
  public private(set) var xButton = Button<CircledXView>()
  public var pageControl:UIPageControl? = UIPageControl()
  public var pageControlMaxDotsCount: Int = 0 {
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
      ///Apply PageControll Dots Update
      guard let pageControl = self.pageControl else { return }
      if self.pageControlMaxDotsCount > 0, self.count > 0,
        self.count > self.pageControlMaxDotsCount {
        pageControl.currentPage
          = Int( round( Float(idx+1)
                        * Float(self.pageControlMaxDotsCount)/Float(self.count)
            ) ) - 1
      }
      else {
        pageControl.currentPage = idx
      }
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
  
    public func addMenuItem(title: String,
                          icon: String,
                          closure: @escaping (String) -> ()) {
      menu.append((title,icon,closure))
  }
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
      guard let strongSelf = self else { return UIView() }
      if let ziv = oview as? ZoomedImageView {
        ziv.optionalImage = strongSelf.images[index]
        return ziv
      }
      else {
        let ziv = ZoomedImageView(optionalImage: strongSelf.images[index])
        ziv.onTap { (oimg, x, y) in
          strongSelf.zoomedImageViewTapped(oimg, x, y)
        }
        
        for itm in strongSelf.menu {
          ziv.addMenuItem(title: itm.title, icon: itm.icon, closure: itm.closure)
        }
        
        return ziv
      }
    }
  }
  
  /// Due onDisplay(idx) with cellforRowAt(idx) delivers another view than visible
  /// the Tapped Closure is wrapped to work with that kind of implementation
  /// of CollectionView, DataSource and ViewProvider
  func zoomedImageViewTapped(_ image: OptionalImage,
                             _ x: Double,
                             _ y: Double) {
    onTapClosure?(image,x,y)
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
    guard let pageControl = self.pageControl else { return }
    if pageControlMaxDotsCount == 0 || self.count < pageControlMaxDotsCount {
      pageControl.numberOfPages = self.count
    } else {
      pageControl.numberOfPages = pageControlMaxDotsCount
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
