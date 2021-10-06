//
//  MakeSolutionView.swift
//  SearchPubChem
//
//  Created by Jae Seung Lee on 10/6/21.
//  Copyright © 2021 Jae Seung Lee. All rights reserved.
//

import SwiftUI
import CoreData

struct MakeSolutionView: UIViewControllerRepresentable {
    @Environment(\.managedObjectContext) private var viewContext
    
    func makeUIViewController(context: Context) -> MakeSolutionViewController {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        print("\(storyboard)")
        guard let makeSolutionViewController = storyboard.instantiateViewController(withIdentifier: "MakeSolutionViewController") as? MakeSolutionViewController else {
            fatalError("Cannot load from storyboard")
        }
        
        makeSolutionViewController.viewContext = viewContext
        return makeSolutionViewController
    }
    
    func updateUIViewController(_ uiViewController: MakeSolutionViewController, context: Context) {
        
    }
        

}
