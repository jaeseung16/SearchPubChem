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
    
    @State private var totalRotation3D = Rotation3D.identity
    @State private var rotationAxis = RotationAxis3D(x: 0, y: 0, z: 0)
    @State private var rotationAngle = Angle.zero
    
    var body: some View {
        GeometryReader3D { geometry in
            ZStack(alignment: .bottom) {
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
                    
                    let scale = bounds.extents.min() / Float(3 * (maxLocation + 1.0))
                    
                    let boxMeshResource = MeshResource.generateBox(size: bounds.extents.min())
                    let boxShapeResource = ShapeResource.generateBox(size: bounds.extents)
                    let boxEntity = ModelEntity(mesh: boxMeshResource, materials: [UnlitMaterial(color: .clear)], collisionShape: boxShapeResource, mass: 0.0)
                    boxEntity.name = "\(conformer.cid): \(conformer.conformerId)"
                    
                    for atom in conformer.atoms {
                        guard let element = Elements(rawValue: atom.number) else {
                            print("No such element: atomic number = \(atom.number)")
                            return
                        }

                        let radius = element.getVanDerWaalsRadius() > 0 ? element.getVanDerWaalsRadius() : element.getCovalentRadius()
                        let location = atom.location.map { Float($0) * scale }
                        
                        let sphereMeshResource = MeshResource.generateSphere(radius: Float(radius) * scale / 200.0)
                        let sphereEntity = ModelEntity(mesh: sphereMeshResource, materials: [SimpleMaterial(color: element.getColor(), roughness: 0, isMetallic: false)])
                        sphereEntity.name = atom.description
                        sphereEntity.position = SIMD3<Float>(x: location[0], y: location[1], z: location[2])
                        sphereEntity.generateCollisionShapes(recursive: false)
                        sphereEntity.components[InputTargetComponent.self] = .init()
                        sphereEntity.setParent(boxEntity)
                    }
                    
                    content.add(boxEntity)
                    
                    entity = boxEntity
                } update: { content in
                    
                } placeholder: {
                    ProgressView()
                }
                .rotation3DEffect(rotationAngle, axis: rotationAxis)
                
                Text("\(compound?.name ?? "")")
                    .font(.extraLargeTitle)
                    .offset(y: -20)
            }
            .gesture(
                DragGesture()
                    .targetedToAnyEntity()
                    .onChanged{ value in
                        rotate(by: value.convert(value.translation3D, from: .local, to: .scene), ended: false)
                    }
                    .onEnded { value in
                        rotate(by: value.convert(value.translation3D, from: .local, to: .scene),  ended: true)
                    }
            )
            .hoverEffect()
        }
        .onDisappear {
            viewModel.isConformerViewOpen = false
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
    
    private func rotate(by translation3D: SIMD3<Float>, ended: Bool) {
        let translation2D = Vector3D(x: translation3D.y, y: translation3D.x, z: 0.0)
        let newRotation3D = Rotation3D(angle: Angle2D(radians: translation2D.length * .pi),
                                       axis: RotationAxis3D(x: translation2D.x, y: translation2D.y, z: 0))
        
        let newTotalRotation3D = newRotation3D * totalRotation3D
        
        rotationAngle = Angle(radians: newTotalRotation3D.angle.radians)
        rotationAxis = newTotalRotation3D.axis
        
        if ended {
            totalRotation3D = newTotalRotation3D
        }
    }
    
}
