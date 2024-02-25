//
//  CompoundListView.swift
//  VisionSearchPubChem
//
//  Created by Jae Seung Lee on 2/25/24.
//  Copyright © 2024 Jae Seung Lee. All rights reserved.
//

import SwiftUI

struct CompoundListView: View {
    @EnvironmentObject private var viewModel: VisionSearchPubChemViewModel
    
    @State var compounds: [Compound]
    
    @State private var selectedCompound: Compound?
    
    var body: some View {
        NavigationSplitView {
            List(compounds, selection: $selectedCompound) { compound in
                label(for: compound)
            }
        } detail: {
            if let selectedCompound = selectedCompound {
                CompoundDetailView(compound: selectedCompound)
            } else {
                EmptyView()
            }
        }
    }
    
    private func label(for compound: Compound) -> some View {
        HStack {
            Text(compound.name ?? "N/A")
            
            if let count = compound.solutions?.count, count > 0 {
                Text("💧")
            }
            
            Spacer()
            Text(compound.formula ?? "N/A")
        }
    }
}
