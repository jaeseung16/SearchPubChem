//
//  SolutionTableViewController.swift
//  SearchPubChem
//
//  Created by Jae Seung Lee on 2/6/18.
//  Copyright © 2018 Jae Seung Lee. All rights reserved.
//

import UIKit
import CoreData
import SwiftUI

class SolutionTableViewController: UITableViewController {
    // MARK: - Properties
    // Constants
    private let detailvViewControllerIdentifier = "SolutionDetailViewController"
    private let tableViewCellIdentifier = "SolutionTableViewCell"
    
    // Variables
    var solutions = [Solution]()
    
    var dataController: DataController!
    var fetchedResultsController: NSFetchedResultsController<Solution>!
    
    // MARK: - Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpFetchedResultsController()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        tableView.reloadData()
    }

    private func setUpFetchedResultsController() {
        let sortDescriptor = NSSortDescriptor(key: "created", ascending: false)
        
        let fetchRequest: NSFetchRequest<Solution> = Solution.fetchRequest()
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: "solutions")
        fetchedResultsController.delegate = self
        
        do {
            try fetchedResultsController.performFetch()
        } catch {
            fatalError("Solutions cannot be fetched: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Table View Data Source
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let solution = fetchedResultsController.object(at: indexPath)
        let cell = tableView.dequeueReusableCell(withIdentifier: tableViewCellIdentifier, for: indexPath) as! SolutionTableViewCell
        cell.populate(with: solution)
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let solution = fetchedResultsController.object(at: indexPath)
        let detailViewController = UIHostingController(rootView: SolutionDetailView(solution: solution))
        navigationController?.pushViewController(detailViewController, animated: true)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    private func setupDetailViewController(for solution: Solution) -> SolutionDetailViewController {
        let detailViewController = storyboard?.instantiateViewController(withIdentifier: detailvViewControllerIdentifier) as! SolutionDetailViewController
        detailViewController.solution = solution
        detailViewController.delegate = self
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

    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let makeSolutionViewController = segue.destination as? MakeSolutionViewController {
            makeSolutionViewController.dataController = dataController
        }
    }
}

// MARK: - SolutionDetailViewControllerDelegate
extension SolutionTableViewController: SolutionDetailViewControllerDelegate {
    func remove(solution: Solution) {
        dataController.viewContext.delete(solution)
        
        do {
            try dataController.viewContext.save()
            NSLog("Saved in SolutionTableViewController.remove(solution:)")
        } catch {
            NSLog("Error while saving in SolutionTableViewController.remove(solution:)")
        }
    }
}

// MARK: - NSFetchedResultsControllerDelegate
extension SolutionTableViewController: NSFetchedResultsControllerDelegate {
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
            fatalError("Unknown change type: \(type)")
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
    }
}

