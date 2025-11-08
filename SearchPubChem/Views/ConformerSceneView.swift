//
//  ConformerSceneView.swift
//  SearchPubChem
//
//  Created by Jae Seung Lee on 7/7/23.
//  Copyright © 2023 Jae Seung Lee. All rights reserved.
//

import SwiftUI
import SceneKit

struct ConformerSceneView: View {
    @EnvironmentObject private var viewModel: SearchPubChemViewModel
    
    private let nodeName = ConformerSceneHelper.nodeName
    
    @State var scene: SCNScene
    var name: String
    var molecularFormula: String
    
    @State private var transform: SCNMatrix4 = SCNMatrix4Identity
    @State private var reference: SCNMatrix4 = SCNMatrix4Identity
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                SceneView(scene: scene)
                    .simultaneousGesture(
                        MagnificationGesture()
                            .onChanged { value in
                                pinchGesture(scale: value, isEnded: false)
                            }
                            .onEnded { value in
                                pinchGesture(scale: value, isEnded: true)
                            }
                    )
                    .simultaneousGesture(
                        DragGesture()
                            .onChanged{ value in
                                panGesture(translation: value.translation, isEnded: false)
                            }
                            .onEnded { value in
                                panGesture(translation: value.translation, isEnded: true)
                            }
                    )

                VStack {
                    header()
                    
                    Spacer()
                    
                    footer()
                }
                .frame(width: 0.95 * geometry.size.width, height: 0.95 * geometry.size.height)
            }
            
        }
        .padding()
    }
    
    private func header() -> some View {
        HStack {
            Spacer()
            Text(molecularFormula)
                .font(.title)
            Spacer()
        }
    }
    
    private func footer() -> some View {
        HStack {
            Spacer()
            
            Button {
                resetRotation()
            } label: {
                Text(Action.Reset.rawValue)
            }
            .padding(5)
            .glassEffect()
        }
    }
    
    // MARK: - SceneKit
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
        if let geometryNode = scene.rootNode.childNode(withName: nodeName, recursively: false) {
            geometryNode.transform = SCNMatrix4Mult(transform, SCNMatrix4Identity)
        }
    }
    
    private func performRotation() {
        if let geometryNode = scene.rootNode.childNode(withName: nodeName, recursively: false) {
            geometryNode.transform = SCNMatrix4Mult(transform, SCNMatrix4Identity)
        }
    }
    
    private func resetRotation() {
        updateAndTransform(newTransform: SCNMatrix4Identity, newReference: SCNMatrix4Identity)
    }

}
