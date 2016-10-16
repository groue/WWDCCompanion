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
            t.column("collection", .text).notNull()
            t.column("title", .text).notNull()
            t.column("description", .text).notNull()
            t.column("transcript", .text).notNull()
            t.column("iOS", .boolean).notNull()
            t.column("macOS", .boolean).notNull()
            t.column("tvOS", .boolean).notNull()
            t.column("watchOS", .boolean).notNull()
            t.column("sessionURL", .text).notNull()
            t.column("imageURL", .text).notNull()
            t.column("videoURL", .text).notNull()
            t.column("presentationURL", .text)
        }
        
        try db.create(virtualTable: "fullTextSessions", using: FTS5()) { t in
            // Porter tokenizer provides English stemming
            t.tokenizer = .porter()
            
            // Index the content of the sessions table
            // See https://github.com/groue/GRDB.swift#external-content-full-text-tables
            t.synchronize(withTable: "sessions")
            
            // The indexed columns
            t.column("title")
            t.column("transcript")
            t.column("description")
        }
    }
    
    try migrator.migrate(dbQueue)
}
