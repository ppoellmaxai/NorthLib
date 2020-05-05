//
//  CubeLabel.swift
//
//  Created by Norbert Thies on 20.04.20.
//  Copyright © 2020 Norbert Thies. All rights reserved.
//

import UIKit

open class CubeLabel: UILabel, Touchable {
   
  /// indicates scroll direction
  public var scrollUp = true
  
  /// Define text to scroll to
  override open var text: String? {
    get { return super.text }
    set { cubeTransition(text: newValue, isUp: scrollUp) }
  }
  
  /// The label's text without rotation
  open var pureText: String? {
    get { return super.text }
    set { super.text = newValue }
  }
  
  /// Define text and scroll direction
  public func setText(_ text: String?, isUp: Bool) 
    { cubeTransition(text: text, isUp: isUp) }
  
  /// To recognized taps on the label
  public var tapRecognizer = TapRecognizer()
  
  private var inAnimation = false
  private var lastText: String?
  private var lastDirection: Bool?
  
  private func cubeTransition( text: String?, isUp: Bool = true ) {
    if (super.text == nil) || (text == nil) { super.text = text; return }
    guard !inAnimation else { lastText = text; lastDirection = isUp; return }
    inAnimation = true
    let newLabel = UILabel(frame: self.frame)
    newLabel.text = text
    newLabel.font = self.font
    newLabel.textAlignment = self.textAlignment
    newLabel.textColor = self.textColor
    newLabel.backgroundColor = self.backgroundColor
    let direction: CGFloat = isUp ? -1 : 1
    let offset = (self.frame.size.height/2) * direction
    newLabel.transform = CGAffineTransform(translationX: 0.0, y: offset).scaledBy(x: 1.0, y: 0.1)
    self.superview?.addSubview(newLabel)
    UIView.animate(withDuration: 0.4, delay: 0.0, options: .curveEaseOut, animations: {
      newLabel.transform = .identity
      self.transform = CGAffineTransform(translationX: 0.0, y: -offset).scaledBy(x: 1.0, y: 0.1)
    }) { _ in
      super.text = newLabel.text
      self.transform = .identity
      newLabel.removeFromSuperview()
      self.inAnimation = false
      if let txt = self.lastText {
        var direction = isUp
        if let lastDirection = self.lastDirection { direction = lastDirection }
        self.lastText = nil
        self.lastDirection = nil
        self.cubeTransition(text: txt, isUp: direction)
      }
    }
  }

} // CubeLabel

