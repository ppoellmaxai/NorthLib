//
//  Keychain.swift
//
//  Created by Norbert Thies on 24.02.20.
//  Copyright © 2020 Norbert Thies. All rights reserved.
//

import Foundation

/** 
 A simple wrapper around Apples's keychain functions
 
 This class allows you to access values in Apple's keychain as a subscript of 
 the singleton keychain object. Eg.:
 ````
   let kc = Keychain.singleton // access singleton Keychain object
   kc["password"] = "secret"   // store String "secret" under key "password"
   print(kc["password"])       // access the String stored under key "password"
   kc["password"] = nil        // delete the String stored under key "password"   
 ````
 TODO: Implement sharing of secrets across all devices an Apple-ID is logged into,
       currently only the device having stored the key/value pairs may access them
*/
open class Keychain: DoesLog {
  
  public static var singleton: Keychain = Keychain()
  private init() {}
  
  // delete key/value from keychain
  private func delete(key: String) {
    let query = [
      kSecClass as String              : kSecClassGenericPassword as String,
      kSecAttrSynchronizable as String : kCFBooleanTrue!,
      kSecAttrAccount as String        : key ] as [String : Any]
    SecItemDelete(query as CFDictionary)
  }
  
  // get value from keychain
  private func get(key: String) -> String? {
    let query = [
      kSecClass as String              : kSecClassGenericPassword,
      kSecAttrSynchronizable as String : kCFBooleanTrue!,
      kSecAttrAccount as String        : key,
      kSecReturnData as String         : kCFBooleanTrue!,
      kSecMatchLimit as String         : kSecMatchLimitOne ] as [String : Any]    
    var ret: AnyObject?
    let status: OSStatus = SecItemCopyMatching(query as CFDictionary, &ret)
    guard status == errSecSuccess else { return nil }
    if let data = ret as? Data { return String(data: data, encoding: .utf8) }
    return nil
  }
  
  // put value into keychain
  private func set(key: String, value: String) {
    let data = value.data(using: .utf8)!
    let query = [
      kSecClass as String              : kSecClassGenericPassword as String,
      kSecAttrSynchronizable as String : kCFBooleanTrue!,
      kSecAttrAccount as String        : key,
      kSecValueData as String          : data ] as [String : Any]
    let status = SecItemAdd(query as CFDictionary, nil)
    if status != errSecSuccess { 
      if #available(iOS 11.3, *) {
        if let str = SecCopyErrorMessageString(status, nil) { error("\(str)") }
      } else {
        error("Can't store value into keychain")
      }
    }
  }
  
  /// obj[key] - returns the value associated with key
  /// obj[key] = value - sets the associated value
  /// obj[key] = nil - removes the key/value pair from Keychain
  open subscript(_ key: String) -> String? {
    get { return get(key: key) }
    set(val) {
      delete(key: key)
      if let v = val { set(key: key, value: v) }
    }
  }

} // Keychain
