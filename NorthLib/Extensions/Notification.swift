//
//  Notification.swift
//
//  Created by Norbert Thies on 27.04.20.
//  Copyright © 2020 Norbert Thies. All rights reserved.
//

import Foundation

public struct Notif {
  
  /// Send Notification
  public static func send(_ message: String, object: Any? = nil) {
    let nn = NSNotification.Name(message)
    let notification = Notification(name: nn, object: object)
    NotificationCenter.default.post(notification)
  }
}

public extension Notification {
  
  typealias Observer = NSObjectProtocol?
  
  /// Send Notification
  static func send(_ message: String, object: Any? = nil) {
    let nn = NSNotification.Name(message)
    let notification = Notification(name: nn, object: object)
    NotificationCenter.default.post(notification)
  }
  
  /// Receive Notification on main thread and return observer object
  @discardableResult
  static func receive(_ message: String, closure: @escaping (Any?)->()) 
    -> Observer {
    let nn = NSNotification.Name(message)
    let observer = NotificationCenter.default.addObserver(forName: nn, 
                     object: nil, queue: nil) { notification in
      closure(notification.object)
    }
    return observer
  }
  
  /// Remove observer
  static func remove(observer: Observer) {
    if let observer = observer {
      NotificationCenter.default.removeObserver(observer)
    }
  }
  
} // Notification Extensions
