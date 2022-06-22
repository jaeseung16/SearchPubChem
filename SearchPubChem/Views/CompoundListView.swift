//
//  CompoundListView.swift
//  SearchPubChem
//
//  Created by Jae Seung Lee on 10/3/21.
//  Copyright © 2021 Jae Seung Lee. All rights reserved.
//

import SwiftUI

struct CompoundListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var viewModel: SearchPubChemViewModel
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Compound.name, ascending: true)],
        animation: .default)
    private var compounds: FetchedResults<Compound>
    
    var filteredCompounds: Array<Compound> {
        compounds.filter { compound in
            
            return isTagged(compound: compound) && nameContainsSearchString(compound: compound)
        }
    }
    
    private func isTagged(compound: Compound) -> Bool {
        return selectedTag == nil || compound.isTagged(by: selectedTag!)
    }
    
    private func nameContainsSearchString(compound: Compound) -> Bool {
        return viewModel.selectedCompoundName.isEmpty || compound.nameContains(string: viewModel.selectedCompoundName)
    }
    
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
                    List {
                        ForEach(filteredCompounds) { compound in
                            NavigationLink(tag: compound.cid ?? "", selection: $selectedCid) {
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
            
            Button {
                presentAddCompoundView = true
            } label: {
                Image(systemName: "plus")
            }
        }
    }
}

struct CompoundListView_Previews: PreviewProvider {
    static var previews: some View {
        CompoundListView()
    }
}
