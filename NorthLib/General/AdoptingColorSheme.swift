//
//  AdoptingColorSheme.swift
//  NorthLib
//
//  Created by Ringo on 03.09.20.
//  Copyright © 2020 Norbert Thies. All rights reserved.
//

import Foundation

public let globalStylesChangedNotification = "globalStylesChanged"

public protocol AdoptingColorSheme {
  func adoptColorSheme(_ forNewer:Bool)
  func registerHandler(_ forNewer:Bool?)
  //  var forNeewer:Bool {get set}
}
//
//protocol AdoptingColorSheme13 : AdoptingColorSheme {
//  //for not traidcollection...
//}

/// Future Idea: registerHandler() must not be called in Class which implements AdoptingColorSheme
/// itself its called by adding protocoll
//extension AdoptingColorSheme where Self: UIView {
//  override func layoutSublayers(of layer: CALayer) {
//    sup
//  }
//  func registerHandler2(){
//    self.loadView()
//  }
//}

public extension AdoptingColorSheme {
  
  func registerHandler(_ forNewer:Bool? = false){
    self.adoptColorSheme(false)
    if #available(iOS 13.0, *) {
      if forNewer == true {
        Notification.receive(globalStylesChangedNotification) {_ in
          self.adoptColorSheme(true)
        }
      }
      //Do Nothing, handled by: UIApplication.shared.keyWindow?.overrideUserInterfaceStyle = .dark
    } else {
      Notification.receive(globalStylesChangedNotification) {_ in
        self.adoptColorSheme(false)
      }
    }
  }
}
