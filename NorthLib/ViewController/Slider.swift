//
//  Slider.swift
//
//  Created by Norbert Thies on 10.12.18.
//  Copyright © 2018 Norbert Thies. All rights reserved.
//

import UIKit

/**
 *  A Slider models a view controller that is slid into another (currently
 *  active) view controller either from the left or from the right side.
 *  In order to slide the subview controller there are two new views created:
 *    - a shade view that is used to dim the view of the current view controller
 *    - a slider view that is used to contain the subview controller
 *  A tap on the shade view slides the subview controller back to the left (or
 *  right) and removes it from the slider view. Following the shade and slider views
 *  are removed.
 */

open class Slider: NSObject, DoesLog {
  
  /// currently active view controller to slide into
  public var active: UIViewController
  /// view controller being slid in
  public var slider: UIViewController
  /// slide in from left? (from right otherwise)
  public var fromLeft: Bool = true { didSet { resetConstraints() } }
  /// how much of the active view controller is covered by the slider
  /// (80% by default)
  public var coverageRatio:CGFloat = 0.8
  /// how long shall the sliding animation be (in seconds, 0.5 by default)
  public var duration:TimeInterval = 0.5
  
  /// how many points of the active view controller are covered by the slider
  /// (derived from coverageRatio by default)
  public var coverage: CGFloat { return active.view.bounds.width * coverageRatio }
  
  // is slider opened
  fileprivate var isOpened = false
  
  fileprivate var openClosure: ((Slider)->())? = nil
  fileprivate var closeClosure: ((Slider)->())? = nil
  fileprivate var tmpOpenClosure: ((Slider)->())? = nil
  fileprivate var tmpCloseClosure: ((Slider)->())? = nil

  /// defines the closure to call when the slider has been slid in
  public func onOpen(closure: @escaping (Slider)->()) {
    openClosure = closure
  }
  
  /// defines the closure to call when the slider has been removed
  public func onClose(closure: @escaping (Slider)->()) {
    closeClosure = closure
  }
  
  public var shadeView = UIView()
  public var sliderView = UIView()
  
  public lazy var leadingConstraint =
    sliderView.leadingAnchor.constraint(equalTo:active.view.leadingAnchor)
  public lazy var trailingConstraint =
    sliderView.trailingAnchor.constraint(equalTo:active.view.trailingAnchor)
  public lazy var widthConstraint =
    sliderView.widthAnchor.constraint(equalToConstant: 0)

  public func invariableConstraints() -> [NSLayoutConstraint] {
    let view = active.view!
    return [
      shadeView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      shadeView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
      shadeView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      shadeView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      sliderView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      sliderView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ]
  }

  public func resetConstraints() {
    widthConstraint.isActive = true
    widthConstraint.constant = coverage
    if isOpened {
      leadingConstraint.constant = 0
      trailingConstraint.constant = 0
    }
    else {
      leadingConstraint.constant = -coverage
      trailingConstraint.constant = coverage
    }
    if fromLeft {
      leadingConstraint.isActive = true
      trailingConstraint.isActive = false
    }
    else {
      leadingConstraint.isActive = false
      trailingConstraint.isActive = true
    }
    active.view.layoutIfNeeded()
  }
  
  public func toggleSlider() {
    slide(toOpen: !isOpened)
  }

  @objc public func handleTap() {
    toggleSlider()
  }
  
  /// A Slider is initialized with the view controller to slide in and a
  /// second view controller to slide into
  public init(slider: UIViewController, into active: UIViewController) {
    self.slider = slider
    self.active = active
    super.init()
    shadeView.backgroundColor = UIColor.black
    shadeView.translatesAutoresizingMaskIntoConstraints = false
    shadeView.isHidden = true
    sliderView.translatesAutoresizingMaskIntoConstraints = false
    sliderView.isHidden = true
    let tapRecognizer = UITapGestureRecognizer(target: self,
                                               action: #selector(handleTap))
    tapRecognizer.numberOfTapsRequired = 1
    shadeView.addGestureRecognizer(tapRecognizer)
    active.view.addSubview(shadeView)
    active.view.addSubview(sliderView)
    NSLayoutConstraint.activate(invariableConstraints())
    resetConstraints()
  }
  
  public func slide(toOpen: Bool, animated: Bool = true) {
    if toOpen == isOpened { return }
    let view = active.view!
    shadeView.isHidden = false
    sliderView.isHidden = false
    if !isOpened {
      shadeView.alpha = 0
      active.presentSubVC(controller: slider, inView: sliderView)
      view.layoutIfNeeded()
    }
    isOpened = toOpen
    let duration = animated ? self.duration : 0
    UIView.animate(withDuration: duration, delay: 0, usingSpringWithDamping: 0.8,
                   initialSpringVelocity: 0.2, options: .curveEaseOut, animations: {
      if self.isOpened { self.shadeView.alpha = 0.2 }
      else { self.shadeView.alpha = 0 }
      self.resetConstraints()
    }) { _ in // completion
      if !self.isOpened { // remove slider
        self.active.removeSubVC(self.slider)
        self.shadeView.isHidden = true
        self.sliderView.isHidden = true
        view.layoutIfNeeded()
        if let closure = self.tmpCloseClosure { self.tmpCloseClosure = nil; closure(self) }
        if let closure = self.closeClosure { closure(self) }
      }
      else {
        if let closure = self.tmpOpenClosure { self.tmpOpenClosure = nil; closure(self) }
        if let closure = self.openClosure { closure(self) }
      }
    }
  }
  
  /// open the slider (slider sliding in)
  public func open(animated: Bool = true, closure: ((Slider)->())? = nil) {
    tmpOpenClosure = closure
    slide(toOpen: true, animated: animated)
  }
  
  /// close the slider (slide out)
  public func close(animated: Bool = true, closure: ((Slider)->())? = nil) {
    tmpCloseClosure = closure
    slide(toOpen: false, animated: animated)
  }
  
} // class Slider


/**
 *  A ButtonSlider is a Slider that uses an image as a Button at the top left
 *  corner of the active view controller to slide in a slider view controller.
 */

open class ButtonSlider: Slider {
  
