//
//  Overlay.swift
//  NorthLib
//
// Created by Ringo Müller-Gromes on 23.06.20.
// Copyright © 2020 Ringo Müller-Gromes for "taz" digital newspaper. All rights reserved.
//
import UIKit

/**
 The Overlay class manages the two view controllers 'overlay' and 'active'.
 'active' is currently visible and 'overlay' will be presented on top of
 'active'. To accomplish this, two views are created, the first one, 'shadeView'
 is positioned on top of 'active.view' with the same size and colored 'shadeColor'
 with an alpha between 0...maxAlpha. This view is used to shade the active view
 controller during the open/close animations. The second view, overlayView is
 used to contain 'overlay' and is animated during opening and closing operations.
 In addition two gesture recognizers (pinch and pan) are used on shadeView to
 start the close animation. The pan gesture is used to move the overlay to the bottom of shadeView.
 The pinch gesture is used to shrink the overlay
 in size while being centered in shadeView. When 'overlay' has been shrunk to
 'closeRatio' (see attribute) or moved 'closeRatio * overlayView.bounds.size.height'
 points to the bottom then 'overlay' is animated automatically away from the
 screen. While the gesture recognizers are working or during the animation the
 alpha of shadeView is changed to reflect the animation's ratio (alpha = 0 =>
 'overlay' is no longer visible). The gesture recognizers coexist with gesture
 recognizers being active in 'overlay'.
 */
/**
 This Class is the container and holds the both VC's
 presentation Process: UIViewControllerContextTransitioning?? or simply
 =====
 ToDo List
 ======
 O Low Prio: Fix From Rect to Rect open/close
 O OverlaySpec
  O=> var overlaySize: CGSize?
  O pinch & zoom & pan only in overlayView or may also in a wrapper over activeVC.view
 */

// MARK: - OverlayAnimator
public class Overlay: NSObject, OverlaySpec, UIGestureRecognizerDelegate {
  //usually 0.4-0.5
  private var openDuration: Double { get { return debug ? 3.0 : 0.4 } }
  private var closeDuration: Double { get { return debug ? 3.0 : 0.25 } }
  private var debug = false
  private var closeAction : (() -> ())?
  
  var shadeView: UIView?
  var overlayVC: UIViewController
  var activeVC: UIViewController
  
  public var overlayView: UIView?
  public var overlaySize: CGSize?
  public var maxAlpha: Double = 0.8
  public var shadeColor: UIColor = .black
  public var closeRatio: CGFloat = 0.5 {
    didSet {
      //Prevent math issues
      if closeRatio > 1.0 { closeRatio = 1.0 }
      if closeRatio < 0.1 { closeRatio = 0.1 }
    }
  }
  
  // MARK: - init
  public required init(overlay: UIViewController, into active: UIViewController) {
    overlayVC = overlay
    activeVC = active
    super.init()
  }
  
