//
//  SearchResultsTableViewController.swift
//  WWDCCompanion
//
//  Created by Gwendal Roué on 15/10/2016.
//  Copyright © 2016 Gwendal Roué. All rights reserved.
//

import UIKit
import GRDBCustomSQLite

class SessionWithSnippet : Session {
    var snippet: String
    
    required init(row: Row) {
        self.snippet = row.value(named: "snippet")
        super.init(row: row)
    }
}

class SearchResultsTableViewController: UITableViewController {
    private var sessionsController: FetchedRecordsController<SessionWithSnippet>!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // sessions
        let request = SessionWithSnippet.filter(false)
        sessionsController = FetchedRecordsController(dbQueue, request: request, compareRecordsByPrimaryKey: true)
        sessionsController.trackChanges { [unowned self] _ in
            self.tableView.reloadData()
        }
        sessionsController.performFetch()
        
        // tableview autolayout
        tableView.estimatedRowHeight = 62
        tableView.rowHeight = UITableViewAutomaticDimension
    }
    
    func setQueryString(_ string: String?) {
        guard let pattern = string.flatMap({ FTS5Pattern(matchingAnyTokenIn: $0) }) else {
            sessionsController.setRequest(SessionWithSnippet.filter(false))
            return
        }
        
        sessionsController.setRequest(sql:
            "SELECT sessions.*, SNIPPET(fullTextSessions, -1, '<b>', '</b>', '…', 15) AS snippet " +
            "FROM sessions, fullTextSessions " +
            "WHERE fullTextSessions.rowid = sessions.rowid AND fullTextSessions MATCH ? " +
            "ORDER BY RANK", arguments: [pattern])
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
        configure(cell: cell, at: indexPath)
        return cell
    }
    
    private func configure(cell: SearchResultTableViewCell, at indexPath: IndexPath) {
        let session = sessionsController.record(at: indexPath)
        cell.titleLabel.text = session.title
        cell.numberLabel.text = String(format:NSLocalizedString("Session %d", comment: ""), session.number)
        cell.yearLabel.text = "\(session.year)"
        
        let font = cell.snippetLabel.font ?? UIFont.systemFont(ofSize: 17)
        let htmlSnippet = "<style>span{font-family: \"\(font.familyName)\"; font-size: \(font.pointSize)px; color: #888;} b{font-weight: normal; color: #000;}</style><span>\(session.snippet)</span>"
        if let data = htmlSnippet.data(using: .utf8),
            let attributedSnippet = try? NSAttributedString(
                data: data,
                options: [
                    NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType,
                    NSCharacterEncodingDocumentAttribute: String.Encoding.utf8.rawValue],
                documentAttributes: nil)
        {
            cell.snippetLabel.attributedText = attributedSnippet
        }
    }
}

extension SearchResultsTableViewController : UISearchResultsUpdating {
    
    func updateSearchResults(for searchController: UISearchController) {
        setQueryString(searchController.searchBar.text)
    }
}
