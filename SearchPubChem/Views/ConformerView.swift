//
//  ConformerView.swift
//  SearchPubChem
//
//  Created by Jae Seung Lee on 10/16/21.
//  Copyright © 2021 Jae Seung Lee. All rights reserved.
//

import SwiftUI
import SceneKit

struct ConformerView: View {
    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject private var viewModel: SearchPubChemViewModel
    
    @State var scene: SCNScene
    var name: String
    var molecularFormula: String
    
    @State private var transform: SCNMatrix4 = SCNMatrix4Identity
    @State private var reference: SCNMatrix4 = SCNMatrix4Identity
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                header()
                
                ZStack(alignment: .top) {
                    SceneKitView(scene: scene, size: geometry.size)
                        .simultaneousGesture(
                            MagnificationGesture()
                                .onChanged { value in
                                    pinchGesture(scale: value, isEnded: false)
                                }
                                .onEnded { value in
                                    pinchGesture(scale: value, isEnded: true)
                                })
                        .simultaneousGesture(
                            DragGesture()
                                .onChanged{ value in
                                    panGesture(translation: value.translation, isEnded: false)
                                }
                                .onEnded { value in
                                    panGesture(translation: value.translation, isEnded: true)
                                })
                    
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
                    Text(Action.Dismiss.rawValue)
                }
                
                Spacer()
                
                Button {
                    resetRotation()
                } label: {
                    Text(Action.Reset.rawValue)
                }
            }
        }
    }
    
    private func panGesture(translation: CGSize, isEnded: Bool) {
        viewModel.panGesture(translation: translation, reference: reference, isEnded: isEnded) { newTransform, newReference in
            self.updateAndTransform(newTransform: newTransform, newReference: newReference)
        }
    }
    
    private func pinchGesture(scale: CGFloat, isEnded: Bool) {
        viewModel.pinchGesture(scale: scale, reference: self.reference, isEnded: isEnded) { newTransform, newReference in
            self.updateAndTransform(newTransform: newTransform, newReference: newReference)
        }
    }
    
    private func updateAndTransform(newTransform: SCNMatrix4, newReference: SCNMatrix4) {
        transform = newTransform
        reference = newReference
        if let geometryNode = scene.rootNode.childNode(withName: ConformerSceneHelper.nodeName, recursively: false) {
            geometryNode.transform = SCNMatrix4Mult(transform, SCNMatrix4Identity)
        }
    }
    
    private func resetRotation() {
        updateAndTransform(newTransform: SCNMatrix4Identity, newReference: SCNMatrix4Identity)
    }
}
