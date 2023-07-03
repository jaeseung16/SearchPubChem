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
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var viewModel: SearchPubChemViewModel
    
    @State var compounds: [Compound]
    
    @State private var presentSelectTagView = false
    @State private var presentAddCompoundView = false
    
    @State private var selectedTag: CompoundTag?
    @State private var selectedCid: String?
    
    private var navigationTitle: String {
        if let tag = selectedTag, let name = tag.name {
            return name.localizedCapitalized
        } else {
            return TabItem.Compounds.rawValue
        }
    }
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                VStack {
                    List(selection: $selectedCid) {
                        ForEach(compounds, id: \.id) { compound in
                            NavigationLink() {
                                CompoundDetailView(compound: compound)
                            } label: {
                                label(for: compound)
                            }
                        }
                    }
                    .navigationTitle(navigationTitle)
                    .toolbar {
                        toolBarContent()
                    }
                    .searchable(text: $viewModel.selectedCompoundName)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .sheet(isPresented: $presentSelectTagView) {
                    SelectTagsView(selectedTag: $selectedTag)
                        .environment(\.managedObjectContext, viewContext)
                        .environmentObject(viewModel)
                }
                .sheet(isPresented: $presentAddCompoundView) {
                    AddCompoundView()
                        .environment(\.managedObjectContext, viewContext)
                        .environmentObject(viewModel)
                }
                .onChange(of: viewModel.receivedURL) { _ in
                    if !viewModel.selectedCid.isEmpty {
                        selectedCid = viewModel.selectedCid
                    }
                }
                .onContinueUserActivity(CSSearchableItemActionType) { activity in
                    viewModel.continueActivity(activity) { cid in
                        selectedCid = cid
                    }
                }
                .onChange(of: viewModel.allCompounds) { newValue in
                    compounds = getTagged(compounds: newValue)
                }
                .onChange(of: viewModel.selectedCompoundName) { newValue in
                    let selectedCompounds = viewModel.searchCompounds(nameContaining: newValue)
                    compounds = getTagged(compounds: selectedCompounds)
                }
                .onChange(of: selectedTag) { newValue in
                    let selectedCompounds = viewModel.searchCompounds(nameContaining: viewModel.selectedCompoundName)
                    compounds = getTagged(compounds: selectedCompounds)
                }
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
    
    private func toolBarContent() -> some View {
        HStack {
            Spacer()
            
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
            .accessibilityIdentifier("addButton")
        }
    }
    
    private func getTagged(compounds: [Compound]) -> [Compound] {
        compounds.filter { compound in
            selectedTag == nil || compound.isTagged(by: selectedTag!)
        }
    }
}

