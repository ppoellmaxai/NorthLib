//
//  ExportDialogue.swift
//
//  Created by Norbert Thies on 02.05.20.
//  Copyright © 2020 Norbert Thies. All rights reserved.
//

import UIKit

open class ExportDialogue<T>: NSObject, UIActivityItemSource {

  /// The item to export
  var item: T?  
  /// A String describing the item (ie used as Subject in eMails
  var subject: String?
  
  public func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
    if let item = item { return item }
    else { return "Error" }
  }
  
  public func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
    if let item = item { return item }
    else { return "Error" }
  }
  
  public func activityViewController(_ activityViewController: UIActivityViewController, subjectForActivityType activityType: UIActivity.ActivityType?) -> String {
    if let str = subject { return str }
    else { return "" }
  }
  
  /// Create export dialogue
  public func present(item: T, view: UIView? = nil, subject: String? = nil) {
    self.item = item
    self.subject = subject
    let aController = UIActivityViewController( activityItems: [self],
      applicationActivities: nil)
    aController.presentAt(view)
  } 
  
} // ExportDialogue

