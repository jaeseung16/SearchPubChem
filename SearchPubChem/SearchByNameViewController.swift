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
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    @IBAction func searchByName(_ sender: UIButton) {
        let name = nameToSearch.text!
        
        client.searchCompound(by: name) { (success, compoundInformation) in
            if success {
                guard let information = compoundInformation else {
                    print("There is no compound.")
                    return
                }

                DispatchQueue.main.async {
                    self.formulaLabel.text = (information["MolecularFormula"] as! String)
                    self.weightLabel.text = String(information["MolecularWeight"] as! Double)
                    self.cidLabel.text = (information["CID"] as! String)
                    self.iupacNameLabel.text = (information["IUPACName"] as! String)
                    
                    self.client.downloadImage(for: self.cidLabel.text!, completionHandler: { (success, data) in
                        if success {
                            DispatchQueue.main.async {
                                self.compoundImageView.image = UIImage(data: data! as Data)
                            }
                        } else {
                            print("Cannot download the image.")
                        }
                    })
                }
                
            } else {
                
            }
        }
    }
    
    @IBAction func dismiss(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func saveCompound(_ sender: UIBarButtonItem) {
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let stack = delegate.stack
        
        let name = nameToSearch.text!
        let formula = formulaLabel.text!
        let molecularWeight = Double(weightLabel.text!)!
        let cid = cidLabel.text!
        let nameIUPAC = iupacNameLabel.text!
        let image = UIImagePNGRepresentation(compoundImageView.image!)!
        
        let compound = Compound(name: name, formula: formula, molecularWeight: molecularWeight, CID: cid, nameIUPAC: nameIUPAC, context: stack.context)
        compound.image = image as NSData
        
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
