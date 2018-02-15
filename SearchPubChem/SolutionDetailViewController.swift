//
//  SolutionDetailViewController.swift
//  SearchPubChem
//
//  Created by Jae Seung Lee on 2/6/18.
//  Copyright © 2018 Jae Seung Lee. All rights reserved.
//

import UIKit
import CoreData

class SolutionDetailViewController: UIViewController {
    
    var solution: Solution!
    var names = [String]()
    var amounts = [Double]()
    var amountsMol = [Double]()
    var molecularWeights = [Double]()
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    
    @IBOutlet weak var absoluteRelativeControl: UISegmentedControl!
    @IBOutlet weak var unitControl: UISegmentedControl!
    
    @IBOutlet weak var compoundsTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        absoluteRelativeControl.addTarget(self, action: #selector(SolutionDetailViewController.switchBetweenAbsoluteAndRelative), for: .valueChanged)
        
        unitControl.addTarget(self, action: #selector(SolutionDetailViewController.switchBetweenGramAndMol), for: .valueChanged)
        
        nameLabel.text = solution.name?.uppercased()
        
        if let date = solution.created {
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            dateFormatter.timeStyle = .medium
            dateFormatter.locale = Locale.current
            
            dateLabel.text = "Created on " + dateFormatter.string(from: date as Date)
        }
        
        guard let compounds = solution.compounds, let amount = solution.amount else {
            print("There is no information.")
            return
        }
        
        for compound in compounds {
            guard let compound = compound as? Compound else {
                print("It is not a compound.")
                break
            }
            
            guard let name = compound.name else {
                print("No name found")
                break
            }
            
            guard let value = amount.value(forKey: name) as? Double else {
                print("No value found")
                break
            }
            
            names.append(name)
            amounts.append(value)
            molecularWeights.append(compound.molecularWeight)
            amountsMol.append(value/compound.molecularWeight)
        }
        
        compoundsTableView.reloadData()
    }
    
    @IBAction func dismiss(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func deleteAndDismiss(_ sender: UIBarButtonItem) {
        // Get the stack
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let stack = delegate.stack
        stack.context.delete(solution)
        
        if save(context: stack.context) {
            print("Saved in SolutionDetailViewController.deleteAndDismiss(_:)")
        } else {
            print("Error while saving in SolutionDetailViewController.deleteAndDismiss(_:)")
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

    @objc func switchBetweenAbsoluteAndRelative() {
        compoundsTableView.reloadData()
    }
    
    @objc func switchBetweenGramAndMol() {
        compoundsTableView.reloadData()
    }
    
}

extension SolutionDetailViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return names.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CompoundsTableViewCell")!
        
        cell.textLabel?.text = names[indexPath.row]
        
        var amount: Double
        
        switch unitControl.selectedSegmentIndex {
        case 0:
            amount = amounts[indexPath.row]
        case 1:
            amount = amountsMol[indexPath.row]
        default:
            amount = amounts[indexPath.row]
        }
        
        var factor: Double
        switch absoluteRelativeControl.selectedSegmentIndex {
        case 0: factor = 1.0
        case 1:
            if unitControl.selectedSegmentIndex == 0 {
                factor = 100.0 / amounts.reduce(0.0, { x, y in x + y })
            } else if unitControl.selectedSegmentIndex == 1 {
                factor = 100.0 / amountsMol.reduce(0.0, { x, y in x + y })
            } else {
                factor = 1.0
            }
        default: factor = 1.0
        }
        
        cell.detailTextLabel?.text = String(amount * factor)
        
        return cell
    }
    
    
}
