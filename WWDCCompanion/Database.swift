//
//  Database.swift
//  WWDCCompanion
//
//  Created by Gwendal Roué on 14/10/2016.
//  Copyright © 2016 Gwendal Roué. All rights reserved.
//

import GRDBCustomSQLite
import UIKit

var dbQueue: DatabaseQueue!

func setupDatabase(_ application: UIApplication) throws {
    
    // Connect to the database
    // See https://github.com/groue/GRDB.swift/#database-connections
    
    let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first! as NSString
    let databasePath = documentsPath.appendingPathComponent("db.sqlite")
    dbQueue = try DatabaseQueue(path: databasePath)
    
    
    // Be a nice iOS citizen, and don't consume too much memory
    // See https://github.com/groue/GRDB.swift/#memory-management
    
    dbQueue.setupMemoryManagement(in: application)
    
    
    // Use DatabaseMigrator to setup the database
    // See https://github.com/groue/GRDB.swift/#migrations
    
    var migrator = DatabaseMigrator()
    
    migrator.registerMigration("createPersons") { db in
        
        try db.create(table: "session") { t in
            t.column("id", .integer).primaryKey()
            t.column("year", .integer).notNull()
            t.column("number", .integer).notNull()
            t.column("title", .text).notNull().check { length($0) > 0 }
            t.column("topic", .text).notNull().check { length($0) > 0 }
            t.column("iOS", .boolean).notNull()
            t.column("macOS", .boolean).notNull()
            t.column("watchOS", .boolean).notNull()
            t.column("tvOS", .boolean).notNull()
            t.column("transcript", .text)
            t.column("url", .text)
            t.column("hdVideoURL", .text)
            t.column("sdVideoURL", .text)
            t.column("presentationURL", .text)
            
            t.uniqueKey(["year", "number"])
        }
    }
    
    try migrator.migrate(dbQueue)
}
