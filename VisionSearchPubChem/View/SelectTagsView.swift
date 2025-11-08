//
//  SelectTagsView.swift
//  VisionSearchPubChem
//
//  Created by Jae Seung Lee on 3/8/24.
//  Copyright © 2024 Jae Seung Lee. All rights reserved.
//

import SwiftUI

struct SelectTagsView: View {
    @EnvironmentObject private var viewModel: VisionSearchPubChemViewModel
    @Environment(\.dismiss) private var dismiss
    
    @Binding var selectedTag: CompoundTag?
    
    var body: some View {
        VStack {
            header()
            
            Divider()
            
            List {
                ForEach(viewModel.allTags) { tag in
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
                .accessibilityIdentifier("resetTagButton")
            }
        }
    }
    
    private func buttonLabel(for tag: CompoundTag) -> some View {
        HStack {
            Text(tag.name ?? "")
            Spacer()
            Text("\(tag.compoundCount)")
        }
        .foregroundColor(.primary)
    }
    
    private func selectedButtonLabel(for tag: CompoundTag) -> some View {
        HStack {
            Text(tag.name ?? "")
            Spacer()
            Text("\(tag.compoundCount)")
        }
        .foregroundColor(.accentColor)
    }
    
}
