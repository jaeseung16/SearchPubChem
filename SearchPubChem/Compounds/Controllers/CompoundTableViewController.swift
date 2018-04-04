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
        self.tableView.reloadData()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let searchByNameViewController = segue.destination as? SearchByNameViewController {
            searchByNameViewController.dataController = dataController
        }
    }
    
    func setUpFetchedResultsController() {
        let fetchRequest: NSFetchRequest<Compound> = Compound.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "name", ascending: true, selector: #selector(NSString.caseInsensitiveCompare))
        
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: "firstCharacterInName", cacheName: "compounds")
        fetchedResultsController.delegate = self
        
        do {
            try fetchedResultsController.performFetch()
        } catch {
            fatalError("Compounds cannot be fetched: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Table view data source
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: tableViewCellIdentifier, for: indexPath)
        let compound = fetchedResultsController.object(at: indexPath)

        // If there is a solution made of a compound, indicate it at the end of its name
        if let count = compound.solutions?.count, let name = compound.name, count > 0 {
            cell.textLabel?.text = name + " 💧"
        } else {
            cell.textLabel?.text = compound.name
        }
        
        cell.detailTextLabel?.text = compound.formula

        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let compound = fetchedResultsController.object(at: indexPath)
        
        // Fetch the solutions containing the selected compound
        let fetchRequest: NSFetchRequest<Solution> = Solution.fetchRequest()
        let sortDescription = NSSortDescriptor(key: "created", ascending: false)
        let predicate = NSPredicate(format: "compounds CONTAINS %@", argumentArray: [compound])
        
        fetchRequest.sortDescriptors = [sortDescription]
        fetchRequest.predicate = predicate
        
        let fc = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        
        // Set up a CompoundDetailViewController
        let detailViewController = self.storyboard?.instantiateViewController(withIdentifier: detailViewControllerIdentifier) as! CompoundDetailViewController
        
        detailViewController.dataController = dataController
        detailViewController.fetchedResultsController = fc
        detailViewController.compound = compound
        
        navigationController?.pushViewController(detailViewController, animated: true)
        tableView.deselectRow(at: indexPath, animated: true)
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
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
    }
}
