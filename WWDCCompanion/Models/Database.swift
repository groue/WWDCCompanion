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
    
    migrator.registerMigration("createWWDCSessions") { db in
        
        try db.create(table: "sessions") { t in
            t.primaryKey(["year", "number"])
            t.column("year", .integer).notNull()
            t.column("number", .integer).notNull()
            t.column("collection", .text).notNull().check { length($0) > 0 }
            t.column("title", .text).notNull().check { length($0) > 0 }
            t.column("description", .text).notNull().check { length($0) > 0 }
            t.column("transcript", .text).notNull().check { length($0) > 0 }
            t.column("iOS", .boolean).notNull()
            t.column("macOS", .boolean).notNull()
            t.column("watchOS", .boolean).notNull()
            t.column("tvOS", .boolean).notNull()
            t.column("sessionURL", .text).notNull()
            t.column("videoURL", .text).notNull()
            t.column("presentationURL", .text)
        }
        
        try db.create(virtualTable: "fullTextSessions", using: FTS5()) { t in
            t.content = "sessions"
            t.column("title")
            t.column("transcript")
            t.column("description")
        }
        
        // Triggers to keep the FTS index up to date.
        // See https://sqlite.org/fts5.html#external_content_tables
        try db.execute(
            "CREATE TRIGGER sessions_ai AFTER INSERT ON sessions BEGIN " +
                "INSERT INTO fullTextSessions(rowid, title, transcript, description) VALUES (new.rowid, new.title, new.transcript, new.description); " +
                "END; " +
                "CREATE TRIGGER sessions_ad AFTER DELETE ON sessions BEGIN " +
                "INSERT INTO fullTextSessions(fullTextSessions, rowid, title, transcript, description) VALUES('delete', old.rowid, old.title, old.transcript, old.description); " +
                "END; " +
                "CREATE TRIGGER sessions_au AFTER UPDATE ON sessions BEGIN " +
                "INSERT INTO fullTextSessions(fullTextSessions, rowid, title, transcript, description) VALUES('delete', old.rowid, old.title, old.transcript, old.description); " +
                "INSERT INTO fullTextSessions(rowid, title, transcript, description) VALUES (new.rowid, new.title, new.transcript, new.description); " +
            "END;")
    }
    
    try migrator.migrate(dbQueue)
}
