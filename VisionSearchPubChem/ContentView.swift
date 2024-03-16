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
    
    @State private var selectedTab: TabItem?
    
    @Binding var compound: Compound?
    
    var body: some View {
        NavigationSplitView {
            List(TabItem.allCases, selection: $selectedTab) {
                Text($0.rawValue)
            }
        } content: {
            switch selectedTab {
            case .Compounds:
                CompoundListView(compounds: viewModel.allCompounds, selectedCompound: $compound)
                    .environmentObject(viewModel)
            case .Solutions:
                EmptyView()
            case .none:
                EmptyView()
            }
        } detail: {
            switch selectedTab {
            case .Compounds:
                if compound != nil {
                    CompoundDetailView(compound: $compound)
                        .environmentObject(viewModel)
                } else {
                    EmptyView()
                }
            case .Solutions:
                EmptyView()
            case .none:
                EmptyView()
            }
        }
        .padding()
    }
}
