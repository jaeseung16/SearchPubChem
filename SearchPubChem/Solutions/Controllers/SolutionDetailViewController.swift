//
//  SolutionDetailViewController.swift
//  SearchPubChem
//
//  Created by Jae Seung Lee on 2/6/18.
//  Copyright © 2018 Jae Seung Lee. All rights reserved.
//

import UIKit
import CoreData

protocol SolutionDetailViewControllerDelegate: AnyObject {
    func remove(solution: Solution)
}

class SolutionDetailViewController: UIViewController {
    // MARK: - Properties
    // IBOutlets
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var absoluteRelativeControl: UISegmentedControl!
    @IBOutlet weak var unitControl: UISegmentedControl!
    @IBOutlet weak var compoundsTableView: UITableView!
    
    // Vairables
    var solution: Solution!
    var compounds = [Compound]()
    var amounts = [Double]()
    var amountsMol = [Double]()
    var amountsToDisplay = [String]()
    
    // delegate will be set by a presenting view controller
    weak var delegate: SolutionDetailViewControllerDelegate?
    
    // MARK: - Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        addTargetToSegmentedControls()
        retrieveDataFromSolution()
        displayNameAndDate()
        displayAmounts()
    }
    
    // Actions
    @IBAction func deleteAndDismiss(_ sender: UIBarButtonItem) {
        delegate?.remove(solution: solution)
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func share(_ sender: UIBarButtonItem) {
        // Build a csv file
        var csvString = "CID, Compound, Molecular Weight (gram/mol), Amount (g), Amount (mol)\n"
        
        for k in 0..<compounds.count {
            csvString += "\(compounds[k].cid!), "
            csvString += "\(compounds[k].name!), "
            csvString += "\(compounds[k].molecularWeight), "
            csvString += "\(amounts[k]), "
            csvString += "\(amountsMol[k])\n"
        }

        guard let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return
        }
        
        let filename = solution.name!.replacingOccurrences(of: "/", with: "-")
        let csvFileURL = path.appendingPathComponent("\(filename).csv")
        
        do {
            try csvString.write(to: csvFileURL, atomically: true, encoding: .utf8)
        } catch {
            print("Failed to save the csv file")
        }
        
        // Prepare and present an activityViewController
        let activityViewController = UIActivityViewController(activityItems: ["Sharing \(solution.name!).csv", csvFileURL], applicationActivities: nil)
        
        activityViewController.completionWithItemsHandler = { (activityType: UIActivity.ActivityType?, completed: Bool, returnedItems: [Any]?, activityError: Error?) in
            do {
                try FileManager.default.removeItem(at: csvFileURL)
                print("Succeeded to remove the item")
            } catch {
                print("Failed to remove the item")
            }
        }
        
        present(activityViewController, animated: true, completion: nil)
    }
    
    // MARK: - Convinience methods
    func retrieveDataFromSolution() {
        guard let compounds = solution.compounds, let amount = solution.amount else {
            print("There is no information.")
            return
        }
        
        for compound in compounds {
            guard let compound = compound as? Compound else {
                print("It is not a compound.")
                break
            }
            
            self.compounds.append(compound)
            
            guard let name = compound.name, let value = amount.value(forKey: name) as? Double else {
                print("No value found")
                break
            }
            
            amounts.append(value)
            amountsMol.append(value/compound.molecularWeight)
            amountsToDisplay.append("\(value)")
        }
    }
    
    func displayNameAndDate() {
        if let name = solution.name {
            nameLabel.text = name.uppercased()
        }
        
        if let date = solution.created {
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            dateFormatter.timeStyle = .none
            dateFormatter.locale = Locale.current
            
            dateLabel.text = "Created on " + dateFormatter.string(from: date as Date)
        }
    }
    
    func displayAmounts() {
        let unit = unitControl.selectedSegmentIndex
        let absolute = absoluteRelativeControl.selectedSegmentIndex
        
        var factor = 1.0
        
        if absolute == 1 {
            if unit == 0 {
                factor = 100.0 / sumOf(amounts)
            } else {
                factor = 100.0 / sumOf(amountsMol)
            }
        }

        for k in 0..<amounts.count {
            var amount: Double
            
            if unit == 0 {
                amount = amounts[k] * factor
            } else {
                amount = amountsMol[k] * factor
            }
            
            amountsToDisplay[k] = String(format: "%g", amount)
        }

        compoundsTableView.reloadData()
    }
    
    func sumOf(_ amounts: [Double]) -> Double {
        return amounts.reduce(0.0, { x, y in x + y })
    }
    
    // MARK: - UISegmentedControls
    func addTargetToSegmentedControls() {
        absoluteRelativeControl.addTarget(self, action: #selector(SolutionDetailViewController.switchBetweenAbsoluteAndRelative), for: .valueChanged)
        
        unitControl.addTarget(self, action: #selector(SolutionDetailViewController.switchBetweenGramAndMol), for: .valueChanged)
    }
    
    @objc func switchBetweenAbsoluteAndRelative() {
        displayAmounts()
    }
    
    @objc func switchBetweenGramAndMol() {
        displayAmounts()
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource
extension SolutionDetailViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return solution.compounds?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CompoundsTableViewCell")!
        
        cell.textLabel?.text = compounds[indexPath.row].name
        cell.detailTextLabel?.text = amountsToDisplay[indexPath.row]
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let compound = compounds[indexPath.row]
        let detailViewController = storyboard?.instantiateViewController(withIdentifier: "CompoundMiniDetailViewController") as! CompoundMiniDetailViewController
        
        detailViewController.compound = compound
        
        present(detailViewController, animated: true, completion: nil)
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
