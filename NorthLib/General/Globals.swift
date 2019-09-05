//
//  Globals.swift
//
//  Created by Norbert Thies on 20.12.18.
//  Copyright © 2018 Norbert Thies. All rights reserved.
//
//  This file implements various global functions.
//

import Foundation

/// delays execution of a closure for a number of seconds
public func delay(seconds: Double, completion:@escaping ()->()) {
  DispatchQueue.main.asyncAfter(deadline: .now() + seconds) { completion() }
}

/// returns the type name of an object as String
func typeName<T>(_ obj: T) -> String { return "\(type(of:obj))" }
