//
//  MakeSolutionViewController.swift
//  SearchPubChem
//
//  Created by Jae Seung Lee on 1/28/18.
//  Copyright © 2018 Jae Seung Lee. All rights reserved.
//

import UIKit
import CoreData

class MakeSolutionViewController: UIViewController {

    @IBOutlet weak var labelForSolution: UITextField!
    @IBOutlet weak var addCompound: UIButton!
    @IBOutlet weak var solutionTableView: UITableView!
    
    @IBOutlet weak var saveButton: UIBarButtonItem!
    
    let maxNumberOfCompounds = 10
    var compounds = [Compound]()
    var amounts = [Double]()
    var units = [Int]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        labelForSolution.text = ""
        saveButton.isEnabled = false
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        print("\(compounds.count)")
        solutionTableView.reloadData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func dismiss(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
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
            
            if units[index] == 1 {
                amountsWithUnit[name] = amount / 1000.0
            } else {
                amountsWithUnit[name] = amount
            }
        }
        
        // Get the stack
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let stack = delegate.stack
        
        let solution = Solution(context: stack.context)
        solution.name = labelForSolution.text!.trimmingCharacters(in: .whitespaces)
        solution.amount = amountsWithUnit as NSObject
        solution.created = Date()
        solution.compounds = NSSet(array: compounds)
        
        try? stack.context.save()
        
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
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        
        if (sender as? UIButton) != nil {
            // Get the stack
            let delegate = UIApplication.shared.delegate as! AppDelegate
            let stack = delegate.stack
            
            // Fetching compounds
            let fr = NSFetchRequest<NSFetchRequestResult>(entityName: "Compound")
            fr.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
            
            let fc = NSFetchedResultsController(fetchRequest: fr, managedObjectContext: stack.context, sectionNameKeyPath: nil, cacheName: nil)
            
            do {
                try fc.performFetch()
            } catch {
                print("Error while performing search: \n\(error)\n\(String(describing: fc))")
                return
            }
            
            // Set up the fetchedResultsController of CompoundCollectionViewController
            if let compoundCollectionViewController = segue.destination as? CompoundCollectionViewController {
                compoundCollectionViewController.fetchedResultsController = fc
                compoundCollectionViewController.delegate = self
                compoundCollectionViewController.compounds = compounds
                present(compoundCollectionViewController, animated: true, completion: nil)
            }
        }
    }
    
}

// MARK: - CompoundCollectionViewDelegate
extension MakeSolutionViewController: CompoundCollectionViewDelegate {
    func selectedCompounds(with compounds: [Compound]) {
        saveButton.isEnabled = compounds.count > 0 ? true : false
        
        self.compounds = compounds
        
        while amounts.count < compounds.count {
            amounts.append(0.0)
            units.append(0)
        }
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

        print(compounds)
        
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

// MARK: - MakeSolutionTableViewCellDelegate
extension MakeSolutionViewController: MakeSolutionTableViewCellDelegate {
    func didEndEditing(_ cell: MakeSolutionTableViewCell) {
        let indexPath = solutionTableView.indexPath(for: cell)
        if let text = cell.textField.text, let amount = Double(text) {
            amounts[indexPath!.row] = amount
        }
        print("\(amounts)")
    }
    
    @objc func didValueChanged(_ cell: MakeSolutionTableViewCell) {
        let indexPath = solutionTableView.indexPath(for: cell)
        units[indexPath!.row] = cell.segmentedControl.selectedSegmentIndex
        print("\(units)")
    }
}
