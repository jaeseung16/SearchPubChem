//
//  CompoundDetailViewController.swift
//  SearchPubChem
//
//  Created by Jae Seung Lee on 1/21/18.
//  Copyright © 2018 Jae Seung Lee. All rights reserved.
//

import UIKit

class CompoundDetailViewController: UIViewController {

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var formulaLabel: UILabel!
    @IBOutlet weak var weightLabel: UILabel!
    @IBOutlet weak var cidLabel: UILabel!
    @IBOutlet weak var iupacLabel: UILabel!
    @IBOutlet weak var compoundImageView: UIImageView!
    
    var compound: Compound!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        nameLabel.text = compound.name
        formulaLabel.text = compound.formula
        weightLabel.text = String(describing: compound.molecularWeight)
        cidLabel.text = compound.cid
        iupacLabel.text = compound.nameIUPAC
        
        if let image = compound.image as Data? {
            compoundImageView.image = UIImage(data: image)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func dismiss(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
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
