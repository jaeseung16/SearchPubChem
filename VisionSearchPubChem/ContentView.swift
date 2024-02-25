//
//  ContentView.swift
//  VisionSearchPubChem
//
//  Created by Jae Seung Lee on 2/25/24.
//  Copyright © 2024 Jae Seung Lee. All rights reserved.
//

import SwiftUI
import RealityKit
import RealityKitContent

struct ContentView: View {
    @EnvironmentObject var viewModel: VisionSearchPubChemViewModel
    
    var body: some View {
        VStack {
            CompoundListView(compounds: viewModel.allCompounds)
        }
        .padding()
    }
}
