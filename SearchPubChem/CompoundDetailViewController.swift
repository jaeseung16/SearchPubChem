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
    
    var compound: Compound!
    var solutions = [Solution]()
    
    var fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult>? {
        didSet {
            fetchedResultsController?.delegate = self
            
            if let fc = fetchedResultsController {
                do {
                    try fc.performFetch()
                } catch let e as NSError {
                    print("Error while trying to perform a search: \n\(e)\n\(fetchedResultsController)")
                }
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
        
        if let solutions = fetchedResultsController?.fetchedObjects as? [Solution] {
            if solutions.count == 0 {
                deleteButton.isEnabled = true
            } else {
                deleteButton.isEnabled = false
            }
            
            for solution in solutions {
                self.solutions.append(solution)
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        solutionsTableView.reloadData()
    }
    
    @IBAction func dismiss(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func deleteAndDismiss(_ sender: UIBarButtonItem) {
        // Get the stack
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let stack = delegate.stack
        stack.context.delete(compound)
        
        if save(context: stack.context) {
            print("Saved in CompoundDetailViewController.deleteAndDismiss(_:)")
        } else {
            print("Error while saving in CompoundDetailViewController.deleteAndDismiss(_:)")
        }
        
        dismiss(animated: true, completion: nil)
    }
    
    func save(context: NSManagedObjectContext) -> Bool {
        if context.hasChanges {
            do {
                try context.save()
                return true
            } catch {
                return false
            }
        } else {
            print("Context has not changed.")
            return false
        }
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
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return solutions.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SolutionMadeOfCompoundTableViewCell")!
        
        cell.textLabel?.text = solutions[indexPath.row].name
        
        if let date = solutions[indexPath.row].created {
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            dateFormatter.timeStyle = .none
            dateFormatter.locale = Locale.current
            
            cell.detailTextLabel?.text = dateFormatter.string(from: date as Date)
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let solution = solutions[indexPath.row]
        
        let detailViewController = self.storyboard?.instantiateViewController(withIdentifier: "SolutionDetailViewController") as! SolutionDetailViewController
        detailViewController.solution = solution
        detailViewController.delegate = self
        
        present(detailViewController, animated: true, completion: nil)
    }
    
}

extension CompoundDetailViewController: SolutionDetailViewControllerDelegate {
    func remove(solution: Solution) {
        if let index = solutions.index(of: solution) {
            solutions.remove(at: index)
            
            fetchedResultsController?.managedObjectContext.delete(solution)
            
            if self.save(context: (fetchedResultsController?.managedObjectContext)!) {
                print("Saved in CompoundDetailViewController.remove(solution:)")
            } else {
                print("Error while saving in CompoundDetailViewController.remove(solution:)")
            }
        }
    }
}
