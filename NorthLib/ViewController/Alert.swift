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
  public static func message(title: String, message: String, closure: (()->())? = nil) {
    let alert = UIAlertController(title: title, message: "\n\(message)", preferredStyle: .alert)
    let okButton = UIAlertAction(title: "OK", style: .default) { _ in closure?() }
    alert.addAction(okButton)
    UIWindow.rootVC?.present(alert, animated: false, completion: nil)
  }
  
  /// Ask the user for confirmation (as action sheet)
  public static func confirm(title: String? = nil, message: String, 
    okText: String = "OK", isDestructive: Bool = false, closure: ((Bool)->())?) {
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
