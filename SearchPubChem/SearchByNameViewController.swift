//
//  SearchByNameViewController.swift
//  SearchPubChem
//
//  Created by Jae Seung Lee on 1/17/18.
//  Copyright © 2018 Jae Seung Lee. All rights reserved.
//

import UIKit

class SearchByNameViewController: UIViewController {

    @IBOutlet weak var nameToSearch: UITextField!
    
    @IBOutlet weak var compoundImageView: UIImageView!
    @IBOutlet weak var formulaLabel: UILabel!
    @IBOutlet weak var weightLabel: UILabel!
    @IBOutlet weak var cidLabel: UILabel!
    @IBOutlet weak var iupacNameLabel: UILabel!
    
    let client = PubChemSearch()
    var compound = Compound()
    var compounds = [Compound]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        compounds = appDelegate.compounds
        // Do any additional setup after loading the view.
    }
    
    @IBAction func searchByName(_ sender: UIButton) {
        let name = nameToSearch.text!
        
        client.searchCompound(by: name) { (success, compound) in
            if success == true {
                guard let compound = compound else {
                    print("There is no compound.")
                    return
                }
                
                self.compound = compound
                
                DispatchQueue.main.async {
                    self.formulaLabel.text = compound.formula
                    self.weightLabel.text = String(describing: compound.molecularWeight)
                    self.cidLabel.text = compound.CID
                    self.iupacNameLabel.text = compound.nameIUPAC
                }
                
            } else {
                
            }
        }
        
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

// MARK: - UITextFieldDelegate
extension SearchByNameViewController: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        textField.text = ""
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
}
