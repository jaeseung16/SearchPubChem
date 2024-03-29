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
    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject private var viewModel: SearchPubChemViewModel
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Compound.name, ascending: true)],
        animation: .default)
    private var compounds: FetchedResults<Compound>
    
    var filteredCompounds: Array<Compound> {
        compounds.filter { compound in
            var filter = true
            
            if let tag = selectedTag {
                if let tags = compound.tags {
                    filter = tags.contains(tag)
                } else {
                    filter = false
                }
            }
            return filter
        }
    }
    
    @State private var presentSelectTagView = false
    @State private var presentAddCompoundView = false
    
    
    @State private var selectedTag: CompoundTag?
    
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
                            NavigationLink {
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
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .sheet(isPresented: $presentSelectTagView) {
                    SelectTagsView(selectedTag: $selectedTag)
                }
                .sheet(isPresented: $presentAddCompoundView) {
                    AddCompoundView()
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
