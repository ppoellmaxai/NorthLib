//
//  ArrayExtensions.swift
//
//  Created by Norbert Thies on 12.12.18.
//  Copyright © 2018 Norbert Thies. All rights reserved.
//

import Foundation

extension Array {
  
  /// appends one Element to an array
  @discardableResult
  static func +=(lhs: inout Array<Element>, rhs: Element) -> Array<Element> {
    lhs.append(rhs)
    return lhs
  }

  /// appends an array to an array
  @discardableResult
  static func +=(lhs: inout Array<Element>, rhs: Array<Element>) -> Array<Element> {
    lhs.append(contentsOf: rhs)
    return lhs
  }
  
}
