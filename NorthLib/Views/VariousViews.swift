//
//  VariousViews.swift
//
//  Created by Norbert Thies on 06.04.20.
//  Copyright © 2020 Norbert Thies. All rights reserved.
//

import UIKit

/// An undefined View - ie. a placeholder view
open class UndefinedView: UIView {
  public var label = UILabel()
  
  private func setup() {
    backgroundColor = UIColor.red
    label.backgroundColor = UIColor.clear
    label.font = UIFont.boldSystemFont(ofSize: 200)
    label.textColor = UIColor.yellow
    label.textAlignment = .center
    label.adjustsFontSizeToFitWidth = true
    label.text = "?"
    addSubview(label)
    pin(label.centerX, to: self.centerX)
    pin(label.centerY, to: self.centerY)
    pin(label.width, to: self.width, dist: -20)
  }
  
  public override init(frame: CGRect) {
    super.init(frame: frame)
    setup()
  }
  
  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    setup()
  }
}

/// A view consisting of a main view that is usually to show and a so called
/// waiting view that is presented until the main view is available (eg. loaded
/// from the internet)
public protocol OptionalView {
  var mainView: UIView { get }
  var waitingView: UIView? { get }
  var isAvailable: Bool { get }
  func whenAvailable(closure: @escaping ()->())
  func loadView()
}

public extension OptionalView {
  var activeView: UIView { return isAvailable ? mainView : (waitingView ?? UndefinedView()) }
}

/// Common Views can be optional
extension UIView: OptionalView {
  public var mainView: UIView { return self }
  public var waitingView: UIView? { return nil }
  public var isAvailable: Bool { return true }
  public func whenAvailable(closure: @escaping () -> ()) {}
  public func loadView() {}
}
