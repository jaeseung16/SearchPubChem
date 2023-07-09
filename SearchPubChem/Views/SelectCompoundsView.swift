//
//  CompoundCollectionView.swift
//  SearchPubChem
//
//  Created by Jae Seung Lee on 10/4/21.
//  Copyright © 2021 Jae Seung Lee. All rights reserved.
//

import SwiftUI

struct SelectCompoundsView: View {
    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject private var viewModel: SearchPubChemViewModel
    
    @State var selectedCompounds: [Compound]
    
    private var selectedCompoundsLabel: String {
        var compoundNames = [String]()
        
        for compound in selectedCompounds {
            if let name = compound.name {
                compoundNames.append(name)
            }
        }
        
        return compoundNames.joined(separator: "/")
    }
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                header()
                
                Divider()
                
                Text("Selected compounds")
                
                Text(selectedCompoundsLabel)
                
                ScrollView {
                    LazyVGrid(columns: Array(repeating: GridItem.init(.flexible()), count: 3)) {
                        ForEach(viewModel.allCompounds) { compound in
                            Button {
                                if let index = selectedCompounds.firstIndex(of: compound) {
                                    selectedCompounds.remove(at: index)
                                } else {
                                    selectedCompounds.append(compound)
                                }
                            } label: {
                                VStack {
                                    if let data = compound.image, let uiImage = UIImage(data: data) {
                                        Image(uiImage: uiImage)
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(maxWidth: geometry.size.width * 0.25)
                                    }
                                    
                                    Text(compound.name ?? "")
                                }
                            }
                        }
                    }
                }
            }
            .padding()
        }
    }
    
    private func header() -> some View {
        HStack {
            Button {
                selectedCompounds.removeAll()
                presentationMode.wrappedValue.dismiss()
            } label: {
                Text(Action.Cancel.rawValue)
            }

            Spacer()
            
            Button {
                viewModel.selectedCompounds(selectedCompounds, with: selectedCompoundsLabel)
                presentationMode.wrappedValue.dismiss()
            } label: {
                Text(Action.Done.rawValue)
            }
        }
    }
}

