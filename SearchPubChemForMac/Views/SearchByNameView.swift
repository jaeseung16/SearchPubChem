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
    @Environment(\.managedObjectContext) private var viewContext
    
    @Binding var presenting: Bool
    
    @State private var isEditing = false
    @State var compoundName: String = "water"
    @State var image: NSImage?
    @State var conformer: Conformer?
    @State var geometryNode: SCNNode?
    @State var properties: Properties?
    
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
                ConformerView(geometryNode: geometryNode!)
            }
            
        }
        .padding()
        .toolbar {
            Button(action: {
                self.addCompound()
                self.presenting.toggle()
            })  {
                Label("Download", systemImage: "arrow.down.circle")
            }
        }
    }
    
    private func addCompound() {
        withAnimation {
            guard let properties = self.properties else {
                return
            }
            
            let newCompoundEntity = CompoundEntity(context: viewContext)
            
            newCompoundEntity.name = self.compoundName
            newCompoundEntity.cid = String(properties.CID)
            newCompoundEntity.formula = properties.MolecularFormula
            newCompoundEntity.molecularWeight = properties.MolecularWeight
            newCompoundEntity.nameIUPAC = properties.IUPACName
            
            newCompoundEntity.image = self.image?.tiffRepresentation

            if let conformer = self.conformer {
                let conformerEntity = ConformerEntity(context: self.viewContext)
                conformerEntity.compound = newCompoundEntity
                conformerEntity.conformerId = conformer.conformerId
            
                for atom in conformer.atoms {
                    let atomEntity = AtomEntity(context: self.viewContext)
                    atomEntity.atomicNumber = Int16(atom.number)
                    atomEntity.coordX = atom.location[0]
                    atomEntity.coordY = atom.location[1]
                    atomEntity.coordZ = atom.location[2]
                    atomEntity.conformer = conformerEntity
                }
                
                newCompoundEntity.conformers = NSSet(arrayLiteral: conformerEntity)
            }
            
            do {
                try viewContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
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
                self.properties = compoundProperties
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
                
                self.geometryNode = GeometryGenerator.generate(from: conformer)
                
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
}

struct SearchByNameView_Previews: PreviewProvider {
    @State static var presented = true
    
    static var previews: some View {
        SearchByNameView(presenting: $presented)
    }
}
