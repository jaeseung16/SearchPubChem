//
//  GeometryTransfomer.swift
//  SearchPubChemForMac
//
//  Created by Jae Seung Lee on 2/12/21.
//  Copyright © 2021 Jae Seung Lee. All rights reserved.
//

import Foundation
import SceneKit

class GeometryTransformer {
    static func makeCoordinateTransfrom(translation: CGSize, reference: SCNMatrix4) -> SCNMatrix4 {
        let rotation = makeRotation(from: translation)
        return makeCoordinateTransform(rotation: rotation, reference: reference)
    }
    
    static func makeCoordinateTransform(rotation: SCNMatrix4, reference: SCNMatrix4) -> SCNMatrix4 {
        let inverseOfReference = SCNMatrix4Invert(reference)
        let transformed = SCNMatrix4Mult(reference, SCNMatrix4Mult(rotation, inverseOfReference))
        return transformed
    }
    
    static func makeRotation(from translation: CGSize) -> SCNMatrix4 {
        let length = sqrt(translation.width * translation.width + translation.height * translation.height)
        let angle = length * .pi / 180.0
        let rotationAxis = [CGFloat](arrayLiteral: translation.height / length, translation.width / length)
        let rotation: SCNMatrix4 = SCNMatrix4MakeRotation(angle, rotationAxis[0], rotationAxis[1], 0.0)
        return rotation
    }
}
