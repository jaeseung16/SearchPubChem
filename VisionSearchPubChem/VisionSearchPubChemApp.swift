//
//  VisionSearchPubChemApp.swift
//  VisionSearchPubChem
//
//  Created by Jae Seung Lee on 2/25/24.
//  Copyright © 2024 Jae Seung Lee. All rights reserved.
//

import SwiftUI
import Persistence

@main
struct VisionSearchPubChemApp: App {
    
    private static var persistence = Persistence(name: SearchPubChemConstants.modelName.rawValue, identifier: SearchPubChemConstants.containerIdentifier.rawValue)
    private static var viewModel = VisionSearchPubChemViewModel(persistence: persistence)
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(VisionSearchPubChemApp.viewModel)
        }
    }
}
