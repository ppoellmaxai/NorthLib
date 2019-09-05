//
//  ColorExtensions.swift
//
//  Created by Norbert Thies on 15.04.16.
//  Copyright © 2016 Norbert Thies. All rights reserved.
//

import UIKit


public extension UIColor {

  /// Returns a UIColor from an Int with 0xRRGGBB
  static func rgb(_ color: Int) -> UIColor {
    let blue:CGFloat = CGFloat(color & 0xff),
        green:CGFloat = CGFloat( (color >> 8) & 0xff ),
        red:CGFloat = CGFloat( (color >> 16) & 0xff )
    return UIColor(red: red/255, green: green/255, blue: blue/255, alpha: 1.0)
  }
  
  /// Returns a tuple (red,green,blue,alpha) of CGFloat values (0<=value<=1)
  func rgba() -> (red:CGFloat, green:CGFloat, blue:CGFloat, alpha:CGFloat) {
    var r:CGFloat = 0, g:CGFloat = 0, b:CGFloat = 0, a:CGFloat = 0
    getRed( &r, green: &g, blue: &b, alpha: &a )
    return (r,g,b,a)
  }
  
  /**
   * Returns a lighter or darker color depending on `factor`.
   *
   * This operator takes a UIColor `color` and returns a newly created color
   * so that the red, green, blue components of `color` are multiplied by `factor`.
   * `factor` will be reduced if the product of one component would become > 1.
   *
   * - Parameters:
   *   - factor: make color lighter if > 1, darker if < 1
   * - Returns: a new UIColor object with a lighter or darker color.
   */
  static func *(color: UIColor, factor: CGFloat) -> UIColor {
    var (r,g,b,a) = color.rgba()
    var m = factor
    for v in [r,g,b] {
      if v > 0.01 {
        let f = 1/v
        if f < m { m = f }
      } }
    r *= m; g *= m; b *= m;
    return UIColor(red: r, green: g, blue: b, alpha: a)
  }
  
}
