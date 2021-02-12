//
//  SearchByNameForMac.swift
//  SearchPubChemForMac
//
//  Created by Jae Seung Lee on 2/9/21.
//  Copyright © 2021 Jae Seung Lee. All rights reserved.
//

import SwiftUI
import SceneKit

struct SearchByNameView: View {
    @State var compoundName: String = "water"
    @State private var isEditing = false
    @State var image: NSImage?
    @State var conformer: Conformer?
    @Binding var presenting: Bool
    
    @State var geometryNode: SCNNode?
    
    static let client = PubChemSearch()
    static let networkErrorString = "The Internet connection appears to be offline"
    
    var body: some View {
        VStack {
            Text("Compound Name")
            
            TextField("water", text: $compoundName) { isEditing in
                self.isEditing = isEditing
            }
            .multilineTextAlignment(.center)
           
            Button(action: { searchByName() }) {
                Label("Search", systemImage: "magnifyingglass")
            }
            
            if (image != nil) {
                Image(nsImage: image!)
            }
            
            if (geometryNode != nil) {
                SceneView(scene: scene, pointOfView: cameraNode, options: [])
                    .frame(width: 250, height: 250, alignment: .center)
                    .gesture(panGesture)
                    .gesture(pinchGesture)
            }
            
        }
        .padding()
        .toolbar {
            Button(action: { self.presenting.toggle() })  {
                Label("Download", systemImage: "arrow.down.circle")
            }
        }
    }
    
    @GestureState var magnifyBy = CGFloat(1.0)
    //@State var currentScale = CGFloat(1.0)
    @State var rotation: SCNMatrix4 = SCNMatrix4Identity
    
    private var pinchGesture: some Gesture {
        MagnificationGesture()
            //.updating($magnifyBy) { currentState, gestureState, transaction in
            //    gestureState = currentState
            //    print("magnifyBy = \(magnifyBy)")
            //}
            .onChanged { scale in
                let newScale: SCNMatrix4 = SCNMatrix4MakeScale(scale, scale, scale)
                geometryNode!.transform = SCNMatrix4Mult(newScale, self.rotation)
            }
            .onEnded { (scale) in
                //currentScale *= scale
                
                let newScale: SCNMatrix4 = SCNMatrix4MakeScale(scale, scale, scale)
                self.rotation = SCNMatrix4Mult(newScale, self.rotation)
            }
        /*
        let scale = Float(sender.scale)
        let newScale = SCNMatrix4MakeScale(scale, scale, scale)
        geometryNode.transform = SCNMatrix4Mult(newScale, self.rotation)
        
        if (sender.state == UIGestureRecognizer.State.ended) {
            self.rotation = SCNMatrix4Mult(newScale, self.rotation)
        }
        */
    }
    
