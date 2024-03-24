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
    @State private var selectedTag: CompoundTag?
    
    @State private var presentSelectTagView = false
    @State private var presentAddCompoundView = false
    
    private var navigationTitle: String {
        if let tag = selectedTag, let name = tag.name {
            return name.localizedCapitalized
        } else {
            return "Compounds"
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            List(compounds, selection: $selectedCompound) { compound in
                NavigationLink(value: compound) {
                    label(for: compound)
                }
                .hoverEffect()
            }
            .navigationTitle(navigationTitle)
            .toolbar {
                ToolbarItem(placement: .bottomOrnament) {
                    Button {
                        presentSelectTagView = true
                    } label: {
                        Image(systemName: "tag")
                    }
                    .accessibilityIdentifier("tagButton")
                }
                
                ToolbarItem(placement: .bottomOrnament) {
                    Button {
                        presentAddCompoundView = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityIdentifier("addCompoundButton")
                }
            }
            .sheet(isPresented: $presentSelectTagView) {
                SelectTagsView(selectedTag: $selectedTag)
                    .environmentObject(viewModel)
                    .frame(minWidth: geometry.size.width, minHeight: geometry.size.height)
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
            .onChange(of: selectedTag) {
                compounds = getTagged(compounds: viewModel.allCompounds)
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
    
    private func getTagged(compounds: [Compound]) -> [Compound] {
        compounds.filter { compound in
            selectedTag == nil || compound.isTagged(by: selectedTag!)
        }
    }
}