  // MARK: - addToActiveVC
  private func addToActiveVC(){
    ///ensure not presented anymore
    if overlayVC.view.superview != nil { removeFromActiveVC()}
    /// config the shade layer
    shadeView = UIView(frame: activeVC.view.frame)
    shadeView?.backgroundColor = shadeColor
    shadeView!.alpha = 0.0
    activeVC.view.addSubview(shadeView!)
    ///configure the overlay vc (TBD::may also create a new one?!)
    let overlayView = UIView()
    overlayView.isHidden = true
    self.overlayView = overlayView
    /// add the pan
    
    let pinchGestureRecognizer
      = UIPinchGestureRecognizer(target: self,
                                 action: #selector(didPinchWith(gestureRecognizer:)))
    let panGestureRecognizer
      = UIPanGestureRecognizer(target: self,
                               action: #selector(didPanWith(gestureRecognizer:)))
    
    overlayView.addGestureRecognizer(panGestureRecognizer)
    overlayView.addGestureRecognizer(pinchGestureRecognizer)
    pinchGestureRecognizer.delegate = self
    //    overlayView.delegate = self
    overlayView.alpha = 1.0
    //    if let size = overlaySize {
    //      overlayView.pinSize(size)
    //    }else{
    overlayView.frame = activeVC.view.frame
    //
    //    }
    overlayView.clipsToBounds = true
    overlayView.addSubview(overlayVC.view)
    
    ///configure the overlay vc and add as child vc to active vc
    overlayVC.view.frame = activeVC.view.frame
    overlayVC.willMove(toParent: activeVC)
    activeVC.view.addSubview(overlayView)
    //ToDo to/toSafe/frame.....
    //the ChildOverlayVC likes frame no autolayout
    //for each child type the animation may needs to be fixed
    //Do make it niche for ImageCollection VC for now!
    NorthLib.pin(overlayView, toSafe: activeVC.view)
    //set overlay view's origin if size given: center
    //    if overlaySize != nil {
    //      NorthLib.pin(overlayView.centerX, to: activeVC.view.centerX)
    //      NorthLib.pin(overlayView.centerY, to: activeVC.view.centerY)
    //    }
    overlayVC.didMove(toParent: activeVC)
    
    if let ct = overlayVC as? OverlayChildViewTransfer {
      ct.addToOverlayContainer(overlayView)
    }
  }
  
  // MARK: showWithoutAnimation
  private func showWithoutAnimation(){
    addToActiveVC()
    self.overlayVC.view.isHidden = false
    shadeView?.alpha = CGFloat(self.maxAlpha)
    overlayView?.isHidden = false
    closeAction = {self.close(animated: false)}
  }
  
  // MARK: open animated
  public func open(animated: Bool, fromBottom: Bool) {
    addToActiveVC()
    closeAction = { self.close(animated: animated, toBottom: fromBottom) }
    guard animated,
      let targetSnapshot
      = overlayVC.view.snapshotView(afterScreenUpdates: true) else {
        showWithoutAnimation()
        return
    }
    targetSnapshot.alpha = 0.0
    
    if fromBottom {
      targetSnapshot.frame = activeVC.view.frame
      targetSnapshot.frame.origin.y += targetSnapshot.frame.size.height
    }
    
    overlayVC.view.isHidden = true
    overlayView?.addSubview(targetSnapshot)
    shadeView?.alpha = 0.0
    overlayView?.isHidden = false
    UIView.animate(withDuration: openDuration, animations: {
      if fromBottom {
        targetSnapshot.frame.origin.y = 0
      }
      self.shadeView?.alpha = CGFloat(self.maxAlpha)
      targetSnapshot.alpha = 1.0
    }) { (success) in
      self.overlayVC.view.isHidden = false
      targetSnapshot.removeFromSuperview()
    }
  }
  
  // MARK: open fromFrame
  public func openAnimated(fromFrame: CGRect, toFrame: CGRect) {
    addToActiveVC()
    closeAction = { self.close(fromRect: toFrame, toRect: fromFrame) }
    guard let fromSnapshot = activeVC.view.resizableSnapshotView(from: fromFrame, afterScreenUpdates: false, withCapInsets: .zero) else {
      showWithoutAnimation()
      return
    }
    guard let targetSnapshot = overlayVC.view.snapshotView(afterScreenUpdates: true) else {
      showWithoutAnimation()
      return
    }
    
    overlayView?.isHidden = false
    targetSnapshot.alpha = 0.0
    
    if debug {
      overlayView?.layer.borderColor = UIColor.green.cgColor
      overlayView?.layer.borderWidth = 2.0
      
      fromSnapshot.layer.borderColor = UIColor.red.cgColor
      fromSnapshot.layer.borderWidth = 2.0
      
      targetSnapshot.layer.borderColor = UIColor.blue.cgColor
      targetSnapshot.layer.borderWidth = 2.0
      
      self.overlayVC.view.layer.borderColor = UIColor.orange.cgColor
      self.overlayVC.view.layer.borderWidth = 2.0
      
      print("fromSnapshot.frame:", fromSnapshot.frame)
      print("targetSnapshot.frame:", toFrame)
    }
    
    fromSnapshot.layer.masksToBounds = true
    fromSnapshot.frame = fromFrame
    
    overlayView?.addSubview(fromSnapshot)
    overlayView?.addSubview(targetSnapshot)
    
    UIView.animateKeyframes(withDuration: openDuration, delay: 0, animations: {
      UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 0.3) {
        self.shadeView?.alpha = CGFloat(self.maxAlpha)
      }
      UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 0.7) {
        fromSnapshot.frame = toFrame
      }
      
      UIView.addKeyframe(withRelativeStartTime: 0.5, relativeDuration: 0.4) {
        fromSnapshot.alpha = 0.0
      }
      UIView.addKeyframe(withRelativeStartTime: 0.7, relativeDuration: 0.3) {
        targetSnapshot.alpha = 1.0
      }
      
    }) { (success) in
      self.overlayVC.view.isHidden = false
      targetSnapshot.removeFromSuperview()
      targetSnapshot.removeFromSuperview()
    }
  }
  
