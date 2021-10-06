//
//  SearchPubChemApp.swift
//  SearchPubChem
//
//  Created by Jae Seung Lee on 10/6/21.
//  Copyright © 2021 Jae Seung Lee. All rights reserved.
//

import SwiftUI

@main
struct SearchPubChemApp: App {
    let dataController = DataController(modelName: "PubChemSolution")
    let viewModel = SearchPubChemViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, dataController.viewContext)
                .environmentObject(viewModel)
        }
    }
}
