//
//  ConformerView.swift
//  SearchPubChem
//
//  Created by Jae Seung Lee on 10/16/21.
//  Copyright © 2021 Jae Seung Lee. All rights reserved.
//

import SwiftUI

struct ConformerView: View {
    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject private var viewModel: SearchPubChemViewModel
    
    var conformer: Conformer
    var name: String
    var molecularFormula: String
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                header()
                
                ZStack(alignment: .top) {
                    SceneKitView(conformer: conformer, size: geometry.size)
                        .environmentObject(viewModel)
                        .simultaneousGesture(MagnificationGesture()
                                    .onChanged({ value in
                            print("MagnificationGesture: \(value)")
                            viewModel.pinchGesture(scale: value, isEnded: false)
                        })
                                    .onEnded({ value in
                            print("MagnificationGesture: ended with \(value)")
                            viewModel.pinchGesture(scale: value, isEnded: true)
                        }))
                        .simultaneousGesture(DragGesture()
                                    .onChanged({ value in
                            print("DragGesture: \(value)")
                            viewModel.panGesture(translation: value.translation, isEnded: false)
                        })
                                    .onEnded({ value in
                            print("DragGesture: ended with \(value)")
                            viewModel.panGesture(translation: value.translation, isEnded: true)
                        }))
                        
                    
                    VStack {
                        Text("")
                        Text(molecularFormula)
                        Spacer()
                    }
                }
            }
        }
        .padding()
    }
    
    private func header() -> some View {
        ZStack {
            HStack {
                Spacer()
                
                Text(name)
                    .font(.headline)
                
                Spacer()
            }
            
            HStack {
                Button {
                    viewModel.resetRotation()
                    presentationMode.wrappedValue.dismiss()
                } label: {
                    Text("Back")
                }
                
                Spacer()
            }
        }
    }
}
