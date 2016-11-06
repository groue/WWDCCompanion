import UIKit
import GRDBCustomSQLite

class SessionsTableViewController: UITableViewController {
    @IBOutlet private var downloadBarButtonItem: UIBarButtonItem!
    @IBOutlet private var downloadingView: UIView!
    @IBOutlet private var downloadProgressView: UIProgressView!
    private var searchController: UISearchController!
    
    /// Use FetchedRecordsController to keep the list of sessions
    /// synchronized with the content of the database.
    ///
    /// See https://github.com/groue/GRDB.swift#fetchedrecordscontroller
    private var sessionsController: FetchedRecordsController<Session>!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Initialize sessionsController
        let request = Session.order(Column("year").desc, Column("number").asc)
        sessionsController = FetchedRecordsController(dbQueue, request: request, compareRecordsByPrimaryKey: true)
        
        // Update table view as the content of the request changes
        // See https://github.com/groue/GRDB.swift#implementing-table-view-updates
        sessionsController.trackChanges(
            recordsWillChange: { [unowned self] _ in
                self.tableView.beginUpdates()
            },
            tableViewEvent: { [unowned self] (controller, record, event) in
                switch event {
                case .insertion(let indexPath):
                    self.tableView.insertRows(at: [indexPath], with: .fade)
                case .deletion(let indexPath):
                    self.tableView.deleteRows(at: [indexPath], with: .fade)
                case .update(let indexPath, _):
                    if let cell = self.tableView.cellForRow(at: indexPath) as? SessionTableViewCell {
                        self.configure(cell, at: indexPath)
                    }
                case .move(let indexPath, let newIndexPath, _):
                    self.tableView.deleteRows(at: [indexPath], with: .fade)
                    self.tableView.insertRows(at: [newIndexPath], with: .fade)
                }
            },
            recordsDidChange: { [unowned self] _ in
                self.tableView.endUpdates()
        })
        
        // Fetch sessions and start tracking
        sessionsController.performFetch()
        
        // Table view autolayout
        tableView.estimatedRowHeight = 62
        tableView.rowHeight = UITableViewAutomaticDimension
        
        // Search controller
        let searchResultsController = storyboard!.instantiateViewController(withIdentifier: "SearchResultsTableViewController") as! SearchResultsTableViewController
        searchController = UISearchController(searchResultsController: searchResultsController)
        searchController.searchResultsUpdater = searchResultsController
        tableView.tableHeaderView = searchController.searchBar
        definesPresentationContext = true
        
        // Title and back button
        navigationItem.title = NSLocalizedString("WWDC Companion", comment: "")
        navigationItem.backBarButtonItem = UIBarButtonItem(title: NSLocalizedString("Sessions", comment: ""), style: .plain, target: nil, action: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Download sessions if needed
        if sessionsController.sections[0].numberOfRecords == 0 {
            download()
        }
        
        // This is necessary for automatic row deselection in the search results
        if searchController.isActive {
            searchController.searchResultsController?.viewWillAppear(animated)
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
        configure(cell, at: indexPath)
        return cell
    }
    
    private func configure(_ cell: SessionTableViewCell, at indexPath: IndexPath) {
        let session = sessionsController.record(at: indexPath)
        cell.titleLabel.text = session.title
        cell.sessionImageURL = session.imageURL
        cell.focusesLabel.text = session.focuses
    }
    
    // MARK: - Table view delegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "ShowSession", sender: self)
    }
    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowSession" {
            // Pushed session depends on the sender: self or the search results
            let session: Session?
            switch sender {
            case let vc as SearchResultsTableViewController:
                session = vc.selectedSession
            default:
                session = tableView
                    .indexPathForSelectedRow
                    .flatMap { sessionsController.record(at: $0) }
            }
            (segue.destination as! SessionViewController).session = session
        }
    }
    
    // MARK: - Download
    
    @IBAction private func download() {
        let progress = WWDC2016.download { [weak self] error in
            guard let strongSelf = self else { return }
            
            if let error = error {
                let alert = UIAlertController(title: error.localizedDescription, message: nil, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
                strongSelf.present(alert, animated: true, completion: nil)
            }
            
            // Update UI
            strongSelf.navigationItem.titleView = nil
            strongSelf.downloadBarButtonItem.isEnabled = true
        }
        
        // Update UI
        let navigationBar = navigationController!.navigationBar
        downloadBarButtonItem.isEnabled = false
        downloadProgressView.observedProgress = progress
        downloadingView.frame.size = downloadingView.systemLayoutSizeFitting(UILayoutFittingCompressedSize)
        downloadingView.frame.size.width = navigationBar.bounds.width / 2
        navigationItem.titleView = downloadingView
    }
}
