//
//  ChemicalTableViewController.swift
//  SearchPubChem
//
//  Created by Jae Seung Lee on 1/15/18.
//  Copyright © 2018 Jae Seung Lee. All rights reserved.
//

import UIKit
import CoreData

class CompoundTableViewController: UITableViewController {
    // MARK:- Properties
    // Constants
    let detailViewControllerIdentifier = "CompoundDetailViewController"
    let tableViewCellIdentifier = "ChemicalTableViewCell"
    
    // Variables
    var compounds = [Compound]()
    var dataController: DataController!
    var fetchedResultsController: NSFetchedResultsController<Compound>!
    
    // MARK:- Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpFetchedResultsController()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        tableView.reloadData()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let searchByNameViewController = segue.destination as? SearchByNameViewController {
            searchByNameViewController.dataController = dataController
        }
    }
    
    func setUpFetchedResultsController() {
        let fetchRequest: NSFetchRequest<Compound> = setupFetchRequest()
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: "firstCharacterInName", cacheName: "compounds")
        fetchedResultsController.delegate = self
        
        do {
            try fetchedResultsController.performFetch()
        } catch {
            fatalError("Compounds cannot be fetched: \(error.localizedDescription)")
        }
    }
    
    func setupFetchRequest() -> NSFetchRequest<Compound> {
        let fetchRequest: NSFetchRequest<Compound> = Compound.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "name", ascending: true, selector: #selector(NSString.caseInsensitiveCompare))
        
        fetchRequest.sortDescriptors = [sortDescriptor]
        return fetchRequest
    }
    
    // MARK: - Table view data source
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let compound = fetchedResultsController.object(at: indexPath)
        
        let cell = tableView.dequeueReusableCell(withIdentifier: tableViewCellIdentifier, for: indexPath)
        cell.textLabel?.text = cellTextLabel(for: compound)
        cell.detailTextLabel?.text = compound.formula
        return cell
    }
    
    func cellTextLabel(for compound: Compound) -> String? {
        var textLabel: String?
        if let count = compound.solutions?.count, let name = compound.name, count > 0 {
            textLabel = name + " 💧"
        } else {
            textLabel = compound.name
        }
        return textLabel
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let compound = fetchedResultsController.object(at: indexPath)
        let detailViewController = setupCompoundDetailViewController(for: compound)
        navigationController?.pushViewController(detailViewController, animated: true)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func setupCompoundDetailViewController(for compound: Compound) -> CompoundDetailViewController {
        let fetchRequest = buildSolutionFetchRequest(for: compound)
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        return setupCompoundDetailViewController(for: compound, with: fetchedResultsController)
    }
    
    func buildSolutionFetchRequest(for compound: Compound) -> NSFetchRequest<Solution> {
        let sortDescription = NSSortDescriptor(key: "created", ascending: false)
        let predicate = NSPredicate(format: "compounds CONTAINS %@", argumentArray: [compound])
        
        let fetchRequest: NSFetchRequest<Solution> = Solution.fetchRequest()
        fetchRequest.sortDescriptors = [sortDescription]
        fetchRequest.predicate = predicate
        return fetchRequest
    }
    
    func setupCompoundDetailViewController(for compound: Compound, with fetchedResultsController: NSFetchedResultsController<Solution>) -> CompoundDetailViewController {
        let detailViewController = storyboard?.instantiateViewController(withIdentifier: detailViewControllerIdentifier) as! CompoundDetailViewController
        detailViewController.dataController = dataController
        detailViewController.fetchedResultsController = fetchedResultsController
        detailViewController.compound = compound
        return detailViewController
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return fetchedResultsController.sections?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fetchedResultsController.sections?[section].numberOfObjects ?? 0
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return fetchedResultsController.sections?[section].name ?? nil
    }
    
    override func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        return fetchedResultsController.section(forSectionIndexTitle: title, at: index)
    }
    
    override func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        return fetchedResultsController.sectionIndexTitles 
    }
}

// MARK: - NSFetchedResultsControllerDelegate
extension CompoundTableViewController: NSFetchedResultsControllerDelegate {
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        let set = IndexSet(integer: sectionIndex)
        
        switch (type) {
        case .insert:
            tableView.insertSections(set, with: .fade)
        case .delete:
            tableView.deleteSections(set, with: .fade)
        default:
            break
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch(type) {
        case .insert:
            tableView.insertRows(at: [newIndexPath!], with: .fade)
        case .delete:
            tableView.deleteRows(at: [indexPath!], with: .fade)
        case .update:
            tableView.reloadRows(at: [indexPath!], with: .fade)
        case .move:
            tableView.deleteRows(at: [indexPath!], with: .fade)
            tableView.insertRows(at: [newIndexPath!], with: .fade)
        @unknown default:
            fatalError("Unkown change type: \(type)")
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
    }
}
