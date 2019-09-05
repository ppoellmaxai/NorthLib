//
//  ViewExtensions.swift
//
//  Created by Norbert Thies on 2019-02-28
//  Copyright © 2019 Norbert Thies. All rights reserved.
//
//  This file implements some UIView extensions
//

import UIKit

public extension UIView {
  
  /**
   pins the top of this view to the "safe" top of the given view 'to'.
   
   'pinTop' uses autolayout constraints to pin the top edge of this view to
   an other view's top edge (optional minus margin).
   If the argument `isMargin == true` then the top of this view is pinned 
   to the top margin of the given view 'to'.
   */
  func pinTop(to view: UIView, isMargin: Bool = false ) {
    let guide = isMargin ? view.layoutMarginsGuide : view.safeAreaLayoutGuide
    translatesAutoresizingMaskIntoConstraints = false
    topAnchor.constraint(equalTo: guide.topAnchor).isActive = true
  }
  
  /**
   pins the bottom of this view to the "safe" bottom of the given view 'to'.
   
   'pinBottom' uses autolayout constraints to pin the bottom edge of this view to
   an other view's bottom edge (optional minus margin).
   If the argument `isMargin == true` then the bottom of this view is pinned 
   to the bottom margin of the given view 'to'.
   */
  func pinBottom(to view: UIView, isMargin: Bool = false ) {
    let guide = isMargin ? view.layoutMarginsGuide : view.safeAreaLayoutGuide
    translatesAutoresizingMaskIntoConstraints = false
    bottomAnchor.constraint(equalTo: guide.bottomAnchor).isActive = true
  }
  
  
  /**
   pins the left edge of this view to the "safe" left edge of the given view 'to'.
   */
  func pinLeft(to view: UIView, isMargin: Bool = false ) {
    let guide = isMargin ? view.layoutMarginsGuide : view.safeAreaLayoutGuide
    translatesAutoresizingMaskIntoConstraints = false
    leftAnchor.constraint(equalTo: guide.leftAnchor).isActive = true
  }
  
  /**
   pins the right edge of this view to the "safe" right edge of the given view 'to'.
   */
  func pinRight(to view: UIView, isMargin: Bool = false ) {
    let guide = isMargin ? view.layoutMarginsGuide : view.safeAreaLayoutGuide
    translatesAutoresizingMaskIntoConstraints = false
    rightAnchor.constraint(equalTo: guide.rightAnchor).isActive = true
  } 
  
  /**
   pins the width of this view to a constant value.
   */
  func pinWidth(_ width: CGFloat) {
    translatesAutoresizingMaskIntoConstraints = false
    widthAnchor.constraint(equalToConstant: width).isActive = true
  } 
  
  /**
   pins the height of this view to a constant value.
   */
  func pinHeight(_ height: CGFloat) {
    translatesAutoresizingMaskIntoConstraints = false
    heightAnchor.constraint(equalToConstant: height).isActive = true
  } 
  
} // extension UIView
