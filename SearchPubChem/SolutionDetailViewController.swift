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
    var molecularWeights = [Double]()
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    
    @IBOutlet weak var absoluteRelativeControl: UISegmentedControl!
    @IBOutlet weak var unitControl: UISegmentedControl!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        absoluteRelativeControl.addTarget(self, action: #selector(SolutionDetailViewController.switchBetweenAbsoluteAndRelative), for: .valueChanged)
        
        unitControl.addTarget(self, action: #selector(SolutionDetailViewController.switchBetweenGramAndMol), for: .valueChanged)
        
        nameLabel.text = solution.name
        dateLabel.text = solution.created?.description
        
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
        }
        
        for index in 1...names.count {
            guard let nameLabel = self.view.viewWithTag(index) as? UILabel, let amountLabel = self.view.viewWithTag(index+10) as? UILabel else {
                print("Cannot find views with tags")
                break
            }
            
            nameLabel.text = names[index-1]
            amountLabel.text = "\(amounts[index-1])"
        }
        
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
        switch absoluteRelativeControl.selectedSegmentIndex {
        case 0:
            for index in 1...amounts.count {
                guard let amountLabel = self.view.viewWithTag(index+10) as? UILabel else {
                    print("Cannot find views with tags")
                    break
                }
                amountLabel.text = "\(amounts[index-1])"
            }
        case 1:
            let maximum = amounts.min()!
            
            for index in 1...amounts.count {
                guard let amountLabel = self.view.viewWithTag(index+10) as? UILabel else {
                    print("Cannot find views with tags")
                    break
                }
                amountLabel.text = "\(amounts[index-1] / maximum)"
            }
        default:
            for index in 1...amounts.count {
                guard let amountLabel = self.view.viewWithTag(index+10) as? UILabel else {
                    print("Cannot find views with tags")
                    break
                }
                amountLabel.text = "\(amounts[index-1])"
            }
        }
    }
    
    @objc func switchBetweenGramAndMol() {
        switch unitControl.selectedSegmentIndex {
        case 0:
            for index in 1...amounts.count {
                guard let amountLabel = self.view.viewWithTag(index+10) as? UILabel else {
                    print("Cannot find views with tags")
                    break
                }
                amountLabel.text = "\(amounts[index-1])"
            }
        case 1:
            for index in 1...amounts.count {
                guard let amountLabel = self.view.viewWithTag(index+10) as? UILabel else {
                    print("Cannot find views with tags")
                    break
                }
                amountLabel.text = "\(amounts[index-1] / molecularWeights[index-1])"
            }
        default:
            for index in 1...amounts.count {
                guard let amountLabel = self.view.viewWithTag(index+10) as? UILabel else {
                    print("Cannot find views with tags")
                    break
                }
                amountLabel.text = "\(amounts[index-1])"
            }
        }
    }
}
