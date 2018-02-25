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
    
    // MARK: - Variables
    var solution: Solution!
    
    var compounds = [Compound]()
    var amounts = [Double]()
    var amountsMol = [Double]()
    var amountsToDisplay = [String]()
    
    weak var delegate: SolutionDetailViewControllerDelegate?
    
    // IBOutlets
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    
    @IBOutlet weak var absoluteRelativeControl: UISegmentedControl!
    @IBOutlet weak var unitControl: UISegmentedControl!
    
    @IBOutlet weak var compoundsTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        addTargetToSegmentedControls()
        retrieveDataFromSolution()
        displayNameAndDate()
        displayAmounts()

    }
    
    @IBAction func dismiss(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func deleteAndDismiss(_ sender: UIBarButtonItem) {
        delegate?.remove(solution: solution)
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func share(_ sender: UIBarButtonItem) {
        var csvString = "Compound, Amount (g), Amount (mol)\n"
        
        for k in 0..<compounds.count {
            csvString += "\(compounds[k].name ?? ""), \(amounts[k]), \(amountsMol[k])\n"
        }
        
        print(csvString)
        
        guard let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return
        }
        
        let csvFileURL = path.appendingPathComponent("/\(solution.name!).csv")
        
        do {
            try csvString.write(to: csvFileURL, atomically: true, encoding: .utf8)
        } catch {
            print("Failed to save the csv file")
        }
        
        let activityViewController = UIActivityViewController(activityItems: [csvFileURL], applicationActivities: nil)
        
        activityViewController.completionWithItemsHandler = { (activityType: UIActivityType?, completed: Bool, returnedItems: [Any]?, activityError: Error?) in
            do {
                try FileManager.default.removeItem(at: csvFileURL)
                print("Succeeded to remove the item")
            } catch {
                print("Failed to remove the item")
            }
        }
        
        present(activityViewController, animated: true, completion: nil)
        
    }
    
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
            dateFormatter.timeStyle = .medium
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
                factor = 100.0 / amounts.reduce(0.0, { x, y in x + y })
            } else {
                factor = 100.0 / amountsMol.reduce(0.0, { x, y in x + y })
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
    
    // Methods for UISegmentedControls
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
        
        let detailViewController = self.storyboard?.instantiateViewController(withIdentifier: "CompoundMiniDetailViewController") as! CompoundMiniDetailViewController
        
        detailViewController.compound = compound
        
        present(detailViewController, animated: true, completion: nil)
    }
}
