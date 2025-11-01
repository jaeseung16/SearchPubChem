//
//  CompoundListView.swift
//  SearchPubChem
//
//  Created by Jae Seung Lee on 10/3/21.
//  Copyright © 2021 Jae Seung Lee. All rights reserved.
//

import SwiftUI
import CoreSpotlight

struct CompoundListView: View {
    @EnvironmentObject private var viewModel: SearchPubChemViewModel
    
    @State var compounds: [Compound]
    
    @State private var presentSelectTagView = false
    @State private var presentAddCompoundView = false
    
    @State private var selectedTag: CompoundTag?
    @State private var selectedCid: String?
    @State private var selectedCompound: Compound?
    
    private var navigationTitle: String {
        if let tag = selectedTag, let name = tag.name {
            return name.localizedCapitalized
        } else {
            return TabItem.Compounds.rawValue
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            NavigationSplitView {
                List(selection: $selectedCompound) {
                    ForEach(compounds) { compound in
                        NavigationLink(value: compound) {
                            label(for: compound)
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .navigationTitle(navigationTitle)
                .toolbar {
                    ToolbarItemGroup {
                        Button {
                            presentSelectTagView = true
                        } label: {
                            Image(systemName: "tag")
                        }
                        .accessibilityIdentifier("tagButton")
                        
                        Button {
                            presentAddCompoundView = true
                        } label: {
                            Image(systemName: "plus")
                        }
                        .accessibilityIdentifier("addCompoundButton")
                    }
                }
                .searchable(text: $viewModel.selectedCompoundName)
            } detail: {
                if let selectedCompound {
                    NavigationStack {
                        CompoundDetailView(compound: selectedCompound)
                            .id(selectedCompound)
                    }
                } else {
                    EmptyView()
                }
            }
            .sheet(isPresented: $presentSelectTagView) {
                SelectTagsView(selectedTag: $selectedTag)
                    .environmentObject(viewModel)
            }
            .sheet(isPresented: $presentAddCompoundView) {
                AddCompoundView()
                    .environmentObject(viewModel)
            }
            .onChange(of: viewModel.receivedURL) {
                if !viewModel.selectedCid.isEmpty {
                    selectedCid = viewModel.selectedCid
                }
            }
            .onContinueUserActivity(CSSearchableItemActionType) { activity in
                viewModel.continueActivity(activity) { compound in
                    selectedCid = compound.id
                    if let name = compound.name {
                        viewModel.selectedCompoundName = name
                    }
                }
            }
            .onChange(of: viewModel.allCompounds) { _, newValue in
                compounds = getTagged(compounds: newValue)
            }
            .onChange(of: viewModel.selectedCompoundName) { _, newValue in
                let selectedCompounds = viewModel.searchCompounds(nameContaining: newValue)
                compounds = getTagged(compounds: selectedCompounds)
            }
            .onChange(of: selectedTag) { _, newValue in
                let selectedCompounds = viewModel.searchCompounds(nameContaining: viewModel.selectedCompoundName)
                compounds = getTagged(compounds: selectedCompounds)
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

