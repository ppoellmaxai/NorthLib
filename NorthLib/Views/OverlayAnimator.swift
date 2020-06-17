//
//  OverlayAnimator.swift
//  NorthLib
//
//  Created by Ringo Müller on 17.06.20.
//  Copyright © 2020 Norbert Thies. All rights reserved.
//

import Foundation

class OverlayAnimator: OverlaySpec{
  var shadeView: UIView
  
  var overlayView: UIView
  
  var overlaySize: CGSize?
  
  var maxAlpha: Double = 1.0
  
  var shadeColor: UIColor = UIColor.red
  
  var closeRatio: CGFloat = 0.5
  
  required init(overlay: UIViewController, into active: UIViewController) {
    //dislike due if this is not a ViewController why i need them?
    //maybe need to present vc
    /**
     public func slide(toOpen: Bool, animated: Bool = true) {
        let view = active.view!
        shadeView.isHidden = false
        sliderView.isHidden = false
        if !isOpen {
          shadeView.alpha = 0
          active.presentSubVC(controller: slider, inView: contentView)
          view.layoutIfNeeded()
        }
     
     
     */
        fatalError("init(overlay:) has not been implemented");
    }
  
  init(overlayView: UIView, shadeView: UIView) {
    self.overlayView = overlayView
    self.shadeView = shadeView
  }
  
  func open(animated: Bool, fromBottom: Bool) {
    print("todo open")
  }
  
  func close(animated: Bool) {
    print("todo close")
  }
  
  func shrinkTo(rect: CGRect) {
    print("todo shrinkTo rect")
  }
  
  func shrinkTo(targetView: UIView) {
    print("todo shrinkTo view")
  }
}
