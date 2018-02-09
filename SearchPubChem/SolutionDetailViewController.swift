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
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        nameLabel.text = solution.name
        dateLabel.text = solution.created?.description
        
        if let compounds = solution.compounds, let amount = solution.amount {
            //let compoundsArray = Array(compounds)
            var count = 1
            
            for compound in compounds {
                guard let compound = compound as? Compound else {
                    print("It is not a compound.")
                    return
                }
                
                if let label = self.view.viewWithTag(count) as? UILabel {
                    label.text = compound.name
                }
                
                if let value = amount.value(forKey: compound.name!) {
                    if let label = self.view.viewWithTag(count+10) as? UILabel {
                        label.text = String(describing: value)
                    }
                }
                
                count += 1
            }
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
