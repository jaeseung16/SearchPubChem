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
    @EnvironmentObject private var viewModel: SearchPubChemViewModel
    @Environment(\.dismiss) private var dismiss
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \CompoundTag.name, ascending: true)],
        animation: .default)
    private var tags: FetchedResults<CompoundTag>
    
    @Binding var selectedTag: CompoundTag?
    
    var body: some View {
        VStack {
            header()
            
            Divider()
            
            List {
                ForEach(tags) { tag in
                    Button {
                        selectedTag = tag
                        dismiss.callAsFunction()
                    } label: {
                        if selectedTag != nil && tag == selectedTag {
                            selectedButtonLabel(for: tag)
                        } else {
                            buttonLabel(for: tag)
                                .foregroundColor(.primary)
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
                Spacer()
                
                Button {
                    selectedTag = nil
                    dismiss.callAsFunction()
                } label: {
                    Text(Action.Reset.rawValue)
                }
            }
        }
    }
    
    private func buttonLabel(for tag: CompoundTag) -> some View {
        HStack {
            Text(tag.name ?? "")
            Spacer()
            Label("\(tag.compoundCount)", image: TabItem.Compounds.defaultImageName)
                .labelStyle(CaptionLabelStyle())
        }
    }
    
    private func selectedButtonLabel(for tag: CompoundTag) -> some View {
        HStack {
            Text(tag.name ?? "")
            Spacer()
            Label("\(tag.compoundCount)", image: TabItem.Compounds.selectedImageName)
                .labelStyle(CaptionLabelStyle())
        }
    }
}

struct CaptionLabelStyle : LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.title
            configuration.icon
                .scaleEffect(0.6, anchor: .center)
                .frame(width: 25, height: 25, alignment: .center)
        }
        .font(.caption)
    }
}
