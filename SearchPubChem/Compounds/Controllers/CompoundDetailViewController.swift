//
//  CompoundDetailViewController.swift
//  SearchPubChem
//
//  Created by Jae Seung Lee on 1/21/18.
//  Copyright © 2018 Jae Seung Lee. All rights reserved.
//

import UIKit
import CoreData

class CompoundDetailViewController: UIViewController {
    // MARK: - Properties
    // Outlets
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var formulaLabel: UILabel!
    @IBOutlet weak var weightLabel: UILabel!
    @IBOutlet weak var cidLabel: UILabel!
    @IBOutlet weak var iupacLabel: UILabel!
    @IBOutlet weak var compoundImageView: UIImageView!
    @IBOutlet weak var deleteButton: UIBarButtonItem!
    @IBOutlet weak var solutionsTableView: UITableView!
    
    // Constants
    let detailViewControllerIdentifier = "SolutionDetailViewController"
    let tableViewCellIdentifier = "SolutionMadeOfCompoundTableViewCell"
    let webViewControllerIdentifer = "WebPubChemViewController"
    
    // Variables
    var compound: Compound!
    
    var dataController: DataController!
    var fetchedResultsController: NSFetchedResultsController<Solution>! {
        didSet {
            fetchedResultsController.delegate = self
            
            do {
                try fetchedResultsController.performFetch()
            } catch {
                NSLog("Solutions cannt be fetched for the compound: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        solutionsTableView.reloadData()
    }
    
    func configureView() {
        nameLabel.text = compound.name?.uppercased()
        formulaLabel.text = compound.formula
        weightLabel.text = "\(String(describing: compound.molecularWeight)) gram/mol"
        cidLabel.text = "PubChem CID: \(compound.cid!)"
        iupacLabel.text = "IUPAC Name: \(compound.nameIUPAC!)"
        
        if let image = compound.image as Data? {
            compoundImageView.image = UIImage(data: image)
        }
        
        if let solutions = fetchedResultsController.fetchedObjects {
            deleteButton.isEnabled = (solutions.count == 0)
        }
    }
    
    // Actions
    @IBAction func deleteAndDismiss(_ sender: UIBarButtonItem) {
        dataController.viewContext.delete(compound)
        
        do {
            try dataController.viewContext.save()
        } catch {
            NSLog("Error while saving: \(error.localizedDescription)")
        }
        
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func searchPubChem(_ sender: UIBarButtonItem) {
        let client = PubChemSearch()
        guard let url = client.urlForPubChem(with: compound) else {
            return
        }
        
        let webViewController = storyboard?.instantiateViewController(withIdentifier: webViewControllerIdentifer) as! WebPubChemViewController
        webViewController.url = url
        
        navigationController?.pushViewController(webViewController, animated: true)
    }
}

// MARK: - UITableViewDataSource, UITableViewDelegate
extension CompoundDetailViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return fetchedResultsController.sections?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fetchedResultsController.sections?[section].numberOfObjects ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: tableViewCellIdentifier)!
        let solution = fetchedResultsController.object(at: indexPath)
        
        cell.textLabel?.text = solution.name
        
        if let date = solution.created {
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            dateFormatter.timeStyle = .none
            dateFormatter.locale = Locale.current
            
            cell.detailTextLabel?.text = dateFormatter.string(from: date as Date)
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let solution = fetchedResultsController.object(at: indexPath)
        let detailViewController = self.storyboard?.instantiateViewController(withIdentifier: detailViewControllerIdentifier) as! SolutionDetailViewController
        
        detailViewController.solution = solution
        detailViewController.delegate = self
        
        navigationController?.pushViewController(detailViewController, animated: true)
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

// MARK: - SolutionDetailViewControllerDelegate
extension CompoundDetailViewController: SolutionDetailViewControllerDelegate {
    func remove(solution: Solution) {
        dataController.viewContext.delete(solution)
        solutionsTableView.reloadData()
        
        do {
            try dataController.viewContext.save()
            NSLog("Saved in SolutionTableViewController.remove(solution:)")
        } catch {
            NSLog("Error while saving in SolutionTableViewController.remove(solution:)")
        }
    }
}

// MARK: - NSFetchedResultsControllerDelegate
extension CompoundDetailViewController: NSFetchedResultsControllerDelegate {
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        solutionsTableView.beginUpdates()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        let set = IndexSet(integer: sectionIndex)
        
        switch (type) {
        case .insert:
            solutionsTableView.insertSections(set, with: .fade)
        case .delete:
            solutionsTableView.deleteSections(set, with: .fade)
        default:
            break
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch(type) {
        case .insert:
            solutionsTableView.insertRows(at: [newIndexPath!], with: .fade)
        case .delete:
            solutionsTableView.deleteRows(at: [indexPath!], with: .fade)
        case .update:
            solutionsTableView.reloadRows(at: [indexPath!], with: .fade)
        case .move:
            solutionsTableView.deleteRows(at: [indexPath!], with: .fade)
            solutionsTableView.insertRows(at: [newIndexPath!], with: .fade)
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        solutionsTableView.endUpdates()
    }
}
