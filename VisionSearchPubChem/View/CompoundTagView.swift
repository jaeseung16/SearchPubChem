//
//  CompoundTagView.swift
//  VisionSearchPubChem
//
//  Created by Jae Seung Lee on 3/4/24.
//  Copyright © 2024 Jae Seung Lee. All rights reserved.
//

import SwiftUI

struct CompoundTagView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var viewModel: VisionSearchPubChemViewModel
    
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
                .disabled(newTagName.isEmpty)
            }
            
            List {
                ForEach(viewModel.allTags) { tag in
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
                dismiss.callAsFunction()
            } label: {
                Text(Action.Dismiss.rawValue)
            }

            Spacer()
            
            Text(compound.name ?? "")
            
            Spacer()
            
            Button {
                updateTags()
                dismiss.callAsFunction()
            } label: {
                Text(Action.Save.rawValue)
            }
        }
    }
    
    private func addTag() {
        if !newTagName.isEmpty {
            viewModel.saveTag(name: newTagName, compound: compound) { tag in
                if tags == nil {
                    tags = Set()
                }
                tags!.insert(tag)
            }
        }
    }
    
    private func deleteTag(indexSet: IndexSet) {
        viewModel.deleteTags(indexSet)
    }
    
    private func updateTags() {
        viewModel.update(compound: compound, newTags: tagsAttachedToCompound)
    }
}
