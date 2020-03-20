//
//  FontExtensions.swift
//
//  Created by Norbert Thies on 04.03.20.
//  Copyright © 2020 Norbert Thies. All rights reserved.
//

import UIKit

public extension UIFont {

  /// Get font from Data
  static func new(data: Data, size: CGFloat) -> UIFont? {
    var font: UIFont? = nil
    if let dataProvider = CGDataProvider(data: data as NSData),
       let cgFont = CGFont(dataProvider) {
      var error: Unmanaged<CFError>?
      if CTFontManagerRegisterGraphicsFont(cgFont, &error) {
        font = UIFont(name: cgFont.postScriptName! as String, size: size)
      }
    }
    return font
  }
  
  /// Get font from file in local FS
  static func new(path: String, size: CGFloat) -> UIFont? {
    return new(data: File(path).data, size: size)
  }
  
  /// Get font from file with extension ".ttf" in main Bundle
  static func new(name: String, size: CGFloat) -> UIFont? {
    guard let path = Bundle.main.path(forResource: name, ofType: "ttf") 
      else { return nil }
    return new(path: path, size: size)
  }

}
