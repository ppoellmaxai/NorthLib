//
//  Alert.swift
//
//  Created by Norbert Thies on 28.02.20.
//  Copyright © 2020 Norbert Thies. All rights reserved.
//

import UIKit

/// A wrapper around some UIAlertController using static methods
open class Alert {
  
  /// Popup message to user
  public static func message(title: String? = nil, message: String, closure: (()->())? = nil) {
    self.message(title: title, message: message, closure: closure, additionalActions: nil)
  }
  
  public static func message(title: String? = nil,
                             message: String,
                             closure: (()->())? = nil,
                             additionalActions : [UIAlertAction]? = nil) {
    onMain {
      let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
      //Prefer destructive style due it makes a red button
      let okButton = UIAlertAction(title: "OK", style: .cancel) { _ in closure?() }
      alert.addAction(okButton)
      for action  in additionalActions ?? [] {
        alert.addAction(action)
      }
      //present even if there is still a modal View presented
      UIViewController.top()?.present(alert, animated: true, completion: nil)
    }
  }
  
  /// Ask the user for confirmation (as action sheet)
  public static func confirm(title: String? = nil, message: String, 
                             okText: String = "OK", isDestructive: Bool = false, 
                             closure: ((Bool)->())?) {
    onMain {
      var okStyle: UIAlertAction.Style = .default
      if isDestructive { okStyle = .destructive }
      let alert = UIAlertController(title: title, message: "\n\(message)", preferredStyle: .alert)
      let okButton = UIAlertAction(title: okText, style: okStyle) { _ in closure?(true) }
      let cancelButton = UIAlertAction(title: "Abbrechen", style: .cancel) { _ in closure?(false) }
      alert.addAction(okButton)
      alert.addAction(cancelButton)
      UIWindow.rootVC?.present(alert, animated: false, completion: nil)  
    }
  }

  /// Generates a UIAlertAction
  public static func action(_ title: String, style: UIAlertAction.Style = .default, 
                            closure: @escaping (String)->()) -> UIAlertAction {
    return UIAlertAction(title: title, style: style) {_ in closure(title) }
  }

  /// Presents an action sheet with a number of buttons
  public static func actionSheet(title: String? = nil, message: String? = nil, 
                                 actions: [UIAlertAction])  {
    onMain {
      var msg: String? = nil
      if let message = message { msg = "\n\(message)" }
      let alert = UIAlertController(title: title, message: msg, preferredStyle: .actionSheet)
      let cancelButton = UIAlertAction(title: "Abbrechen", style: .cancel)
      for a in actions { alert.addAction(a) }
      alert.addAction(cancelButton)
      UIWindow.rootVC?.present(alert, animated: true, completion: nil)    
    }
  }

  /// Presents an action sheet with a number of buttons
  public static func actionSheet(title: String? = nil, message: String? = nil, 
                                 actions: UIAlertAction...) {
    actionSheet(title: title, message: message, actions: actions)
  }
  
} // Alert
