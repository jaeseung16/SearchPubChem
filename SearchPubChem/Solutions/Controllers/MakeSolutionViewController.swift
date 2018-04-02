//
//  MakeSolutionViewController.swift
//  SearchPubChem
//
//  Created by Jae Seung Lee on 1/28/18.
//  Copyright © 2018 Jae Seung Lee. All rights reserved.
//

import UIKit
import CoreData

enum Units: Int {
    case gram = 0, mg, mol, mM
}

class MakeSolutionViewController: UIViewController {
    // MARK: - Properties
    // Outlets
    @IBOutlet weak var labelForSolution: UITextField!
    @IBOutlet weak var addCompound: UIButton!
    @IBOutlet weak var solutionTableView: UITableView!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    
    // Constants
    let maxNumberOfCompounds = 10
    let collectionViewControllerIdentifier = "CompoundCollectionViewController"
    
    // Variables
    var compounds = [Compound]()
    var amounts = [Double]()
    var units = [Int]()
    
    var dataController: DataController!
    
    // MARK: - Methods
    override func viewDidLoad() {
        super.viewDidLoad()

        labelForSolution.text = ""
        saveButton.isEnabled = false
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        solutionTableView.reloadData()
    }
    
    // Actions
    @IBAction func dismiss(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }

    @IBAction func addCompounds(_ sender: UIButton) {
        // Fetching compounds
        let fetchRequest: NSFetchRequest<Compound> = Compound.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "name", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        let fc = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: "firstCharacterInName", cacheName: "compounds")
        
        // Set up the fetchedResultsController of CompoundCollectionViewController
        let compoundCollectionViewController = storyboard?.instantiateViewController(withIdentifier: collectionViewControllerIdentifier) as! CompoundCollectionViewController
        
        compoundCollectionViewController.fetchedResultsController = fc
        compoundCollectionViewController.delegate = self
        compoundCollectionViewController.compounds = compounds
        present(compoundCollectionViewController, animated: true, completion: nil)
    }
    
    @IBAction func createSolution(_ sender: UIBarButtonItem) {
        guard labelForSolution.text != "" else {
            let title = "No Label"
            let message = "Try again after giving a label."
            presentAlert(title: title, message: message)
            return
        }
        
        var amountsWithUnit: [String: Double] = [:]
        
        for index in 0..<compounds.count {
            let name = compounds[index].name!
            let amount = amounts[index]
            
            guard let unit = Units(rawValue: units[index]) else {
                NSLog("Invalid unit")
                continue
            }
            
            switch unit {
            case .gram:
                amountsWithUnit[name] = amount
            case .mg:
                amountsWithUnit[name] = amount / 1000.0
            case .mol:
                amountsWithUnit[name] = amount * compounds[index].molecularWeight
            case .mM:
                amountsWithUnit[name] = amount * compounds[index].molecularWeight / 1000.0
            }
        }
        
        let solution = Solution(context: dataController.viewContext)
        solution.name = labelForSolution.text!.trimmingCharacters(in: .whitespaces)
        solution.amount = amountsWithUnit as NSObject
        solution.compounds = NSSet(array: compounds)
        
        do {
            try dataController.viewContext.save()
            NSLog("Successfully saved a new solution")
        } catch {
            NSLog("There is an error while saving a new solution: \(error.localizedDescription)")
        }
        
        let title = "Saved"
        let message = "A new solution saved."
        presentAlert(title: title, message: message) { _ in
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    func presentAlert(title: String, message: String, completion: ((UIAlertAction) -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: completion))
        self.present(alert, animated: true, completion: nil)
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource
extension MakeSolutionViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return compounds.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MakeSolutionTableViewCell") as! MakeSolutionTableViewCell
        
        cell.label.text = compounds[indexPath.row].name
        cell.delegate = self

        return cell
    }
}

// MARK: - UITextFieldDelegate
extension MakeSolutionViewController: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        textField.text = ""
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

// MARK: - CompoundCollectionViewDelegate
extension MakeSolutionViewController: CompoundCollectionViewDelegate {
    func selectedCompounds(_ compounds: [Compound], with title: String) {
        saveButton.isEnabled = compounds.count > 0 ? true : false
        
        self.compounds = compounds
        
        while amounts.count < compounds.count {
            amounts.append(0.0)
            units.append(0)
        }
        
        while amounts.count > compounds.count {
            amounts.removeLast()
            units.removeLast()
        }
        
        // If a label for a solution is not given yet, set it to 'title'
        if labelForSolution.text == "" {
            labelForSolution.text = title
        }
    }
}

// MARK: - MakeSolutionTableViewCellDelegate
extension MakeSolutionViewController: MakeSolutionTableViewCellDelegate {
    func didEndEditing(_ cell: MakeSolutionTableViewCell) {
        let indexPath = solutionTableView.indexPath(for: cell)
        if let text = cell.textField.text, let amount = Double(text) {
            amounts[indexPath!.row] = amount
        }
    }
    
    func didValueChanged(_ cell: MakeSolutionTableViewCell) {
        let indexPath = solutionTableView.indexPath(for: cell)
        units[indexPath!.row] = cell.unitPickerView.selectedRow(inComponent: 0)
    }
}
