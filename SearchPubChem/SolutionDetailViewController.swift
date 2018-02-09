//
//  SolutionDetailViewController.swift
//  SearchPubChem
//
//  Created by Jae Seung Lee on 2/6/18.
//  Copyright © 2018 Jae Seung Lee. All rights reserved.
//

import UIKit

class SolutionDetailViewController: UIViewController {
    
    var solution: Solution!
    var names = [String]()
    var amounts = [Double]()
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
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
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
