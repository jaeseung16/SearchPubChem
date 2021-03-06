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
    
    @IBOutlet weak var searchBySegmentedControl: UISegmentedControl!
    
    private var searchType: PubChemSearch.SearchType {
        return PubChemSearch.SearchType(rawValue: searchBySegmentedControl.selectedSegmentIndex) ?? .name
    }
    
    // Constants
    private let client = PubChemSearch()
    private let networkErrorString = "The Internet connection appears to be offline"
    
    // Variables
    var dataController: DataController!
    var conformer: Conformer? {
        willSet {
            if newValue == nil {
                conformerButton.isHidden = true
            } else {
                conformerButton.isHidden = false
            }
        }
    }
    
    private var compoundTitle: String?

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
            conformerViewController.name = nameToSearch.text
            conformerViewController.formula = formulaLabel.text
        }
    }
    
    private func enableSaveButton(_ yes: Bool) {
        saveButton.isEnabled = yes
    }
    
    private func showNetworkIndicators(_ yes: Bool) {
        DispatchQueue.main.async {
            self.activityIndicator.isHidden = !yes
            UIApplication.shared.isNetworkActivityIndicatorVisible = yes
        }
    }
    
    private func hideLabels(_ yes: Bool) {
        cidTitleLabel.isHidden = yes
        iupacTitleLabel.isHidden = yes
        weightTitleLabel.isHidden = yes

        formulaLabel.isHidden = yes
        cidLabel.isHidden = yes
        iupacNameLabel.isHidden = yes
        weightLabel.isHidden = yes
        
        compoundImageView.isHidden = yes
        conformer = nil
    }
    
    // Actions
    @IBAction func searchByName(_ sender: UIButton) {
        let name = nameToSearch.text!.trimmingCharacters(in: .whitespaces)
        nameToSearch.text = name
        
        hideLabels(true)
        showNetworkIndicators(true)
        
        client.searchCompound(with: name, searchType: searchType) { (success, compoundProperties, errorString) in
            self.showNetworkIndicators(false)
            
            if success {
                guard let compoundProperties = compoundProperties else {
                    NSLog("There is no infromation for a compound")
                    return
                }

                DispatchQueue.main.async {
                    self.formulaLabel.text = compoundProperties.MolecularFormula
                    self.weightLabel.text = String(compoundProperties.MolecularWeight)
                    self.cidLabel.text = String(compoundProperties.CID)
                    self.iupacNameLabel.text = compoundProperties.IUPACName
                    
                    self.hideLabels(false)
                    self.showNetworkIndicators(true)
                    
                    self.downloadImage(for: self.cidLabel.text!)
                    self.download3DData(for: name)
                    
                    self.compoundTitle = self.searchType == .cid ? compoundProperties.Title : nil
                }
            } else {
                guard let errorString = errorString, errorString.contains(self.networkErrorString) else {
                    let errorString = "There is no compound matching the name \'\(name)\'"
                    self.presentAlert(title: "Search Failed", message: errorString)
                    return
                }
                self.presentAlert(title: "Search Failed", message: self.networkErrorString)
            }
        }
        
    }
    
    private func downloadImage(for cid: String) {
        self.client.downloadImage(for: cid, completionHandler: { (success, data, errorString) in
            if success {
                DispatchQueue.main.async {
                    self.compoundImageView.image = UIImage(data: data! as Data)
                    self.enableSaveButton(true)
                }
            } else {
                guard let errorString = errorString, errorString.contains(self.networkErrorString) else {
                    let errorString = "Failed to download the molecular structure for \'\(cid)\'"
                    self.presentAlert(title: "No Image", message: errorString)
                    return
                }
                self.presentAlert(title: "No Image", message: self.networkErrorString)
            }
        })
    }
    
    private func download3DData(for name: String) {
        self.client.download3DData(for: self.cidLabel.text!, completionHandler: { (success, conformer, errorString) in
            self.showNetworkIndicators(false)
            
            if success, let conformer = conformer {
                DispatchQueue.main.async {
                    self.conformer = conformer
                    print("\(String(describing: self.conformer))")
                }
            } else {
                guard let errorString = errorString, errorString.contains(self.networkErrorString) else {
                    let errorString = "Failed to download 3d data for \'\(name)\'"
                    self.presentAlert(title: "No 3D Data", message: errorString)
                    return
                }
                self.presentAlert(title: "No 3D Data", message: errorString)
            }
        })
    }
    
    @IBAction func dismiss(_ sender: UIBarButtonItem) {
        showNetworkIndicators(false)
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func saveCompound(_ sender: UIBarButtonItem) {
        let compound = Compound(context: dataController.viewContext)
        
        compound.name = searchType == .cid ? compoundTitle : nameToSearch.text!
        compound.firstCharacterInName = String(compound.name!.first!).uppercased()
        compound.formula = formulaLabel.text!
        compound.molecularWeight = Double(weightLabel.text!)!
        compound.cid = cidLabel.text!
        compound.nameIUPAC = iupacNameLabel.text!
        compound.image = compoundImageView.image!.pngData()!
        compound.conformerDownloaded = true
       
        let conformerEntity = ConformerEntity(context: dataController.viewContext)
        if let conformer = self.conformer {
            conformerEntity.compound = compound
            conformerEntity.conformerId = conformer.conformerId
        
            for atom in conformer.atoms {
                let atomEntity = AtomEntity(context: dataController.viewContext)
                atomEntity.atomicNumber = Int16(atom.number)
                atomEntity.coordX = atom.location[0]
                atomEntity.coordY = atom.location[1]
                atomEntity.coordZ = atom.location[2]
                atomEntity.conformer = conformerEntity
            }
        }
        //print("conformerEntity = \(conformerEntity)")
        
        do {
            try dataController.viewContext.save()
            NSLog("Saved in SearchByNameViewController.saveCompound(:)")
        } catch {
            NSLog("Error while saving in SearchByNameViewController.saveCompound(:)")
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
