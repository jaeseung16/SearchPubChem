//
//  MakeSolutionTableViewCell.swift
//  SearchPubChem
//
//  Created by Jae Seung Lee on 2/10/18.
//  Copyright © 2018 Jae Seung Lee. All rights reserved.
//

import UIKit

protocol MakeSolutionTableViewCellDelegate: AnyObject {
    func didEndEditing(_ cell: MakeSolutionTableViewCell)
    func didValueChanged(_ cell: MakeSolutionTableViewCell)
}

class MakeSolutionTableViewCell: UITableViewCell {
    // MARK: - Properties
    // Outlets
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var unitPickerView: UIPickerView!
    
    // Variable
    weak var delegate: MakeSolutionTableViewCellDelegate?
    
    let units = ["gram", "mg", "mol", "mM"]
        
    // MARK: - Methods
    override func awakeFromNib() {
        super.awakeFromNib()
        textField.delegate = self
    }
}

// MARK: - UITextFieldDelegate
extension MakeSolutionTableViewCell: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        textField.text = ""
    }
    
    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        delegate?.didEndEditing(self)
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

// MARK: - UIPickerViewDataSource and UIPickerViewDelegate
extension MakeSolutionTableViewCell: UIPickerViewDataSource, UIPickerViewDelegate {
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return units.count
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        let label = UILabel()
        label.text = units[row]
        label.textAlignment = .right
        
        return label
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        delegate?.didValueChanged(self)
    }
}