  // MARK: - removeFromActiveVC
  private func removeFromActiveVC(){
    shadeView?.removeFromSuperview()
    shadeView = nil
    overlayVC.view.removeFromSuperview()
    if let ct = overlayVC as? OverlayChildViewTransfer {
      ct.removeFromOverlay()
    }
    overlayView?.removeFromSuperview()
    overlayView = nil
    closing = false
  }
  
  // MARK: close
  var preventRecursive = false
  public func close(animated: Bool) {
    if preventRecursive {
      close(animated: false, toBottom: false)
    }
    else if let action = closeAction {
      preventRecursive = true
      action()
      preventRecursive = false
    } else {
      close(animated: true, toBottom: false)
    }
  }
  
  var closing = false
  // MARK: close to bottom
  public func close(animated: Bool, toBottom: Bool = false) {
    print("close: animted/toBottom ", animated, toBottom)
    if animated == false {
      removeFromActiveVC()
      return;
    }
    if closing { return }
    closing = true
    UIView.animate(withDuration: closeDuration, animations: {
      self.shadeView?.alpha = 0
      self.overlayView?.alpha = 0
      if toBottom {
        self.overlayVC.view.frame.origin.y
        = CGFloat(self.shadeView?.frame.size.height ?? 0.0)
      }
    }, completion: { _ in
      self.removeFromActiveVC()
      self.overlayView?.alpha = 1
    })
  }
  
  // MARK: close fromRect toRect
  public func close(fromRect: CGRect, toRect: CGRect) {
    guard let overlaySnapshot = overlayVC.view.resizableSnapshotView(from: fromRect, afterScreenUpdates: false, withCapInsets: .zero) else {
      self.close(animated: true)
      return
    }
    
    if debug {
      print("todo close fromRect", fromRect, "toRect", toRect)
      overlaySnapshot.layer.borderColor = UIColor.magenta.cgColor
      overlaySnapshot.layer.borderWidth = 2.0
    }
    
    overlaySnapshot.frame = fromRect
    overlayView?.addSubview(overlaySnapshot)
    if closing { return }
    closing = true
    UIView.animateKeyframes(withDuration: closeDuration, delay: 0, animations: {
      UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 0.4) {
        self.overlayVC.view.alpha = 0.0
      }
      UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 0.7) {
        overlaySnapshot.frame = toRect
        
      }
      UIView.addKeyframe(withRelativeStartTime: 0.7, relativeDuration: 0.3) {
        overlaySnapshot.alpha = 0.0
      }
      UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 1) {
        self.shadeView?.alpha = 0.0
      }
    }) { (success) in
      self.removeFromActiveVC()
      self.overlayView?.alpha = 1.0
      self.overlayVC.view.alpha = 1.0
    }
  }
  
  // MARK: shrinkTo rect
  public func shrinkTo(rect: CGRect) {
    /** TBD OVERLAY SIZE **/
    //    if let fromRect = overlaySize TBD {
    //          close(fromRect: fromRect, toRect: rect)
    //    }
    close(fromRect: overlayVC.view.frame, toRect: rect)
  }
  // MARK: shrinkTo targetView
  public func shrinkTo(view: UIView) {
    if !view.isDescendant(of: activeVC.view) {
      self.close(animated: true)
      return;
    }
    /** TBD OVERLAY SIZE **/
    //    if let fromRect = overlaySize TBD {
    //          close(fromRect: fromRect, toRect: rect)
    //    }
    
    close(fromRect: overlayVC.view.frame, toRect: activeVC.view.convert(view.frame, from: view))
  }
  
  
  var otherGestureRecognizersScrollView : UIScrollView?
  // MARK: - UIGestureRecognizerDelegate
  public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                                shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
    
    if let sv = otherGestureRecognizer.view as? UIScrollView {
      otherGestureRecognizersScrollView = sv
    }
    return true
  }
  
  // MARK: - didPanWith
  var panStartY:CGFloat = 0.0
  @IBAction func didPanWith(gestureRecognizer: UIPanGestureRecognizer) {
    let translatedPoint = gestureRecognizer.translation(in: overlayView)
    
    if gestureRecognizer.state == .began {
      panStartY = gestureRecognizer.location(in: overlayView).y
        + translatedPoint.y
    }
    
    self.overlayVC.view.frame.origin.y = translatedPoint.y > 0 ? translatedPoint.y : translatedPoint.y*0.4
    self.overlayVC.view.frame.origin.x = translatedPoint.x*0.4
    let p = translatedPoint.y/(overlayView?.frame.size.height ?? 0-panStartY)
    if translatedPoint.y > 0 {
      debug ? print("panDown... ",self.shadeView?.alpha as Any, (1 - p), p, self.maxAlpha) : ()
      self.shadeView?.alpha = max(0, min(1-p, CGFloat(self.maxAlpha)))
    }
    
    if gestureRecognizer.state == .ended {
      debug ? print("ended... ",self.shadeView?.alpha as Any, (1 - p), p, self.maxAlpha) : ()
      if 2*p > closeRatio {
        closeAction?()
        self.close(animated: true, toBottom: true)
      }
      else {
        UIView.animate(seconds: closeDuration) {
          self.overlayVC.view.frame.origin = .zero
          self.shadeView?.alpha = CGFloat(self.maxAlpha)
        }
      }
    }
  }
  
  // MARK: - didPinchWith
  var pinchStartTransform: CGAffineTransform?
  var canCloseOnEnd = false
  @IBAction func didPinchWith(gestureRecognizer: UIPinchGestureRecognizer) {
    if let sv = otherGestureRecognizersScrollView {
      //the .ended comes delayed, after the inner scrollview bounced back,
      //so i remember the last value and close of pinch ended
      //!Not closing due pinch this would be non natural behaviour
      if canCloseOnEnd, gestureRecognizer.state == .ended {
        self.close(animated: true)
      }
      //The inner scrollview can zoom out to half of its minimum zoom factor
      //e.g. minimum zoom factor = 0.2 current zooFactor = 0.2
      //its had to zoom smaller than 0.1 on Device
      //if close ratio is 0.5, the limit would be reached at 0.15
      canCloseOnEnd = sv.zoomScale < closeRatio*0.5*sv.minimumZoomScale + 0.5*sv.minimumZoomScale
      return;
    }
    ///handle pinch for non inner ScrollView ...do the zoom out here!
    guard gestureRecognizer.view != nil else { return }
    if gestureRecognizer.state == .began {
      pinchStartTransform = gestureRecognizer.view?.transform
    }
    
    if gestureRecognizer.state == .began || gestureRecognizer.state == .changed {
      gestureRecognizer.view?.transform = (gestureRecognizer.view?.transform.scaledBy(x: gestureRecognizer.scale, y: gestureRecognizer.scale))!
      gestureRecognizer.scale = 1.0
    }
    else if gestureRecognizer.state == .ended {
      if gestureRecognizer.view?.transform.a ?? 1.0 < closeRatio {
         self.close(animated: true)
      }
      else if(self.pinchStartTransform != nil){
        UIView.animate(seconds: closeDuration) {
          gestureRecognizer.view?.transform = self.pinchStartTransform!
        }
      }
    }
  }
}

