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
    
    @Binding var selectedCompound: Compound?
    
    @State private var presentSelectTagView = false
    @State private var presentAddCompoundView = false
    
    var body: some View {
        NavigationSplitView {
            List(compounds, selection: $selectedCompound) { compound in
                NavigationLink(value: compound) {
                    label(for: compound)
                }
                .hoverEffect()
            }
            .navigationTitle("Compounds")
            .toolbar {
                HStack {
                    Spacer()
                    /*
                    Button {
                        presentSelectTagView = true
                    } label: {
                        Image(systemName: "tag")
                    }
                    .accessibilityIdentifier("tagButton")
                    */
                    
                    Button {
                        presentAddCompoundView = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityIdentifier("addCompoundButton")
                }
            }
        } detail: {
            if let selectedCompound {
                CompoundDetailView(compound: selectedCompound)
                    .id(selectedCompound)
            }
        }
        .sheet(isPresented: $presentAddCompoundView) {
            AddCompoundView()
                .environmentObject(viewModel)
        }
        .refreshable {
            compounds = viewModel.allCompounds
        }
        .onChange(of: viewModel.allCompounds) {
            compounds = viewModel.allCompounds
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
