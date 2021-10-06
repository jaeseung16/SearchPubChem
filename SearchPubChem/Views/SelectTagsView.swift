//
//  SelectTagsView.swift
//  SearchPubChem
//
//  Created by Jae Seung Lee on 10/5/21.
//  Copyright © 2021 Jae Seung Lee. All rights reserved.
//

import SwiftUI

struct SelectTagsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) private var presentationMode
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \CompoundTag.name, ascending: true)],
        animation: .default)
    private var tags: FetchedResults<CompoundTag>
    
    @Binding var selectedTag: CompoundTag?
    
    var body: some View {
        VStack {
            header()
            
            Divider()
            
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3)) {
                    ForEach(tags) { tag in
                        Button {
                            selectedTag = tag
                            presentationMode.wrappedValue.dismiss()
                        } label: {
                            VStack {
                                Text(tag.name ?? "")
                                Text("\(tag.compoundCount)")
                            }
                        }
                    }
                }
            }
        }
        .padding()
    }
    
    private func header() -> some View {
        ZStack {
            Text("Select Tags")
            
            HStack {
                Button {
                    presentationMode.wrappedValue.dismiss()
                } label: {
                    Text("Cancel")
                }

                Spacer()
                
                Button {
                    selectedTag = nil
                    presentationMode.wrappedValue.dismiss()
                } label: {
                    Text("Reset")
                }
            }
        }
    }
}

