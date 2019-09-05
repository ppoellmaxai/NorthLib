//
//  DataExtensions.swift
//
//  Created by Norbert Thies on 05.09.19.
//  Copyright © 2019 Norbert Thies. All rights reserved.
//

import Foundation

public extension Data {
  
  /// Returns the md5 sum as a String of hex digits.
  var md5: String {
    let d: NSData = self as NSData
    let cstr = hash_md5( d.bytes, d.count)
    let str = String(utf8String: cstr!)
    free(cstr)
    return str!
  }

  /// Returns the sha1 sum as a String of hex digits.
  var sha1: String {
    let d: NSData = self as NSData
    let cstr = hash_sha1( d.bytes, d.count)
    let str = String(utf8String: cstr!)
    free(cstr)
    return str!
  }
  
  /// Returns the sha256 sum as a String of hex digits.
  var sha256: String {
    let d: NSData = self as NSData
    let cstr = hash_sha256( d.bytes, d.count)
    let str = String(utf8String: cstr!)
    free(cstr)
    return str!
  }
  
} // extension Data
