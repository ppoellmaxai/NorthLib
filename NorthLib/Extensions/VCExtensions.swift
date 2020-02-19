//
//  VCExtensions.swift
//
//  Created by Norbert Thies on 01.05.16.
//  Copyright © 2016 Norbert Thies. All rights reserved.
//

import UIKit


public extension UIViewController {
  
  /**
   * `presentSubVC(controller:inView:)` takes a view controller 'controller'
   * and presents it in a subview 'inView' so that all views of 'controller'' are clipped by
   * the bounds of 'inView'.
   * - Parameters:
   *   - controller: the view controller to present
   *   - inView:     the view in which controller is presented (and clipped)
   * - Returns: controller
   */
  @discardableResult
  func presentSubVC(controller ctr: UIViewController,
                    inView view:UIView) -> UIViewController {
    ctr.view.frame = view.bounds
    ctr.willMove(toParent: self)
    view.addSubview(ctr.view)
    view.clipsToBounds = true
    self.addChild(ctr)
    ctr.didMove(toParent: self)
    return ctr
  }
  
  /**
   * `presentSubVC(name:inView:)` reads a view controller named 'name',
   * reads it from the default storyboard and presents it in a subview 'inView' so
   * that all views of 'name'' are clipped by the bounds of 'inView'.
   * - Parameters:
   *   - name:   the name of the view controller to present
   *   - inView: the view in which controller is presented (and clipped)
   * - Returns:
   *   - the view controller if it could be read from the storyboard
   *   - nil if the view controller couldn't be found
   */
  func presentSubVC(name: String, inView view: UIView)
    -> UIViewController? {
      if let ctr = self.storyboard?.instantiateViewController(withIdentifier: name) {
        return presentSubVC(controller: ctr, inView: view)
      }
      else { return nil }
  }
  
  /// removes a subview controller
  func removeSubVC(_ ctr: UIViewController) {
    ctr.willMove(toParent: nil)
    ctr.view.removeFromSuperview()
    ctr.removeFromParent()
  }
  
  /// returns the width of the device's screen
  var screenWidth: CGFloat { return UIScreen.main.bounds.size.width }
  
  /// returns the height of the device's screen
  var screenHeight: CGFloat { return UIScreen.main.bounds.size.height }

  /**
   * `confirm(_:atView:block:)` produces a modal popup box (popover, UIAlert) to
   * ask the user for confirmation. It presents a "yes" and "no" button for the
   * user to select.
   * - Parameters:
   *   - message:  String asking for confirmation
   *   - atView:   view used as anchor for the popover
   *   - block:    closure to call when button is pressed
   */
  func confirm(_ message: String, atView sourceView: UIView,
                block:@escaping (Bool)->()) {
    let actions = UIAlertController.init( title: "Bestätigung",
                                          message: message, preferredStyle: .actionSheet )
    actions.addAction( UIAlertAction.init( title: "Ja", style: .default ) {
      (handler: UIAlertAction) in
      block( true )
    } )
    actions.addAction( UIAlertAction.init( title: "Nein", style: .default ) {
      (handler: UIAlertAction) in
      block( false )
    } )
    actions.popoverPresentationController?.sourceView = sourceView
    actions.popoverPresentationController?.sourceRect =
      CGRect(x: 0, y: 0, width: 0, height: 0)
    present(actions, animated: true, completion: nil)
  }
  
  /**
   * `top` returns the top most view controller
   */
  class func top(controller: UIViewController? = UIApplication.shared.keyWindow?.rootViewController)
    -> UIViewController? {
    if let navigationController = controller as? UINavigationController {
      return top(controller: navigationController.visibleViewController)
    }
    if let tabController = controller as? UITabBarController {
      if let selected = tabController.selectedViewController {
        return top(controller: selected)
      }
    }
    if let presented = controller?.presentedViewController {
      return top(controller: presented)
    }
    return controller
  }
  
  /**
   loadFromNib instantiates a view controler from a nib file
   */
  class func loadFromNib() -> Self {
    func instantiateFromNib<T: UIViewController>() -> T {
      return T.init(nibName: String(describing: T.self), bundle: nil)
    }    
    return instantiateFromNib()
  }
  
} // extension UIViewController
