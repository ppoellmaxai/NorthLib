//
//  ImageCollectionViewController.swift
//  NorthLib
//
//  Created by Ringo Müller on 02.06.20.
//  Copyright © 2020 Norbert Thies. All rights reserved.
//

import Foundation
import UIKit

open class ImageCollectionVC: PageCollectionVC, ImageCollectionVCSpec {
  public func onTap(closure: ((Double, Double) -> ())?) {
    onTapClosure = closure
    for case let cell as PageCell in self.collectionView.visibleCells {
      if let ziv = cell.page?.activeView as? ZoomedImageView {
          /// add/remove onTap to currently visible Cell
          ziv.onTap(closure: closure)
        }
    }
  }
  
  public private(set) var xButton = Button<CircledXView>()
  public private(set) var pageControl = UIPageControl()
  private var onXClosure: (()->())? = nil
  private var onTapClosure : ((Double, Double) -> ())? = nil
  private var fallbackOnXClosure: (()->())? = nil
  private var scrollToIndexPathAfterLayoutSubviews : IndexPath?
  
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
  
  private func updatePageControllDots() {
    if pageControlMaxDotsCount == 0 || self.count < pageControlMaxDotsCount {
      self.pageControl.numberOfPages = self.count
    } else {
      self.pageControl.numberOfPages = pageControlMaxDotsCount
    }
  }
  
  public override func scrollViewDidScroll(_ scrollView: UIScrollView) {
    if pageControlMaxDotsCount != 0 {
      let pageWidth = scrollView.frame.width
      let currentPage = Int((scrollView.contentOffset.x + pageWidth / 2) / pageWidth)
      self.pageControl.currentPage = Int(round(Float(currentPage) * Float(pageControlMaxDotsCount) / Float(self.count)))
    }
    else {
      let witdh = scrollView.frame.width - (scrollView.contentInset.left*2)
      let index = scrollView.contentOffset.x / witdh
      let roundedIndex = round(index)
      self.pageControl.currentPage = Int(roundedIndex)
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
  
  public func onX(closure: @escaping () -> ()) {
    self.onXClosure = closure
  }
  
  func defaultOnXHandler() {
    if let nc = self.navigationController {
      nc.popViewController(animated: true)
    }
    else if let pvc = self.presentingViewController {
      pvc.dismiss(animated: true, completion: nil)
    }
  }
  
  // MARK: - Life Cycle
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
    //initially render CollectionView
    self.collectionView.reloadData()
  }
  
  open override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    if let iPath = scrollToIndexPathAfterLayoutSubviews {
      collectionView?.scrollToItem(at: iPath, at: .centeredHorizontally, animated: false)
      scrollToIndexPathAfterLayoutSubviews = nil
    }
  }
  open override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
    super.viewWillTransition(to: size, with: coordinator)
    scrollToIndexPathAfterLayoutSubviews = collectionView?.indexPathsForVisibleItems.first
  }
  
  // MARK: UI Helper Methods
  func prepareCollectionView() {
    self.collectionView.backgroundColor = UIColor.black
    self.collectionView.showsHorizontalScrollIndicator = false
    self.collectionView.showsVerticalScrollIndicator = false
    self.collectionView.delegate = self
  }
  
  func setupViewProvider(){
    viewProvider { [weak self] (index, oview) in
      guard let strongSelf = self else { return UIView() }
      if let ziv = oview as? ZoomedImageView {
        ziv.optionalImage = strongSelf.images[index]
        ziv.onTap(closure: strongSelf.onTapClosure)
        return ziv
      }
      else {
        let ziv = ZoomedImageView(optionalImage: strongSelf.images[index])
        ziv.onTap(closure: strongSelf.onTapClosure)
        return ziv
      }
    }
  }
} // PageCollectionVC
