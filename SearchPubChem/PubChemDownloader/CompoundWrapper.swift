//
//  CompoundWrapper.swift
//  SearchPubChem
//
//  Created by Jae Seung Lee on 5/16/21.
//  Copyright © 2021 Jae Seung Lee. All rights reserved.
//

import Foundation

struct CompoundWrapper: Codable {
    var name: String?
    var cid: String?
    var iupacName: String?
    var molecularFormula: String?
    var molecularWeight: String
    var conformerDownloaded: Bool
    var conformers: [Conformer]
    var compoundTags: [String]
    
    struct Conformer: Codable {
        var conformerId: String?
        var atoms: [Atom]
    }
    
    struct Atom: Codable {
        var atomicNumber: Int
        var coordX: Double
        var coordY: Double
        var coordZ: Double
    }
}


/*
 
 compound.firstCharacterInName = String(compound.name!.first!).uppercased()
 compound.image = compoundImageView.image!.pngData()!
 compound.conformerDownloaded = true
 
 
 compound.name -> compoundProperties.Title
 compound.formula ->  compoundProperties.MolecularFormula
 compound.molecularWeight -> compoundProperties.MolecularWeight
 compound.cid -> compoundProperties.CID
 compound.nameIUPAC -> compoundProperties.IUPACName
 
 
 
 let conformerEntity = ConformerEntity(context: dataController.viewContext)
 if let conformer = self.conformer {
     conformerEntity.compound = compound
     conformerEntity.conformerId = conformer.conformerId
 
     for atom in conformer.atoms {
         let atomEntity = AtomEntity(context: dataController.viewContext)
         atomEntity.atomicNumber = Int16(atom.number)
         atomEntity.coordX = atom.location[0]
         atomEntity.coordY = atom.location[1]
         atomEntity.coordZ = atom.location[2]
         atomEntity.conformer = conformerEntity
     }
 }
 
 */
