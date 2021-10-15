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
                Text("Dismiss")
            }

            Spacer()
            
            Text(compound.name ?? "")
            
            Spacer()
            
            Button {
                updateTags()
                presentationMode.wrappedValue.dismiss()
            } label: {
                Text("Save")
            }
        }
    }
    
    private func addTag() {
        if !newTagName.isEmpty {
            let newTag = CompoundTag(context: viewContext)
            newTag.compoundCount = 1
            newTag.name = newTagName
            
            //tagsAttachedToCompound.insert(newTag)
            //setTagsLabel()
            
            if let tags = compound.tags, tags.count > 0 {
                tags.adding(newTag)
            } else {
                compound.tags = NSSet(arrayLiteral: newTag)
            }
            
            do {
                try viewContext.save()
            } catch {
                NSLog("Error while saving in iPadCompoundTagViewController.addNewTag(:)")
            }
        } else {
            print("New tag is not given")
        }
    }
    
    private func deleteTag(indexSet: IndexSet) {
        for index in indexSet {
            let tag = allTags[index]
            viewContext.delete(tag)
        }
        
        do {
            try viewContext.save()
            NSLog("Saved in iPadCompoundTagViewController.deleteTags(:)")
        } catch {
            NSLog("Error while saving in iPadCompoundTagViewController.deleteTags(:)")
        }
    }
    
    private func updateTags() {
        if let tags = compound.tags {
            for tag in tags {
                if let compoundTag = tag as? CompoundTag {
                    compoundTag.compoundCount -= 1
                }
            }
        }
        
        for tag in tagsAttachedToCompound {
            tag.compoundCount += 1
        }
        
        compound.tags = NSSet(array: tagsAttachedToCompound)
        
        do {
            try viewContext.save()
        } catch {
            NSLog("Error while saving in iPadCompoundTagViewController.addNewTag(:)")
        }
    }
}