// MARK: - OverlayChildViewTransfer
public protocol OverlayChildViewTransfer {
  /// add and Layout to Child Views
  func addToOverlayContainer(_ container:UIView?)
  ///optional
  func removeFromOverlay()
}

// MARK: ext:ZoomedImageView
extension ZoomedImageView : OverlayChildViewTransfer{
  /// add and Layout to Child Views
  public func addToOverlayContainer(_ container:UIView?){
    guard let container = container else { return }
    container.addSubview(self.xButton)
    NorthLib.pin(self.xButton.right, to: container.rightGuide(), dist: -15)
    NorthLib.pin(self.xButton.top, to: container.topGuide(), dist: 15)
  }
  ///optional
  public func removeFromOverlay(){
    self.xButton.removeFromSuperview()
  }
}

// MARK: ext:ImageCollectionVC
extension ImageCollectionVC : OverlayChildViewTransfer{
  /// add and Layout to Child Views
  public func addToOverlayContainer(_ container:UIView?){
    guard let container = container else { return }
    self.collectionView.backgroundColor = .clear
    container.addSubview(self.xButton)
    pin(self.xButton.right, to: container.rightGuide(), dist: -15)
    pin(self.xButton.top, to: container.topGuide(), dist: 15)
    if let pc = self.pageControl {
      container.addSubview(pc)
      pin(pc.centerX, to: container.centerX)
      // Example values for dist to bottom and height
      pin(pc.bottom, to: container.bottomGuide(), dist: -15)
    }
  }
  
  ///optional
  public func removeFromOverlay(){
    self.xButton.removeFromSuperview()
    self.pageControl?.removeFromSuperview()
  }
}
