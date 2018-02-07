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
    
    @IBOutlet weak var compound1Label: UILabel!
    @IBOutlet weak var compound2Label: UILabel!
    
    @IBOutlet weak var amount1Label: UILabel!
    @IBOutlet weak var amount2Label: UILabel!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        nameLabel.text = solution.name
        dateLabel.text = solution.created?.description
        
        if let compounds = solution.compounds, let amount = solution.amount {
            let compoundsArray = Array(compounds)
            
            if let compound = compoundsArray[0] as? Compound {
                compound1Label.text = compound.name
                if let value = amount.value(forKey: compound.name!) {
                    print("\(String(describing: value))")
                    amount1Label.text = String(describing: value)
                }
            }
            
            if let compound = compoundsArray[1] as? Compound {
                compound2Label.text = compound.name
                
                if let value = amount.value(forKey: compound.name!) {
                    print("\(String(describing: value))")
                    amount2Label.text = String(describing: value)
                }
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
