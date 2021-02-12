//
//  ConformerView.swift
//  SearchPubChemForMac
//
//  Created by Jae Seung Lee on 2/12/21.
//  Copyright © 2021 Jae Seung Lee. All rights reserved.
//

import SwiftUI
import SceneKit

struct ConformerView: View {
    var geometryNode: SCNNode
    
    @State var rotation: SCNMatrix4 = SCNMatrix4Identity
    
    private var cameraNode: SCNNode {
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3Make(0, 0, 25)
        return cameraNode
    }
    
    private var ambientLightNode: SCNNode {
        let ambientLightNode = SCNNode()
        ambientLightNode.light = SCNLight()
        ambientLightNode.light!.type = SCNLight.LightType.ambient
        ambientLightNode.light!.color = CGColor(gray: 0.67, alpha: 1.0)
        return ambientLightNode
    }
    
    private var omniLightNode: SCNNode {
        let omniLightNode = SCNNode()
        omniLightNode.light = SCNLight()
        omniLightNode.light!.type = SCNLight.LightType.omni
        omniLightNode.light!.color = CGColor(gray: 0.75, alpha: 1.0)
        omniLightNode.position = SCNVector3Make(0, 50, 50)
        return omniLightNode
    }
    
    private var scene: SCNScene {
        let scene = SCNScene()
        scene.background.contents = NSColor.systemGray
        scene.rootNode.addChildNode(ambientLightNode)
        scene.rootNode.addChildNode(omniLightNode)
        scene.rootNode.addChildNode(geometryNode)
        return scene
    }
    
    var body: some View {
        SceneView(scene: scene, pointOfView: cameraNode, options: [])
            .frame(width: 250, height: 250, alignment: .center)
            .gesture(panGesture)
            .gesture(pinchGesture)
    }
    
    private var pinchGesture: some Gesture {
        MagnificationGesture()
            .onChanged { scale in
                let newScale: SCNMatrix4 = SCNMatrix4MakeScale(scale, scale, scale)
                geometryNode.transform = SCNMatrix4Mult(newScale, self.rotation)
            }
            .onEnded { (scale) in
                let newScale: SCNMatrix4 = SCNMatrix4MakeScale(scale, scale, scale)
                self.rotation = SCNMatrix4Mult(newScale, self.rotation)
            }
    }
    
    private var panGesture: some Gesture {
        DragGesture()
            .onChanged { (value) in
                let translation = value.translation
                let newRotation = coordinateTransform(for: makeRotation(from: translation), with: self.rotation)
                geometryNode.transform = SCNMatrix4Mult(newRotation, self.rotation)
            }
            .onEnded { (value) in
                let translation = value.translation
                let newRotation = coordinateTransform(for: makeRotation(from: translation), with: self.rotation)
                self.rotation = SCNMatrix4Mult(newRotation, self.rotation)
            }
    }
    
    private func makeRotation(from translation: CGSize) -> SCNMatrix4 {
        let length = sqrt( translation.width * translation.width + translation.height * translation.height )
        let angle = CGFloat(length) * .pi / 180.0
        let rotationAxis = [CGFloat](arrayLiteral: translation.height / length, translation.width / length)
        let rotation: SCNMatrix4 = SCNMatrix4MakeRotation(angle, CGFloat(rotationAxis[0]), CGFloat(rotationAxis[1]), 0.0)
        return rotation
    }
    
    private func coordinateTransform(for rotation: SCNMatrix4, with reference: SCNMatrix4) -> SCNMatrix4 {
        let inverseOfReference = SCNMatrix4Invert(reference)
        let transformed = SCNMatrix4Mult(reference, SCNMatrix4Mult(rotation, inverseOfReference))
        return transformed
    }
    
}

struct ConformerView_Previews: PreviewProvider {
    static var previews: some View {
        ConformerView(geometryNode: SCNNode())
    }
}