  /// image to use as button
  public var image: UIImage? {
    didSet {
      guard let img = image else { return }
      button.setImage(img, for: .normal)
      resetConstraints()
    }
  }
  public var button = UIButton(type: .custom)
  public var buttonAlpha: CGFloat = 0.9 {
    didSet { button.alpha = buttonAlpha }
  }
  public var shiftRatio: CGFloat = 0.1 { didSet { resetConstraints() } }
  public var shift: CGFloat { return (image?.size.width ?? 0) * shiftRatio }
  public var topInset: CGFloat = 7 { didSet { resetConstraints() } }
  public override var fromLeft: Bool { didSet { resetConstraints() } }
  
  public override var coverage: CGFloat {
    if let img = image { return active.view!.bounds.size.width - img.size.width }
    else { return super.coverage }
  }
  
  public lazy var leadingButtonConstraint: NSLayoutConstraint =
    button.leadingAnchor.constraint(equalTo: sliderView.trailingAnchor)
  public lazy var trailingButtonConstraint: NSLayoutConstraint =
    button.trailingAnchor.constraint(equalTo: sliderView.leadingAnchor)
  public lazy var topButtonConstraint: NSLayoutConstraint =
    button.topAnchor.constraint(equalTo: active.view.safeAreaLayoutGuide.topAnchor)
  public lazy var widthButtonConstraint: NSLayoutConstraint =
    button.widthAnchor.constraint(equalToConstant: 0)
  public lazy var heightButtonConstraint: NSLayoutConstraint =
    button.heightAnchor.constraint(equalToConstant: 0)
  
  public override func resetConstraints() {
    super.resetConstraints()
    topButtonConstraint.constant = topInset
    if let img = image {
      widthButtonConstraint.constant = img.size.width
      heightButtonConstraint.constant = img.size.height
    }
    if fromLeft {
      leadingButtonConstraint.constant = -shift
      leadingButtonConstraint.isActive = true
      trailingButtonConstraint.isActive = false
    }
    else {
      trailingButtonConstraint.constant = shift
      trailingButtonConstraint.isActive = true
      leadingButtonConstraint.isActive = false
    }
    NSLayoutConstraint.activate([topButtonConstraint, widthButtonConstraint,
                                 heightButtonConstraint])
    active.view?.layoutIfNeeded()
  }
  
  @objc public func buttonPressed(sender: UIButton) {
    toggleSlider()
  }
  
  public override init(slider: UIViewController, into active: UIViewController) {
    active.view.addSubview(button)
    button.translatesAutoresizingMaskIntoConstraints = false
    super.init(slider: slider, into: active)
    active.view.bringSubviewToFront(button)
    button.addTarget(self, action: #selector(buttonPressed(sender:)), for: .touchUpInside)
  }
  
  public func buttonFadeOut( _ duration: TimeInterval, atEnd: (()->())? = nil ) {
    UIView.animate(withDuration: duration, delay: 0, options: .curveEaseOut, animations: {
      self.button.alpha = 0
    } ) { _ in
      if let closure = atEnd { closure() }
    }
  }
  
  public func buttonFadeIn( _ duration: TimeInterval, atEnd: (()->())? = nil ) {
    UIView.animate(withDuration: duration, delay: 0, usingSpringWithDamping: 0.03,
                   initialSpringVelocity: 0.0, options: .curveEaseOut, animations: {
      self.button.alpha = self.buttonAlpha
    } ) { _ in
      if let closure = atEnd { closure() }
    }
  }
  
  public func blinkButton() {
    let tout: TimeInterval = 1.2
    let tin: TimeInterval = 1.5
    self.buttonFadeOut(tout) {
      self.buttonFadeIn(tin)
    }
  }
  
} // class ButtonSlider
