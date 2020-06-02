//
//  ImageCollectionViewController.swift
//  NorthLib
//
//  Created by Ringo Müller on 02.06.20.
//  Copyright © 2020 Norbert Thies. All rights reserved.
//

import Foundation
import UIKit



open class ImageCollectionViewController: PageCollectionVC, ImageCollectionViewControllerSpec {
  public var images: [OptionalImage] = []
  
  
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
  
  //max dots in pageControll, set to 0 for disable
  let maxPageControlDotsCount = 4
  var pageControl:UIPageControl = UIPageControl()
  
//  /// Defines the closure which delivers the views to display
//  open override func viewProvider(provider: @escaping (Int, OptionalView?)->OptionalView) {
//    self.provider = provider
//  }
  
  
  // MARK: - Life Cycle
  open override func viewDidLoad() {
    self.inset = 0.0
    
    if self.count == 0 && self.images.count > 0 {
      self.count = self.images.count
      self.collectionView.backgroundColor = UIColor.black
      self.collectionView.showsHorizontalScrollIndicator = false
      self.collectionView.showsVerticalScrollIndicator = false
      //TODO Maybe other place
      //Todo refer 2 diff implementation for used practice for setup
      if maxPageControlDotsCount == 0 || self.count < maxPageControlDotsCount {
             self.pageControl.numberOfPages = self.count
         } else {
             self.pageControl.numberOfPages = maxPageControlDotsCount
         }
      //Set the delegate
      self.collectionView.delegate = self
    }
    super.viewDidLoad()
    
    self.view.addSubview(self.pageControl)
    pin(pageControl.right, to: self.view.rightGuide(), dist: -15)
    pin(pageControl.left, to: self.view.leftGuide(), dist: 15)
    pin(pageControl.bottom, to: self.view.bottomGuide(), dist: -15)
    
    viewProvider { [weak self] (index, oview) in
      guard let this = self else { return UIView() }
      
//      return ZoomedImageView(optionalImage: this.images[index])
      if let ziv = oview as? ZoomedImageView {
        ziv.optionalImage = this.images[index]
        print("reuse ziv")
        return ziv
      }
      else {
        print("init new ziv")
        return ZoomedImageView(optionalImage: this.images[index])
        
      }
    }
  }
  
} // PageCollectionVC
