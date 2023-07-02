//
//  CompoundTagView.swift
//  SearchPubChem
//
//  Created by Jae Seung Lee on 10/4/21.
//  Copyright © 2021 Jae Seung Lee. All rights reserved.
//

import SwiftUI

struct CompoundTagView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject private var viewModel: SearchPubChemViewModel
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \CompoundTag.name, ascending: true)],
        animation: .default)
    private var allTags: FetchedResults<CompoundTag>
    
    var compound: Compound
    
    @State var tags: Set<CompoundTag>?
    
    private var tagsAttachedToCompound: [CompoundTag] {
        var tags = [CompoundTag]()
        self.tags?.forEach { tag in
            tags.append(tag)
        }
        return tags
    }
    
    @State private var newTagName: String = ""
    
    var body: some View {
        VStack {
            header()
            
            Divider()
            
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3)) {
                    ForEach(tagsAttachedToCompound) { tag in
                        Button {
                            if tags != nil {
                                tags!.remove(tag)
                            }
                        } label: {
                            Text(tag.name ?? "")
                                .foregroundColor(.primary)
                        }
                    }
                }
            }
            
            HStack {
                TextField("new tag", text: $newTagName)
                
                Spacer()
                
                Button {
                    addTag()
                } label: {
                    Text("Add a new tag")
                }
            }
            
            List {
                ForEach(allTags) { tag in
                    Button {
                        if tags == nil {
                            tags = Set()
                        }
                        
                        if tags!.contains(tag) {
                            tags!.remove(tag)
                        } else {
                            tags!.insert(tag)
                        }
                    } label : {
                        Text(tag.name ?? "")
                    }
                }
                .onDelete(perform: deleteTag)
            }
        }
        .padding()
    }
    
    private func header() -> some View {
        HStack {
            Button {
                presentationMode.wrappedValue.dismiss()
            } label: {
                Text(Action.Dismiss.rawValue)
            }

            Spacer()
            
            Text(compound.name ?? "")
            
            Spacer()
            
            Button {
                updateTags()
                presentationMode.wrappedValue.dismiss()
            } label: {
                Text(Action.Save.rawValue)
            }
        }
    }
    
    private func addTag() {
        if !newTagName.isEmpty {
            let newTag = CompoundTag(context: viewContext)
            newTag.compoundCount = 1
            newTag.name = newTagName
            newTag.addToCompounds(compound)
            
            viewModel.save() { _ in
            }
            
            if tags == nil {
                tags = Set()
            }
            tags!.insert(newTag)
        } else {
            print("New tag is not given")
        }
    }
    
    private func deleteTag(indexSet: IndexSet) {
        for index in indexSet {
            let tag = allTags[index]
            
            if let compounds = tag.compounds {
                tag.removeFromCompounds(compounds)
            }
            
            viewModel.delete(tag)
        }
        
        viewModel.save() { _ in }
    }
    
    private func updateTags() {
        if let tags = compound.tags {
            for tag in tags {
                if let compoundTag = tag as? CompoundTag {
                    compoundTag.compoundCount -= 1
                    compoundTag.removeFromCompounds(compound)
                }
            }
        }
        
        for tag in tagsAttachedToCompound {
            tag.compoundCount += 1
            tag.addToCompounds(compound)
        }
        
        viewModel.save() { _ in
            
        }
    }
}

