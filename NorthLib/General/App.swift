//
//  App.swift
//
//  Created by Norbert Thies on 22.06.18.
//  Copyright © 2018 Norbert Thies. All rights reserved.
//

import UIKit

/// App description from Apple's App Store
open class StoreApp {
  
  public enum AppError: Error {
    case appStoreLookupFailed
  }
  
  /// Bundle identifier of app
  public var bundleIdentifier: String
  
  /// App store info
  public var info: [String:Any] = [:]
  
  /// App store version
  public var version: Version { return Version(info["version"] as! String) }
  
  /// URL of app store entry
  public var url: URL { return URL(string: info["trackViewUrl"] as! String)! }

  /// Minimal OS version of app in store
  public var minOsVersion: Version { return Version(info["minimumOsVersion"] as! String) }
  
  /// Release notes of last app update in store
  public var releaseNotes: String { return info["releaseNotes"] as! String }
  
  /// Lookup app store info of app with given bundle identifier
  public static func lookup(_ id: String) throws -> [String:Any] {
    let surl = "http://itunes.apple.com/lookup?bundleId=\(id)"
    let url = URL(string: surl)!
    do {
      let data = try Data(contentsOf: url)
      let json = try JSONSerialization.jsonObject(with: data,
          options: [.allowFragments]) as! [String: Any]
      if let result = (json["results"] as? [Any])?.first as? [String: Any] {
        return result
      }
      else { throw AppError.appStoreLookupFailed }
    }
    catch {
      throw AppError.appStoreLookupFailed
    }
  }
  
  /// Open app store with app description
  public func openInAppStore() {
    UIApplication.shared.open(url)
  }
  
  /// Retrieve app store data of app with given bundle identifier
  public init( _ bundleIdentifier: String ) throws {
    self.bundleIdentifier = bundleIdentifier
    self.info = try StoreApp.lookup(bundleIdentifier)
  }
  
} // class StoreApp

/// Currently running app
open class App {
  
  /// Info dictionary of currently running app
  public static let info = Bundle.main.infoDictionary!
  
  /// The current device
  public static let device = UIDevice.current
  
  /// Version string of currently running app
  public static var bundleVersion: String {
    return info["CFBundleShortVersionString"] as! String
  }
  
  /// Name of currently running app
  public static var name: String {
    return info["CFBundleDisplayName"] as! String
  }

  /// Build number of currently running app
  public static var buildNumber: String {
    return info["CFBundleVersion"] as! String
  }
  
  /// Is this release a beta version (last two digits of buildNumber < 50)
  /// or has it been defined as beta version
  public static var isBeta = {
    return Int(buildNumber.suffix(2))! < 50
  }()
  
  /// Bundle identifier of currently running app
  public static var bundleIdentifier: String {
    return info["CFBundleIdentifier"] as! String
  }
  
  /// Version of running app
  public static var version = Version(App.bundleVersion)
  
  /// AppStore app information
  public static var store: StoreApp? = {
    do { return try StoreApp(App.bundleIdentifier) }
    catch { return nil }
  }()
  
  /// Version of running OS
  public static var osVersion = Version(device.systemVersion)
  
  /// Returns true if a newer version is available at the app store
  public static func isUpdatable() -> Bool {
    if let sversion = store?.version {
      return (version < sversion) && (osVersion >= store!.minOsVersion)
    }
    else { return false }
  }
  
  /// Calls the passed closure if an update is avalable at the app store
  public static func ifUpdatable(closure: @escaping ()->()) {
    DispatchQueue.global().async {
      if App.isUpdatable() {
        DispatchQueue.main.async { closure() }
      }
    }
  }
  
  public init() {}
  
} // class App