    private var panGesture: some Gesture {
        DragGesture()
            .onChanged { (value) in
                let translation = value.translation
                let newRotation = coordinateTransform(for: makeRotation(from: translation), with: self.rotation)
                geometryNode!.transform = SCNMatrix4Mult(newRotation, self.rotation)
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
    
    private func searchByName() -> Void {
        let name = compoundName
        
        // showNetworkIndicators(true)
        
        SearchByNameView.client.searchCompound(name: name) { (success, compoundProperties, errorString) in
            //self.showNetworkIndicators(false)
            
            if success {
                guard let compoundProperties = compoundProperties else {
                    NSLog("There is no infromation for a compound")
                    return
                }

                print("\(compoundProperties)")
                
                self.downloadImage(for: String(compoundProperties.CID))
                self.download3DData(for: name, cid: String(compoundProperties.CID))
                
                /*
                DispatchQueue.main.async {
                    self.formulaLabel.text = compoundProperties.MolecularFormula
                    self.weightLabel.text = String(compoundProperties.MolecularWeight)
                    self.cidLabel.text = String(compoundProperties.CID)
                    self.iupacNameLabel.text = compoundProperties.IUPACName
                    
                    self.hideLabels(false)
                    self.showNetworkIndicators(true)
                    
                    self.downloadImage(for: self.cidLabel.text!)
                    self.download3DData(for: name)
                }
                */
            } else {
                guard let errorString = errorString, errorString.contains(SearchByNameView.networkErrorString) else {
                    let errorString = "There is no compound matching the name \'\(name)\'"
                    
                    print(errorString)
                    //self.presentAlert(title: "Search Failed", message: errorString)
                    return
                }
                
                print("Search Failed")
                //self.presentAlert(title: "Search Failed", message: self.networkErrorString)
            }
        }
    }
    
    private func downloadImage(for cid: String) {
        SearchByNameView.client.downloadImage(for: cid, completionHandler: { (success, data, errorString) in
            if success {
                self.image = NSImage(data: data! as Data)
                
                /*
                DispatchQueue.main.async {
                    self.compoundImageView.image = UIImage(data: data! as Data)
                    self.enableSaveButton(true)
                }
                */
            } else {
                guard let errorString = errorString, errorString.contains(SearchByNameView.networkErrorString) else {
                    let errorString = "Failed to download the molecular structure for \'\(cid)\'"
                    print(errorString)
                    //self.presentAlert(title: "No Image", message: errorString)
                    return
                }
                print("No Image")
                //self.presentAlert(title: "No Image", message: self.networkErrorString)
            }
        })
    }
    
    private func download3DData(for name: String, cid: String) {
        SearchByNameView.client.download3DData(for: cid, completionHandler: { (success, conformer, errorString) in
            //self.showNetworkIndicators(false)
            
            if success, let conformer = conformer {
                self.conformer = conformer
                print("conformer: \(String(describing: conformer))")
                
                self.geometryNode = createSCNNode(for: self.conformer!)
                
                /*
                DispatchQueue.main.async {
                    self.conformer = conformer
                    print("\(String(describing: self.conformer))")
                }
                 */
            } else {
                guard let errorString = errorString, errorString.contains(SearchByNameView.networkErrorString) else {
                    let errorString = "Failed to download 3d data for \'\(name)\'"
                    print(errorString)
                    //self.presentAlert(title: "No 3D Data", message: errorString)
                    return
                }
                print("No 3D Data")
                //self.presentAlert(title: "No 3D Data", message: errorString)
            }
        })
    }
    
    private var scene: SCNScene {
        let scene = SCNScene()

        let ambientLightNode = SCNNode()
        ambientLightNode.light = SCNLight()
        ambientLightNode.light!.type = SCNLight.LightType.ambient
        ambientLightNode.light!.color = CGColor(gray: 0.67, alpha: 1.0)
        scene.rootNode.addChildNode(ambientLightNode)
        
        let omniLightNode = SCNNode()
        omniLightNode.light = SCNLight()
        omniLightNode.light!.type = SCNLight.LightType.omni
        omniLightNode.light!.color = CGColor(gray: 0.75, alpha: 1.0)
        omniLightNode.position = SCNVector3Make(0, 50, 50)
        scene.rootNode.addChildNode(omniLightNode)
        
        scene.rootNode.addChildNode(geometryNode!)
        
        return scene
    }
    
    private var cameraNode: SCNNode {
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3Make(0, 0, 25)
        //scene.rootNode.addChildNode(cameraNode)
        return cameraNode
    }
    
    private func createSCNNode(for conformer: Conformer) -> SCNNode {
        let atomsNode = SCNNode()
        
        for atom in conformer.atoms {
            let atomNode = SCNNode(geometry: createSCNNode(for: atom))
            atomNode.position = SCNVector3Make(CGFloat(Float(atom.location[0])), CGFloat(atom.location[1]), CGFloat(atom.location[2]))
            atomsNode.addChildNode(atomNode)
        }
        return atomsNode
    }
    
    private func createSCNNode(for atom: Atom) -> SCNGeometry {
        guard let element = Elements(rawValue: atom.number) else {
            print("No such element: atomic number = \(atom.number)")
            return SCNGeometry()
        }

        let radius = element.getVanDerWaalsRadius() > 0 ? element.getVanDerWaalsRadius() : element.getCovalentRadius()
        
        let atomNode = SCNSphere(radius: CGFloat(radius) / 200.0)
        atomNode.firstMaterial?.diffuse.contents = NSColor(element.getColor())
        atomNode.firstMaterial?.specular.contents = NSColor.white
        
        return atomNode
    }
}

struct SearchByNameView_Previews: PreviewProvider {
    @State static var presented = true
    
    static var previews: some View {
        SearchByNameView(presenting: $presented)
    }
}
