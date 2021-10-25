//
//  UIViewController+Extension.swift
//  SearchPubChem
//
//  Created by Jae Seung Lee on 4/9/18.
//  Copyright © 2018 Jae Seung Lee. All rights reserved.
//

import UIKit

extension UIViewController {
    func presentAlert(title: String, message: String, completion: ((UIAlertAction) -> Void)? = nil) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: Action.Dismiss.rawValue, style: .cancel, handler: completion))
            self.present(alert, animated: true, completion: nil)
        }
    }
}

// MARK: - UITextFieldDelegate
extension UIViewController: UITextFieldDelegate {
    public func textFieldDidBeginEditing(_ textField: UITextField) {
        textField.text = ""
    }
    
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
