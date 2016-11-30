import UIKit
import GRDBCustomSQLite

/// A subclass of Sessions that holds a search result snippet
private class SessionWithSnippet : Session {
    var snippet: String
    
    required init(row: Row) {
        snippet = row.value(named: "snippet")
        super.init(row: row)
    }
}

/// The search results controller
class SearchResultsTableViewController: UITableViewController, UISearchResultsUpdating {
    
    /// Use FetchedRecordsController to keep the list of search results
    /// synchronized with the content of the database.
    ///
    /// See https://github.com/groue/GRDB.swift#fetchedrecordscontroller
    private var sessionsController: FetchedRecordsController<SessionWithSnippet>!
    
    var selectedSession: Session? {
        return tableView
            .indexPathForSelectedRow
            .flatMap { sessionsController.record(at: $0) }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Initialize sessionsController with an empty request.
        // The request will be updated in updateSearchResults(for:).
        let request = SessionWithSnippet.none()
        sessionsController = try! FetchedRecordsController(dbQueue, request: request, compareRecordsByPrimaryKey: true)
        
        // Update table view as the content of the request changes
        // See https://github.com/groue/GRDB.swift#implementing-table-view-updates
        sessionsController.trackChanges { [unowned self] _ in
            self.tableView.reloadData()
        }
        
        // Fetch sessions and start tracking
        try! sessionsController.performFetch()
        
        // Table view autolayout
        tableView.estimatedRowHeight = 62
        tableView.rowHeight = UITableViewAutomaticDimension
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return sessionsController.sections.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sessionsController.sections[section].numberOfRecords
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SearchResultTableViewCell", for: indexPath) as! SearchResultTableViewCell
        configure(cell, at: indexPath)
        return cell
    }
    
    private func configure(_ cell: SearchResultTableViewCell, at indexPath: IndexPath) {
        let session = sessionsController.record(at: indexPath)
        cell.titleLabel.text = session.title
        cell.sessionImageURL = session.imageURL
        cell.focusesLabel.text = session.focuses
        
        // The snippet returned by SQLite wraps matched words in <b> html tags.
        // Turn those tags into an NSAttributedString.
        let snippet = session.snippet
        let font = cell.snippetLabel.font!
        let htmlSnippet = "<style>span{font-family: \"\(font.familyName)\"; font-size: \(font.pointSize)px; color: #888;} b{font-weight: normal; color: #000;}</style><span>\(snippet)</span>"
        if let data = htmlSnippet.data(using: .utf8),
            let attributedSnippet = try? NSAttributedString(
                data: data,
                options: [
                    NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType,
                    NSCharacterEncodingDocumentAttribute: String.Encoding.utf8.rawValue],
                documentAttributes: nil)
        {
            cell.snippetLabel.attributedText = attributedSnippet
        } else {
            cell.snippetLabel.text = nil
        }
    }
    
    // MARK: - Table view delegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Let the SessionsTableViewController present the session
        presentingViewController?.performSegue(withIdentifier: "ShowSession", sender: self)
    }
    
    // MARK: - UISearchResultsUpdating
    
    /// Part of the UISearchResultsUpdating protocol
    func updateSearchResults(for searchController: UISearchController) {
        // Turn the user query into a search pattern, and update
        // sessionsController's request.
        if let queryString = searchController.searchBar.text,
            let pattern = FTS5Pattern(matchingAnyTokenIn: queryString)
        {
            // Valid pattern: full-text search
            let sql = "SELECT sessions.*, SNIPPET(fullTextSessions, -1, '<b>', '</b>', '…', 15) AS snippet " +
                "FROM sessions " +
                "JOIN fullTextSessions ON fullTextSessions.rowid = sessions.rowid AND fullTextSessions MATCH ? " +
            "ORDER BY RANK"
            try! sessionsController.setRequest(sql: sql, arguments: [pattern])
        } else {
            // No pattern: empty the search results
            try! sessionsController.setRequest(SessionWithSnippet.none())
        }
    }
    
}
