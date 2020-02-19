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
  
  /// path of database
  public var dbPath: String { return Database.dbDir + "/\(modelName).sqlite" }
  
  /// managed object context of database
  public var context: NSManagedObjectContext
  
  @discardableResult  
  public init(_ modelName: String, closure: @escaping (Database)->() ) {
    self.modelName = modelName
    self.context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
    self.context.persistentStoreCoordinator = coordinator
    Dir(Database.dbDir).create()
    let dbURL = URL(fileURLWithPath: dbPath)
    let queue = DispatchQueue.global(qos: .background)
    queue.async {
      do {
        try self.coordinator.addPersistentStore(ofType: NSSQLiteStoreType, 
                  configurationName: nil, at: dbURL, options: nil)
        DispatchQueue.main.sync { closure(self) }
      }
      catch {
        self.fatal("Can't open database, possibly migration error")
      }
    }
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
