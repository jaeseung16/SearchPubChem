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
}

class MakeSolutionTableViewCell: UITableViewCell {

    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    
    weak var delegate: MakeSolutionTableViewCellDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        textField.delegate = self
    }
}

extension MakeSolutionTableViewCell: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        textField.text = ""
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        delegate?.didEndEditing(self)
        textField.resignFirstResponder()
        return true
    }}
