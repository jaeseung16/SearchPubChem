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
    
    @State private var compound: Compound?
    
    var body: some Scene {
        WindowGroup(id: WindowId.compounds.rawValue) {
            ContentView(compound: $compound)
                .environmentObject(VisionSearchPubChemApp.viewModel)
        }
        .windowStyle(.plain)
        
        WindowGroup(id: WindowId.conformer.rawValue) {
            ConformerView(compound: $compound)
                .environmentObject(VisionSearchPubChemApp.viewModel)
        }
        .windowStyle(.volumetric)
        .defaultSize(width: 0.5, height: 0.5, depth: 0.5, in: .meters)
    }
}
