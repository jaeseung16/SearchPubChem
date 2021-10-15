//
//  ConformerView.swift
//  SearchPubChem
//
//  Created by Jae Seung Lee on 10/3/21.
//  Copyright © 2021 Jae Seung Lee. All rights reserved.
//

import SwiftUI

struct ConformerView: UIViewControllerRepresentable {
    var conformer: Conformer
    var name: String
    var formula: String
    
    func makeUIViewController(context: Context) -> ConformerViewController {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        print("\(storyboard)")
        guard let conformerViewController = storyboard.instantiateViewController(withIdentifier: "ConfomerViewController") as? ConformerViewController else {
            fatalError("Cannot load from storyboard")
        }
        
        conformerViewController.conformer = conformer
        conformerViewController.name = name.uppercased()
        conformerViewController.formula = formula
        return conformerViewController
    }
    
    func updateUIViewController(_ uiViewController: ConformerViewController, context: Context) {
        
    }
        
    
}
