//
//  Directory.swift
//
//  Created by Norbert Thies on 21.06.17.
//  Copyright © 2017 Norbert Thies. All rights reserved.
//

import Foundation

/// A Directory class models a directory in the local file system
open class Directory: NSObject, DoesLog {
  
  public static var fm: FileManager { return FileManager.default }
  var path: String
  
  /// Returns true, if the directory at the given path 'dir' is existent.
  public static func isa( _ dir: String ) -> Bool {
    var isDir: ObjCBool = false
    let exists = fm.fileExists(atPath: dir, isDirectory: &isDir)
    return exists && isDir.boolValue
  }
  
  /// Create directory at given path
  public static func create(_ path: String) throws {
    guard let _ = try? fm.createDirectory(atPath: path, withIntermediateDirectories: true)
      else { throw Log.error("Can't create directory: \(path)") }
  }
  
  /// Open the directory at the path 'dir'. If 'dir' is not existing or can't be 
  /// opened, the initializer fails (ie returns nil)
  public init?( _ dir: String? ) {
    if let dir = dir, Directory.isa(dir) {
      self.path = dir
    }
    else { return nil }
  }
  
  /// returns an array of the contents of the directory (without preceeding path)
  public func content() -> [String] {
    do {
      return try Directory.fm.contentsOfDirectory(atPath: path)
    }
    catch { return [] }
  }
  
  /// scans for files in the passed directory and returns an array of absolute
  /// pathnames. select is an optional predicate to use.
  public func scan( filter:((String)->Bool)? = nil ) -> [String] {
    var ret: [String] = []
    let content = self.content()
    for f in content {
      let path = "\(self.path)/\(f)"
      if let sel = filter { if sel(path) { ret.append(path) } }
      else { ret.append(path) }
    }
    return ret
  }

  /// scanExtensions searches for files in a given directory beeing matched
  /// by any one in a list of given extensions.
  public func scanExtensions( _ ext: [String] ) -> [String] {
    let lext = ext.map { $0.lowercased() }
    return scan { (fn: String) -> Bool in
      let fe = (fn.lowercased() as NSString).pathExtension
      if let _ = lext.firstIndex(of: fe) { return true }
      return false
    }
  }
  
  /// scanExtensions searches for files in a given directory beeing matched
  /// by any one in a list of given extensions.
  public func scanExtensions( _ ext: String... ) -> [String] {
    return scanExtensions(ext)
  }
  
  /// returns the path to the document directory
  public static func documentsPath() -> String? {
    if let url =  try? fm.url(for: .documentDirectory, in: .userDomainMask,
                              appropriateFor: nil, create: true) {
      return url.standardizedFileURL.path
    }
    return nil
  }
  
  /// returns the path to the Inbox directory
  public static func inboxPath() -> String? {
    if let docs =  Directory.documentsPath() {
      return "\(docs)/Inbox"
    }
    return nil
  }
  
  /// returns the path to the app support directory
  public static func appSupportPath() -> String? {
    if let dir = try? FileManager.default.url(for: .applicationSupportDirectory, 
                                              in: .userDomainMask, appropriateFor: nil, create: true) {
      return dir.path
    }
    else { return nil }
  }
  
  /// returns the document directory
  public static func documents() -> Directory? {
    do { return Directory(Directory.documentsPath()) }
  }

  /// returns the Inbox directory
  public static func inbox() -> Directory? {
    do { return Directory(Directory.inboxPath()) }
  }
  
  /// returns a list of files in the inbox
  public static func scanInbox( _ ext: String ) -> [String] {
    if let d = Directory.inbox() {
      return d.scanExtensions(ext)
    }
    else { return [] }
  }
  
} // Directory
