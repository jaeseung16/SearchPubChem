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
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var saveButton: UIBarButtonItem!
    
    @IBOutlet weak var nameToSearch: UITextField!
    
    @IBOutlet weak var compoundImageView: UIImageView!
    
    @IBOutlet weak var cidTitleLabel: UILabel!
    @IBOutlet weak var iupacTitleLabel: UILabel!
    @IBOutlet weak var weightTitleLabel: UILabel!
    
    @IBOutlet weak var formulaLabel: UILabel!
    @IBOutlet weak var cidLabel: UILabel!
    @IBOutlet weak var iupacNameLabel: UILabel!
    @IBOutlet weak var weightLabel: UILabel!
    
    @IBOutlet weak var conformerButton: UIButton!
    
    // Constants
    let client = PubChemSearch()
    
    // Variables
    var dataController: DataController!
    var conformer: Conformers?

    // MARK: - Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        hideLabels(true)
        showNetworkIndicators(false)
        enableSaveButton(false)
        conformerButton.isHidden = true
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let conformerViewController = segue.destination as? ConformerViewController {
            guard let conformer = self.conformer else {
                print("No 3D Data")
                return
            }
                conformerViewController.conformer = conformer
        }
        
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
        cidTitleLabel.isHidden = yes
        iupacTitleLabel.isHidden = yes
        weightTitleLabel.isHidden = yes

        formulaLabel.isHidden = yes
        cidLabel.isHidden = yes
        iupacNameLabel.isHidden = yes
        weightLabel.isHidden = yes
        
        compoundImageView.isHidden = yes
    }
    
    // Actions
    @IBAction func searchByName(_ sender: UIButton) {
        let name = nameToSearch.text!.trimmingCharacters(in: .whitespaces)
        nameToSearch.text = name
        
        hideLabels(true)
        showNetworkIndicators(true)
        
        client.searchCompound(by: name) { (success, compoundInformation, errorString) in
            self.showNetworkIndicators(false)
            
            let networkErrorString = "The Internet connection appears to be offline"
            
            if success {
                guard let information = compoundInformation else {
                    NSLog("There is no infromation for a compound")
                    return
                }

                DispatchQueue.main.async {
                    self.formulaLabel.text = (information["MolecularFormula"] as! String)
                    self.weightLabel.text = String(information["MolecularWeight"] as! Double)
                    self.cidLabel.text = (information["CID"] as! String)
                    self.iupacNameLabel.text = (information["IUPACName"] as! String)
                    
                    self.hideLabels(false)
                    self.showNetworkIndicators(true)
                    
                    self.client.downloadImage(for: self.cidLabel.text!, completionHandler: { (success, data, errorString) in
                        self.showNetworkIndicators(false)
                        
                        if success {
                            DispatchQueue.main.async {
                                self.compoundImageView.image = UIImage(data: data! as Data)
                                self.enableSaveButton(true)
                            }
                        } else {
                            guard let errorString = errorString, errorString.contains(networkErrorString) else {
                                let errorString = "Failed to download the molecular structure for \'\(name)\'"
                                self.presentAlert(title: "No Image", message: errorString)
                                return
                            }
                            self.presentAlert(title: "No Image", message: networkErrorString)
                        }
                    })
                    
                    self.client.download3DData(for: self.cidLabel.text!, completionHandler: { (success, data, errorString) in
                        //self.showNetworkIndicators(false)
                        
                        if success {
                            DispatchQueue.main.async {
                                guard let atoms = data else {
                                    let errorString = "There is a problem with data \'\(String(describing: data))\'"
                                    self.presentAlert(title: "No 3D Data", message: errorString)
                                    return
                                }
                                
                                self.conformer = Conformers()
                                self.conformer?.atoms = atoms
                                self.conformer?.cid = self.cidLabel.text!
                                
                                self.conformerButton.isHidden = false
                                print(self.conformer!)
                            }
                        } else {
                            guard let errorString = errorString, errorString.contains(networkErrorString) else {
                                let errorString = "Failed to download 3d data for \'\(name)\'"
                                self.presentAlert(title: "No 3D Data", message: errorString)
                                return
                            }
                            self.presentAlert(title: "No 3D Data", message: errorString)
                        }
                    })
                    
                }
            } else {
                guard let errorString = errorString, errorString.contains(networkErrorString) else {
                    let errorString = "There is no compound matching the name \'\(name)\'"
                    self.presentAlert(title: "Search Failed", message: errorString)
                    return
                }
                self.presentAlert(title: "Search Failed", message: networkErrorString)
            }
        }
    }
    
    @IBAction func dismiss(_ sender: UIBarButtonItem) {
        showNetworkIndicators(false)
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func saveCompound(_ sender: UIBarButtonItem) {
        let compound = Compound(context: dataController.viewContext)
        
        compound.name = nameToSearch.text!
        compound.firstCharacterInName = String(compound.name!.first!).uppercased()
        compound.formula = formulaLabel.text!
        compound.molecularWeight = Double(weightLabel.text!)!
        compound.cid = cidLabel.text!
        compound.nameIUPAC = iupacNameLabel.text!
        compound.image = compoundImageView.image!.pngData()!
        
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
extension SearchByNameViewController {
    override func textFieldDidBeginEditing(_ textField: UITextField) {
        super.textFieldDidBeginEditing(textField)
        enableSaveButton(false)
    }
}
