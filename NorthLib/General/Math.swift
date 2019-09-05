//
//  Math.swift
//
//  Created by Norbert Thies on 20.12.18.
//  Copyright © 2018 Norbert Thies. All rights reserved.
//
//  This file implements various mathematical operations.
//

import Foundation

infix operator /~ : MultiplicationPrecedence
infix operator =~ : ComparisonPrecedence

public extension FloatingPoint {
  
  /// Remainder for FloatingPoint values, e.g. 3.6 % 0.5 == 0.1
  static func %(lhs: Self, rhs: Self) -> Self {
    return lhs.truncatingRemainder(dividingBy: rhs)
  }
  
  /// Truncating division for FloatingPoint values, e.g. 3.6 /~ 0.5 == 7.0
  static func /~(lhs: Self, rhs: Self) -> Self {
    return (lhs/rhs).rounded(.towardZero)
  }
  
  /// Compares two floats with an epsilon of 2*Self.ulpOfOne
  static func =~(lhs: Self, rhs: Self) -> Bool {
    return abs(lhs-rhs) < (2*Self.ulpOfOne)
  }
  
} // extension FloatingPoint
