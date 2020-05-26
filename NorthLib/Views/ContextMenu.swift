//
//  ContextMenu.swift
//
//  Created by Norbert Thies on 25.05.20.
//  Copyright © 2020 Norbert Thies. All rights reserved.
//

import UIKit

/**
 A ContextMenu is used to display a context menu (if iOS >= 13) or an alert
 controller showing an action sheet when a long touch is performed on a
 certain view.
 */
open class ContextMenu: NSObject, UIContextMenuInteractionDelegate {
  
  /// The view on which to show the context menu
  public var view: UIView
  
  /// Initialize with a view on which to define the context menu
  public init(view: UIView) {
    self.view = view
    super.init()
  }
  
  /// Define the menu to display on long touch
  public var menu: [(title: String, icon: String, closure: (String)->())] = [] {
    willSet {
      if menu.count == 0 {
        view.isUserInteractionEnabled = true   
        if #available(iOS 13.0, *) {
          let menuInteraction = UIContextMenuInteraction(delegate: self)
          view.addInteraction(menuInteraction)      
        }
        else {
          let longTouch = UILongPressGestureRecognizer(target: self, 
                            action: #selector(actionMenuTapped))
          longTouch.numberOfTouchesRequired = 1
          view.addGestureRecognizer(longTouch)
        }
      }      
    }
  }
  
  @objc func actionMenuTapped(_ sender: UIGestureRecognizer) {
    var actionMenu: [UIAlertAction] = []
    for m in menu {
      actionMenu += Alert.action(m.title, closure: m.closure)
    }
    Alert.actionSheet(actions: actionMenu)
  }
  
  /// Add an additional menu item
  public func addMenuItem(title: String, icon: String, 
                          closure: @escaping (String)->()) {
    menu += (title: title, icon: icon, closure: closure)
  }
  
  @available(iOS 13.0, *)
  fileprivate func createContextMenu() -> UIMenu {
    let menuItems = menu.map { m in
      UIAction(title: m.title, image: UIImage(systemName: m.icon)) {_ in m.closure(m.title) }
    }
    return UIMenu(title: "", children: menuItems)
  }
  
  // MARK: - UIContextMenuInteractionDelegate protocol

  @available(iOS 13.0, *)
  public func contextMenuInteraction(_ interaction: UIContextMenuInteraction, 
    configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
    return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) 
    { _ -> UIMenu? in 
      return self.createContextMenu()
    }
  }
  
} // ContextMenu
