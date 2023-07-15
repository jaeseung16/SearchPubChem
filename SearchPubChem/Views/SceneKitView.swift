//
//  SceneKitView.swift
//  SearchPubChem
//
//  Created by Jae Seung Lee on 10/16/21.
//  Copyright © 2021 Jae Seung Lee. All rights reserved.
//

import SwiftUI
import SceneKit

struct SceneKitView: UIViewRepresentable {
    @EnvironmentObject private var viewModel: SearchPubChemViewModel
    
    private let nodeName = "geometryNode"
    
    var scene: SCNScene
    var size: CGSize

    func makeUIView(context: Context) -> SCNView {
        let scnView = SCNView(frame: CGRect(origin: CGPoint(x: 0,y: 0), size: self.size))
        scnView.scene = scene
        return scnView
    }
    
    func updateUIView(_ uiView: SCNView, context: Context) {
        if let geometryNode =  uiView.scene?.rootNode.childNode(withName: nodeName, recursively: false) {
            geometryNode.transform = SCNMatrix4Mult(viewModel.rotation, SCNMatrix4Identity)
        }
    }
}
