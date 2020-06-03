//
//  ImageCollectionViewController.swift
//  NorthLib
//
//  Created by Ringo Müller on 02.06.20.
//  Copyright © 2020 Norbert Thies. All rights reserved.
//

import Foundation
import UIKit

/** ToDo's
 - Handle rotation from this not from View DONE
      - Issue: small Image displayed => rotate => the nearby Image is also shown
             => ToDo Solution fade Out & In or just set the transparency!
 - implement X CLose Callback DONE
 
 */

open class ImageCollectionViewController: PageCollectionVC, ImageCollectionViewControllerSpec {
    public private(set) var xButton: Button<CircledXView> = Button<CircledXView>()
  
  public var images: [OptionalImage] = []
  
  private var reuseableViews: [ZoomedImageView] = []
  
  
  public override func scrollViewDidScroll(_ scrollView: UIScrollView) {
    if maxPageControlDotsCount != 0 {
      let pageWidth = scrollView.frame.width
      let currentPage = Int((scrollView.contentOffset.x + pageWidth / 2) / pageWidth)
      self.pageControl.currentPage = Int(round(Float(currentPage) * Float(maxPageControlDotsCount) / Float(self.count)))
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
  
  //max dots in pageControl, set to 0 for disable
  let maxPageControlDotsCount = 4
  var pageControl:UIPageControl = UIPageControl()
  
//  /// Defines the closure which delivers the views to display
//  open override func viewProvider(provider: @escaping (Int, OptionalView?)->OptionalView) {
//    self.provider = provider
//  }
  
  /** the default way to initialize/render the PageCollectionVC is to set its count
      this triggers collectionView.reloadData()
      this will be done automatic in ImageCollectionViewController->viewDidLoad
      To get rid of this default behaviour, we overwrite the Count Setter
  */
  override open var count: Int {
    get { return self.images.count }
    set {
      //Not used, not allowed
    }
  }
  
  
  // MARK: - Life Cycle
  open override func viewDidLoad() {
    super.viewDidLoad()
    self.inset = 0.0
    prepareCollectionView()
    setupXButton()
    preparePageControl()
    setupViewProvider()
    //initially render CollectionView
    self.collectionView.reloadData()
    self.onX {
      self.index = 3
      print("X Press!!")
    }
  }
  
  // MARK: UI Helper Methods
  func prepareCollectionView() {
    self.collectionView.backgroundColor = UIColor.black
    //
    self.collectionView.showsHorizontalScrollIndicator = false
    self.collectionView.showsVerticalScrollIndicator = false
    self.collectionView.delegate = self
  }
  
  func preparePageControl() {
    //setup number of dots
    if maxPageControlDotsCount == 0 || self.count < maxPageControlDotsCount {
      self.pageControl.numberOfPages = self.count
    } else {
      self.pageControl.numberOfPages = maxPageControlDotsCount
    }
    //Setup UI
    self.view.addSubview(self.pageControl)
    pin(pageControl.right, to: self.view.rightGuide(), dist: -15)
    pin(pageControl.left, to: self.view.leftGuide(), dist: 15)
    pin(pageControl.bottom, to: self.view.bottomGuide(), dist: -15)
  }
  
  
  var scrollToIndexPathAfterLayoutSubviews : IndexPath?
  
  open override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    if let iPath = scrollToIndexPathAfterLayoutSubviews {
      collectionView?.scrollToItem(at: iPath, at: .centeredHorizontally, animated: true)
      scrollToIndexPathAfterLayoutSubviews = nil
    }
    
    /** Idea Invalidate Layouts here reset Index did not work as fine as the final Solution
      let _ipath = collectionView?.indexPathsForVisibleItems
      print("viewDidLayoutSubviews: ipath for visible items", _ipath)
      collectionView?.collectionViewLayout.invalidateLayout()
      guard let ipath = _ipath?.last else  { return }
      collectionView?.scrollToItem(at: ipath, at: .centeredHorizontally, animated: true)
     */
  }
  
  open override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
    super.viewWillTransition(to: size, with: coordinator)
    scrollToIndexPathAfterLayoutSubviews = collectionView?.indexPathsForVisibleItems.first
    /** Debug Output for IndexPath
     print("viewWillTransition: ipath for visible items", _ipath)
     */
    
    /** Idea Invalidate Layout #1 => Problem Size is good, ScrollPosition not
     guard let flowLayout = collectionView?.collectionViewLayout as? UICollectionViewFlowLayout else {
      return
     }
     flowLayout.itemSize = size
     flowLayout.invalidateLayout()
     */
    
    /** Idea Invalidate Layout #1b => Idea 1 also not in Combination with Update UI of reuseable Views
     for ziv in self.reuseableViews {
      print("prepare rotate Rotate for All Items")
      ziv.updateUiAfterRotationWithTargetSize(size)
      ziv.setNeedsLayout()
     }
     */
    
    /** Idea Updating Cell Sizes => just updates one Cell / There is only one Visible Cell!
     for cell in collectionView.visibleCells {
      if let pCell = cell as? PageCell,
      let ziv = pCell.pageView as? ZoomedImageView {
        print("prepare rotate just for one active cell!")
        ziv.updateUiAfterRotationWithTargetSize(size)
      }
     }
     */
    
    /** Idea Scroll to Item ...Idea is good but only aplyable in layout Subviews
     ...but in Layout Subviews we may have 2 active cells, so remember the cell here is the Solution!
     if let idx = self.index {
      print("scroll to index: ", idx)
      let ipath = IndexPath(item: idx, section: 0)
      collectionView.scrollToItem(at: ipath, at: .centeredHorizontally, animated: true)
     }
     */

    /** Idea trigger Layout for Zoomes Image View by self.currentView
     ...but self.currentView is unset
     @ToDo: may Refactor due ist not really used in current taz.neo #ea0f123(26.5.) & NorthLib #5cdf32a(3.6.)
     guard let ziv = self.currentView as? ZoomedImageView else { return }
     */
    
    /** Idea: just Reload Data => too expencive, not working like invalidateLayout
         collectionView.reloadData()
     */
  }
    
  func setupViewProvider(){
    viewProvider { [weak self] (index, oview) in
      guard let this = self else { return UIView() }
      if let ziv = oview as? ZoomedImageView {
        ziv.optionalImage = this.images[index]
        print("reuse ziv")
        return ziv
      }
      else {
        print("init new ziv")
        let ziv = ZoomedImageView(optionalImage: this.images[index])
        self?.reuseableViews.push(ziv)
        //Part Of the Ideas to handle Orientation Change
//        ziv.handleOrientationChange = false
        return ziv
      }
    }
  }
  
} // PageCollectionVC
