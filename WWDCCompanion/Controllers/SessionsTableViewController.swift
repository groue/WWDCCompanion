//
//  SessionsTableViewController.swift
//  WWDCCompanion
//
//  Created by Gwendal Roué on 15/10/2016.
//  Copyright © 2016 Gwendal Roué. All rights reserved.
//

import UIKit
import GRDBCustomSQLite

class SessionsTableViewController: UITableViewController {
    @IBOutlet private var downloadBarButtonItem: UIBarButtonItem!
    private var sessionsController: FetchedRecordsController<Session>!
    private var searchController: UISearchController!
    private let urlSession = URLSession(configuration: .default)

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // sessions
        let request = Session.order(Column("year").desc, Column("number").asc)
        sessionsController = FetchedRecordsController(dbQueue, request: request, compareRecordsByPrimaryKey: true)
        sessionsController.trackChanges { [unowned self] _ in
            self.tableView.reloadData()
        }
        sessionsController.performFetch()
        
        // tableview autolayout
        tableView.estimatedRowHeight = 62
        tableView.rowHeight = UITableViewAutomaticDimension
        
        // search controller
        let searchResultsController = storyboard!.instantiateViewController(withIdentifier: "SearchResultsTableViewController") as! SearchResultsTableViewController
        searchController = UISearchController(searchResultsController: searchResultsController)
        searchController.searchResultsUpdater = searchResultsController
        tableView.tableHeaderView = searchController.searchBar
        definesPresentationContext = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if sessionsController.sections.count == 0 || sessionsController.sections[0].numberOfRecords == 0 {
            download()
        }
    }
    
    // MARK: - Table view delegate
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let session = sessionsController.record(at: indexPath)
        let task = urlSession.dataTask(with: session.imageURL) { [weak self] (data, response, error) in
            if let image = data.flatMap({ UIImage(data: $0) }) {
                DispatchQueue.main.async {
                    guard let strongSelf = self else { return }
                    if let indexPath = strongSelf.sessionsController.indexPath(for: session),
                        let cell = strongSelf.tableView.cellForRow(at: indexPath) as? SessionTableViewCell
                    {
                        cell.sessionImageView.image = image
                    }
                }
            }
        }
        task.resume()
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return sessionsController.sections.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sessionsController.sections[section].numberOfRecords
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SessionTableViewCell", for: indexPath) as! SessionTableViewCell
        configure(cell: cell, at: indexPath)
        cell.sessionImageView.image = nil
        return cell
    }
    
    private func configure(cell: SessionTableViewCell, at indexPath: IndexPath) {
        let session = sessionsController.record(at: indexPath)
        cell.titleLabel.text = session.title
        var focuses: [String] = []
        if session.iOS { focuses.append("iOS") }
        if session.macOS { focuses.append("macOS") }
        if session.tvOS { focuses.append("tvOS") }
        if session.watchOS { focuses.append("watchOS") }
        cell.focusesLabel.text = focuses.joined(separator: ", ")
    }
    
    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    }
    
    // MARK: - Download
    
    @IBAction private func download() {
        downloadBarButtonItem.isEnabled = false
        let progress = WWDC2016.download { [weak self] error in
            guard let strongSelf = self else { return }
            if let error = error {
                let alert = UIAlertController(title: error.localizedDescription, message: nil, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
                strongSelf.present(alert, animated: true, completion: nil)
            }
            strongSelf.navigationItem.titleView = nil
            strongSelf.downloadBarButtonItem.isEnabled = true
        }
        let progressView = UIProgressView(frame: .zero)
        progressView.observedProgress = progress
        navigationItem.titleView = progressView
    }
}
