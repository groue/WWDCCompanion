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
    @IBOutlet var downloadBarButtonItem: UIBarButtonItem!
    var sessionsController: FetchedRecordsController<Session>!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.estimatedRowHeight = 62
        tableView.rowHeight = UITableViewAutomaticDimension
        
        let request = Session.order(Column("year").desc, Column("number").asc)
        sessionsController = FetchedRecordsController<Session>(dbQueue, request: request, compareRecordsByPrimaryKey: true)
        sessionsController.trackChanges { [unowned self] _ in
            self.tableView.reloadData()
        }
        sessionsController.performFetch()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if sessionsController.sections.count == 0 || sessionsController.sections[0].numberOfRecords == 0 {
            download()
        }
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
        return cell
    }
    
    func configure(cell: SessionTableViewCell, at indexPath: IndexPath) {
        let session = sessionsController.record(at: indexPath)
        cell.titleLabel.text = session.title
        cell.numberLabel.text = String(format:NSLocalizedString("Session %d", comment: ""), session.number)
        cell.yearLabel.text = "\(session.year)"
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    }
    
    // MARK: - Sessions
    
    @IBAction func download() {
        downloadBarButtonItem.isEnabled = false
        let progress = WWDC2016.download { [weak self] error in
            guard let strongSelf = self else { return }
            if let error = error {
                let alert = UIAlertController(title: error.localizedDescription, message: nil, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
                strongSelf.present(alert, animated: true, completion: nil)
            }
            strongSelf.tableView.tableHeaderView = nil
            strongSelf.downloadBarButtonItem.isEnabled = true
        }
        let progressView = UIProgressView(frame: .zero)
        progressView.observedProgress = progress
        tableView.tableHeaderView = progressView
    }
}
