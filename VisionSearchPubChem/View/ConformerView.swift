//
//  ConformerView.swift
//  VisionSearchPubChem
//
//  Created by Jae Seung Lee on 2/28/24.
//  Copyright © 2024 Jae Seung Lee. All rights reserved.
//

import SwiftUI
import RealityKit

struct ConformerView: View {
    @EnvironmentObject private var viewModel: VisionSearchPubChemViewModel
    
    @Binding var compound: Compound?
    
    @State private var entity: Entity?
    
    var body: some View {
        GeometryReader3D { geometry in
            RealityView { content in
                guard let conformer else {
                    return
                }
                
                let maxLocation = conformer.atoms.compactMap {
                    $0.location.map { abs($0) }
                        .max()
                }.max()
                
                guard let maxLocation else {
                    return
                }
                
                let bounds = content.convert(geometry.frame(in: .local), from: .local, to: content)
                
                let scale = bounds.extents.min() / Float(3 * maxLocation)
                
                let boxMeshResource = MeshResource.generateBox(size: bounds.extents.min())
                let boxShapeResource = ShapeResource.generateBox(size: bounds.extents)
                let boxEntity = ModelEntity(mesh: boxMeshResource, materials: [UnlitMaterial(color: .clear)], collisionShape: boxShapeResource, mass: 0.0)
                
                for atom in conformer.atoms {
                    guard let element = Elements(rawValue: atom.number) else {
                        print("No such element: atomic number = \(atom.number)")
                        return
                    }

                    let radius = element.getVanDerWaalsRadius() > 0 ? element.getVanDerWaalsRadius() : element.getCovalentRadius()
                    
                    let sphereMeshResource = MeshResource.generateSphere(radius: Float(radius) * scale / 200.0)
                    let sphereEntity = ModelEntity(mesh: sphereMeshResource, materials: [SimpleMaterial(color: element.getColor(), roughness: 0, isMetallic: false)])
                    let location = atom.location.map { Float($0) * scale }
                    sphereEntity.position = SIMD3<Float>(x: location[0], y: location[1], z: location[2])
                    //sphereEntity.components[OpacityComponent.self] = .init(opacity: 1.0)
                    sphereEntity.setParent(boxEntity)
                }
                
                content.add(boxEntity)
                
                entity = boxEntity
                
            } update: { content in
                
            } placeholder: {
                ProgressView()
            }
            .hoverEffect()
            .dragRotation(yawLimit: .degrees(20), pitchLimit: .degrees(20))
        }
        
        
    }
    
    private var conformer: Conformer? {
        guard let compound, compound.conformerDownloaded else {
            return nil
        }
        
        if let conformers = compound.conformers, conformers.count > 0 {
            for conformerEntity in conformers {
                if let entity = conformerEntity as? ConformerEntity {
                    var atoms = [AtomEntity]()
                    entity.atoms?.forEach({ atom in
                        if let atom = atom as? AtomEntity {
                            atoms.append(atom)
                        }
                    })
                    
                    return Conformer(cid: compound.cid ?? "", conformerEntity: entity, atomEntities: atoms)
                }
            }
        }
        return nil
    }
}
