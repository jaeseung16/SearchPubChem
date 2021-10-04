//
//  CompoundMiniDetailViewController.swift
//  SearchPubChem
//
//  Created by Jae Seung Lee on 2/17/18.
//  Copyright © 2018 Jae Seung Lee. All rights reserved.
//

import UIKit

@available(*, deprecated, message: "Replaced by CompoundMiniDetailView")
class CompoundMiniDetailViewController: UIViewController {
    // MARK: - Properties
    // Outlets
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var formulaLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    
    // Variables
    var compound: Compound!
    
    // MARK: - Methods
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
}
