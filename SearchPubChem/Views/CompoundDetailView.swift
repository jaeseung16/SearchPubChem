//
//  CompoundDetailView.swift
//  SearchPubChem
//
//  Created by Jae Seung Lee on 10/3/21.
//  Copyright © 2021 Jae Seung Lee. All rights reserved.
//

import SwiftUI
import CoreData

struct CompoundDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @State var compound: Compound
    @State private var presentConformerView = false
    
    private var solutions: [Solution] {
        var solutions = [Solution]()
        compound.solutions?.forEach { solution in
            if let solution = solution as? Solution {
                solutions.append(solution)
            }
        }
        return solutions
    }
    
    private var conformer: Conformer? {
        guard compound.conformerDownloaded else {
            return nil
        }
        
        if let conformers = compound.conformers, conformers.count > 0 {
            print("conformers = \(conformers)")
            for conformerEntity in conformers {
                if let entity = conformerEntity as? ConformerEntity {
                    var atoms = [AtomEntity]()
                    entity.atoms?.forEach({ atom in
                        if let atom = atom as? AtomEntity {
                            atoms.append(atom)
                        }
                    })
                    
                    return populateConformer(for: entity, with: atoms)
                }
            }
        }
        return nil
    }
    
    private func populateConformer(for conformerEntity: ConformerEntity, with atomEntities: [AtomEntity]) -> Conformer {
        let conformer = Conformer()
        conformer.cid = compound.cid ?? ""
        conformer.conformerId = conformerEntity.conformerId ?? ""
        
        conformer.atoms = [Atom]()
        for atomEntity in atomEntities {
            let atom = Atom()
            atom.number = Int(atomEntity.atomicNumber)
            atom.location = [atomEntity.coordX, atomEntity.coordY, atomEntity.coordZ]
            
            conformer.atoms.append(atom)
        }
        return conformer
    }
    
    var body: some View {
        VStack {
            ZStack {
                HStack {
                    Text("tags here")
                    Spacer()
                    Button {
                        if let conformer = conformer {
                            presentConformerView = true
                        }
                    } label: {
                        Text("3D")
                    }
                    .disabled(conformer == nil)
                }
                
                HStack {
                    Spacer()
                    Text(compound.name?.uppercased() ?? "")
                    Spacer()
                }
            }
            
            
            Text(compound.formula ?? "")
            Text("\(compound.molecularWeight) gram/mol")
            
            if let imageData = compound.image, let image = UIImage(data: imageData) {
                Image(uiImage: image)
            } else {
                Text("N/A")
            }
            
            Text("PubChem CID: \(compound.cid ?? "")")
            
            Text("IUPAC Name: \(compound.nameIUPAC ?? "")")
            
            Divider()
            
            Text("Solutions")
            
            List {
                ForEach(solutions) { solution in
                    Text(solution.name ?? "")
                }
            }
        }
        .padding()
        .sheet(isPresented: $presentConformerView) {
            if let conformer = conformer {
                ConformerView(conformer:conformer, name: compound.name ?? "", formula: compound.formula ?? "")
            }
        }
        
    }
}

