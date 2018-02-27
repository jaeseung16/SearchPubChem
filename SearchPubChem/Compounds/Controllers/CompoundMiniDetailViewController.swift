//
//  CompoundMiniDetailViewController.swift
//  SearchPubChem
//
//  Created by Jae Seung Lee on 2/17/18.
//  Copyright © 2018 Jae Seung Lee. All rights reserved.
//

import UIKit

class CompoundMiniDetailViewController: UIViewController {

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var formulaLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    
    var compound: Compound!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        nameLabel.text = compound.name
        formulaLabel.text = compound.formula
        if let image = compound.image as Data? {
            imageView.image = UIImage(data: image)
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
