import Foundation
import UIKit
import CoreData

class EventAlliancesContainerViewController: ContainerViewController {

    private(set) var event: Event
    private let myTBA: MyTBA

    private var alliancesViewController: EventAlliancesViewController!

    // MARK: - Init

    init(event: Event, myTBA: MyTBA, persistentContainer: NSPersistentContainer, tbaKit: TBAKit, userDefaults: UserDefaults) {
        self.event = event
        self.myTBA = myTBA

        let alliancesViewController = EventAlliancesViewController(event: event, persistentContainer: persistentContainer, tbaKit: tbaKit, userDefaults: userDefaults)

        super.init(viewControllers: [alliancesViewController],
                   navigationTitle: "Alliances",
                   navigationSubtitle: "@ \(event.friendlyNameWithYear)",
                   persistentContainer: persistentContainer,
                   tbaKit: tbaKit,
                   userDefaults: userDefaults)

        alliancesViewController.delegate = self
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

extension EventAlliancesContainerViewController: EventAlliancesViewControllerDelegate {

    func teamKeySelected(_ teamKey: TeamKey) {
        let teamAtEventViewController = TeamAtEventViewController(teamKey: teamKey, event: self.event, myTBA: myTBA, persistentContainer: persistentContainer, tbaKit: tbaKit, userDefaults: userDefaults)
        self.navigationController?.pushViewController(teamAtEventViewController, animated: true)
    }

}

protocol EventAlliancesViewControllerDelegate: AnyObject {
    func teamKeySelected(_ teamKey: TeamKey)
}

private class EventAlliancesViewController: TBATableViewController {

    private let event: Event

    weak var delegate: EventAlliancesViewControllerDelegate?
    private var dataSource: TableViewDataSource<EventAlliance, EventAlliancesViewController>!

    // MARK: - Init

    init(event: Event, persistentContainer: NSPersistentContainer, tbaKit: TBAKit, userDefaults: UserDefaults) {
        self.event = event

        super.init(persistentContainer: persistentContainer, tbaKit: tbaKit, userDefaults: userDefaults)

        setupDataSource()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        // Override automatic rowHeight - these will be smaller than 44 by default, and we want to open them up
        tableView.rowHeight = 44
    }

    // MARK: Table View Data Source

    private func setupDataSource() {
        let fetchRequest: NSFetchRequest<EventAlliance> = EventAlliance.fetchRequest()
        // This seems like a poor sort descriptor... since this could be nil
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        setupFetchRequest(fetchRequest)

        let frc = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: persistentContainer.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        dataSource = TableViewDataSource(fetchedResultsController: frc, delegate: self)
    }

    private func updateDataSource() {
        dataSource.reconfigureFetchRequest(setupFetchRequest(_:))
    }

    private func setupFetchRequest(_ request: NSFetchRequest<EventAlliance>) {
        request.predicate = NSPredicate(format: "event == %@", event)
    }

}

extension EventAlliancesViewController: TableViewDataSourceDelegate {

    func configure(_ cell: EventAllianceTableViewCell, for object: EventAlliance, at indexPath: IndexPath) {
        cell.viewModel = EventAllianceCellViewModel(alliance: object, allianceNumber: indexPath.row + 1)
        cell.teamKeySelected = { [unowned self] (teamKey) in
            let teamKey = TeamKey.insert(withKey: teamKey, in: self.persistentContainer.viewContext)
            self.delegate?.teamKeySelected(teamKey)
        }
    }

}

extension EventAlliancesViewController: Refreshable {

    var refreshKey: String? {
        return "\(event.key!)_alliances"
    }

    var automaticRefreshInterval: DateComponents? {
        return nil
    }

    var automaticRefreshEndDate: Date? {
        return nil
    }

    var isDataSourceEmpty: Bool {
        if let alliances = dataSource.fetchedResultsController.fetchedObjects, alliances.isEmpty {
            return true
        }
        return false
    }

    @objc func refresh() {
        removeNoDataView()

        var request: URLSessionDataTask?
        request = tbaKit.fetchEventAlliances(key: event.key!, completion: { (alliances, error) in
            let context = self.persistentContainer.newBackgroundContext()
            context.performChangesAndWait({
                if let alliances = alliances {
                    let event = context.object(with: self.event.objectID) as! Event
                    event.insert(alliances)
                }
            }, saved: {
                self.markTBARefreshSuccessful(self.tbaKit, request: request!)
            })
            self.removeRequest(request: request!)
        })
        self.addRequest(request: request!)
    }

}

extension EventAlliancesViewController: Stateful {

    var noDataText: String {
        return "No alliances for event"
    }

}
