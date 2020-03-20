//
//  Database.swift
//
//  Created by Norbert Thies on 10.04.19.
//  Copyright © 2019 Norbert Thies. All rights reserved.
//

import Foundation
import CoreData

open class Database: DoesLog {
  
  /// name of data model
  public var modelName: String
  
  /// URL of model
  public lazy var modelURL = Bundle.main.url(forResource: modelName, withExtension: "mom")!
  
  /// the model object
  public lazy var model = NSManagedObjectModel(contentsOf: modelURL)!
  
  /// the persistent store coordinator
  public lazy var coordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
  
  /// application support directory
  public static var appDir: String { return Dir.appSupportPath }
    
  /// directory where DB is stored
  public static var dbDir: String { return Database.appDir + "/database" }
  
  /// path of database with given model name
  public static func dbPath(model: String) -> String
    { return Database.dbDir + "/\(model).sqlite" }
  
  /// remove database
  public static func dbRemove(model: String) { File(Database.dbPath(model: model)).remove() }

  /// path of database
  public var dbPath: String { return Database.dbPath(model: modelName) }
  
  /// managed object context of database
  public var context: NSManagedObjectContext?
  
  /// create/open database once
  private func openOnce(closure: @escaping (Error?)->()) {
    let model = self.modelName
    self.context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
    self.context?.persistentStoreCoordinator = coordinator
    let path = Database.dbPath(model: model)
    Dir(Database.dbDir).create()
    let dbURL = URL(fileURLWithPath: path)
    let queue = DispatchQueue.global(qos: .userInteractive)
    queue.async { [weak self] in
      guard let self = self else { return }
      do {
        try self.coordinator.addPersistentStore(ofType: NSSQLiteStoreType, 
                  configurationName: nil, at: dbURL, options: nil)
        DispatchQueue.main.sync { closure(nil) }
      }
      catch let err {
        closure(self.error(err))
      }
    }
  }

  public func open(closure: @escaping (Error?)->()) {
    self.openOnce { [weak self] err in
      guard let self = self else { return }
      if err != nil {
        Database.dbRemove(model: self.modelName)
        self.openOnce { [weak self] err in
          guard let self = self else { return }
          if err != nil { 
            closure(self.error("Can't create create database"))
          }
          else { closure(nil) }
        }
      }
      else { closure(nil) }
    }
  }
  
  public init(_ modelName: String) {
    self.modelName = modelName
  }
  
  public func save(_ context: NSManagedObjectContext? = nil) {
    let ctx = (context != nil) ? context : self.context
    if ctx!.hasChanges { try! ctx!.save() }
  }
  
  public func inBackground(_ closure: @escaping (NSManagedObjectContext)->()) {
    let ctx = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
    ctx.persistentStoreCoordinator = self.coordinator
    ctx.perform {
      closure(ctx)
      self.save(ctx)
    }
  }
  
} // class Database
