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
        
        if let compounds = solution.compounds {
            let compoundsArray = Array(compounds)
            
            if let compound1 = compoundsArray[0] as? Compound {
                compound1Label.text = compound1.name
            }
            
            if let compound1 = compoundsArray[1] as? Compound {
                compound1Labe2.text = compound1.name
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
