//
//  SelectCompoundsView.swift
//  VisionSearchPubChem
//
//  Created by Jae Seung Lee on 3/13/24.
//  Copyright © 2024 Jae Seung Lee. All rights reserved.
//

import SwiftUI

struct SelectCompoundsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var viewModel: VisionSearchPubChemViewModel
    
    @State var selectedCompounds: [Compound]
    
    private var selectedCompoundsLabel: String {
        return selectedCompounds.compactMap { $0.name }
            .joined(separator: "/")
    }
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                header()
                
                Divider()
                
                Text("Selected compounds")
                
                Text(selectedCompoundsLabel)
                
                ScrollView {
                    LazyVGrid(columns: Array(repeating: .init(.fixed(geometry.size.width * 0.3)), count: 3)) {
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
                                    }
                                    
                                    Text(compound.name ?? "")
                                }
                                .padding(5.0)
                            }
                            .buttonBorderShape(.roundedRectangle(radius: 10.0))
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
                dismiss.callAsFunction()
            } label: {
                Text(Action.Cancel.rawValue)
            }

            Spacer()
            
            Button {
                viewModel.selectedCompounds(selectedCompounds, with: selectedCompoundsLabel)
                dismiss.callAsFunction()
            } label: {
                Text(Action.Done.rawValue)
            }
        }
    }
}

