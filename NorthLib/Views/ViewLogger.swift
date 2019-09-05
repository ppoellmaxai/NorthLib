//
//  ViewLogger.swift
//
//  Created by Norbert Thies on 16.05.19.
//  Copyright © 2019 Norbert Thies. All rights reserved.
//

import UIKit

extension Log {
  
  /// A ViewLogger writes all passed log messages to a TextView
  open class ViewLogger: Logger {
    
    /// TextView to log to
    public var textView: UITextView
    
    /// The ViewLogger must be initialized with a TextView
    public init(textView: UITextView) {
      self.textView = textView
      super.init()
      textView.isEditable = false
      textView.text = ""
    }
    
    /// log a message to the TextView
    public override func log(_ msg: Message) {
      DispatchQueue.main.async { [weak self] in
        if let this = self {
          let txt = String(describing: msg)
          if txt.hasSuffix("\n") { this.textView.text.append(txt) }
          else { this.textView.text.append(txt + "\n") }
          let range = NSMakeRange(this.textView.text.count - 1, 0)
          this.textView.scrollRangeToVisible(range)
        }
      }
    }
    
  } // class ViewLogger
  
} // extension Log
