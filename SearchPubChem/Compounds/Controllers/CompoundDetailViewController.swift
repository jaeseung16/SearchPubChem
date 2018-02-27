//
//  CompoundDetailViewController.swift
//  SearchPubChem
//
//  Created by Jae Seung Lee on 1/21/18.
//  Copyright © 2018 Jae Seung Lee. All rights reserved.
//

import UIKit
import CoreData

class CompoundDetailViewController: UIViewController, NSFetchedResultsControllerDelegate {

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var formulaLabel: UILabel!
    @IBOutlet weak var weightLabel: UILabel!
    @IBOutlet weak var cidLabel: UILabel!
    @IBOutlet weak var iupacLabel: UILabel!
    @IBOutlet weak var compoundImageView: UIImageView!
    @IBOutlet weak var deleteButton: UIBarButtonItem!
    
    @IBOutlet weak var solutionsTableView: UITableView!
    
    var dataController: DataController!
    
    var compound: Compound!
    
    var fetchedResultsController: NSFetchedResultsController<Solution>! {
        didSet {
            fetchedResultsController.delegate = self
            
            do {
                try fetchedResultsController.performFetch()
            } catch {
                print("Solutions cannt be fetched for the compound: \(error.localizedDescription)")
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        nameLabel.text = compound.name?.uppercased()
        formulaLabel.text = compound.formula
        weightLabel.text = "\(String(describing: compound.molecularWeight)) gram/mol"
        cidLabel.text = "PubChem CID: \(compound.cid!)"
        iupacLabel.text = "IUPAC Name: \(compound.nameIUPAC!)"
        
        if let image = compound.image as Data? {
            compoundImageView.image = UIImage(data: image)
        }
        
        if let solutions = fetchedResultsController.fetchedObjects {
            if solutions.count == 0 {
                deleteButton.isEnabled = true
            } else {
                deleteButton.isEnabled = false
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        solutionsTableView.reloadData()
    }
    
    @IBAction func deleteAndDismiss(_ sender: UIBarButtonItem) {
        dataController.viewContext.delete(compound)
        
        do {
            try dataController.viewContext.save()
            print("Saved in CompoundDetailViewController.deleteAndDismiss(_:)")
        } catch {
            print("Error while saving in CompoundDetailViewController.deleteAndDismiss(_:)")
        }
        
        navigationController?.popViewController(animated: true)
        //dismiss(animated: true, completion: nil)
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

extension CompoundDetailViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return fetchedResultsController.sections?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fetchedResultsController.sections?[section].numberOfObjects ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SolutionMadeOfCompoundTableViewCell")!
        
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
        
        let detailViewController = self.storyboard?.instantiateViewController(withIdentifier: "SolutionDetailViewController") as! SolutionDetailViewController
        detailViewController.solution = solution
        detailViewController.delegate = self
        
        navigationController?.pushViewController(detailViewController, animated: true)
    }
    
}

extension CompoundDetailViewController: SolutionDetailViewControllerDelegate {
    func remove(solution: Solution) {
        dataController.viewContext.delete(solution)
        solutionsTableView.reloadData()
        
        do {
            try dataController.viewContext.save()
            print("Saved in SolutionTableViewController.remove(solution:)")
        } catch {
            print("Error while saving in SolutionTableViewController.remove(solution:)")
        }
    }
}
