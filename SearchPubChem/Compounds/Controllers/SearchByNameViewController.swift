//
//  SearchByNameViewController.swift
//  SearchPubChem
//
//  Created by Jae Seung Lee on 1/17/18.
//  Copyright © 2018 Jae Seung Lee. All rights reserved.
//

import UIKit
import CoreData

class SearchByNameViewController: UIViewController {
    // MARK: - Properties
    // Outlets
    @IBOutlet weak var nameToSearch: UITextField!
    @IBOutlet weak var weightTitleLabel: UILabel!
    @IBOutlet weak var cidTitleLabel: UILabel!
    @IBOutlet weak var iupacTitleLabel: UILabel!
    @IBOutlet weak var compoundImageView: UIImageView!
    @IBOutlet weak var formulaLabel: UILabel!
    @IBOutlet weak var weightLabel: UILabel!
    @IBOutlet weak var cidLabel: UILabel!
    @IBOutlet weak var iupacNameLabel: UILabel!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    // Constants
    let client = PubChemSearch()
    
    // Variables
    var dataController: DataController!

    // MARK: - Methods
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        hideLabels(true)
        showNetworkIndicators(false)
        enableSaveButton(false)
    }
    
    func enableSaveButton(_ yes: Bool) {
        saveButton.isEnabled = yes
    }
    
    func showNetworkIndicators(_ yes: Bool) {
        DispatchQueue.main.async {
            self.activityIndicator.isHidden = !yes
            UIApplication.shared.isNetworkActivityIndicatorVisible = yes
        }
    }
    
    func hideLabels(_ yes: Bool) {
        weightTitleLabel.isHidden = yes
        cidTitleLabel.isHidden = yes
        iupacTitleLabel.isHidden = yes
        
        compoundImageView.isHidden = yes
        formulaLabel.isHidden = yes
        weightLabel.isHidden = yes
        cidLabel.isHidden = yes
        iupacNameLabel.isHidden = yes
    }
    
    // Actions
    @IBAction func searchByName(_ sender: UIButton) {
        let name = nameToSearch.text!.trimmingCharacters(in: .whitespaces)
        nameToSearch.text = name
        
        hideLabels(true)
        showNetworkIndicators(true)
        
        client.searchCompound(by: name) { (success, compoundInformation) in
            self.showNetworkIndicators(false)
            
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
                    
                    self.hideLabels(false)
                    self.showNetworkIndicators(true)
                    
                    self.client.downloadImage(for: self.cidLabel.text!, completionHandler: { (success, data) in
                        self.showNetworkIndicators(false)
                        
                        if success {
                            DispatchQueue.main.async {
                                self.compoundImageView.image = UIImage(data: data! as Data)
                                self.enableSaveButton(true)
                            }
                        } else {
                            DispatchQueue.main.async {
                                let alert = UIAlertController(title: "No Image", message: "Failed to download the molecular structure for \(name).", preferredStyle: .alert)
                                alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))
                                self.present(alert, animated: true, completion: nil)
                            }
                        }
                    })
                }
            } else {
                DispatchQueue.main.async {
                    let alert = UIAlertController(title: "Search Failed", message: "There is no compound matching the name \(name). Try again.", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                }
            }
        }
    }
    
    @IBAction func dismiss(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func saveCompound(_ sender: UIBarButtonItem) {
        let compound = Compound(context: dataController.viewContext)
        
        compound.name = nameToSearch.text!
        compound.formula = formulaLabel.text!
        compound.molecularWeight = Double(weightLabel.text!)!
        compound.cid = cidLabel.text!
        compound.nameIUPAC = iupacNameLabel.text!
        compound.image = UIImagePNGRepresentation(compoundImageView.image!)!
        
        do {
            try dataController.viewContext.save()
            NSLog("Saved in SolutionTableViewController.remove(solution:)")
        } catch {
            NSLog("Error while saving in SolutionTableViewController.remove(solution:)")
        }
        
        dismiss(animated: true, completion: nil)
    }
}

// MARK: - UITextFieldDelegate
extension SearchByNameViewController: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        textField.text = ""
        enableSaveButton(false)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
