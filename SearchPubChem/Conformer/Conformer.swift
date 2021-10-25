//
//  Conformer.swift
//  SearchPubChem
//
//  Created by Jae Seung Lee on 7/21/19.
//  Copyright © 2019 Jae Seung Lee. All rights reserved.
//

import Foundation

class Conformer {
    var atoms: [Atom]
    var cid: String
    var conformerId: String
    
    init() {
        atoms = [Atom]()
        cid = ""
        conformerId = ""
    }
    
    init(cid: String, conformerEntity: ConformerEntity, atomEntities: [AtomEntity]) {
        self.cid = cid
        self.conformerId = conformerEntity.conformerId ?? ""
        
        var atoms = [Atom]()
        for atomEntity in atomEntities {
            let atom = Atom()
            atom.number = Int(atomEntity.atomicNumber)
            atom.location = [atomEntity.coordX, atomEntity.coordY, atomEntity.coordZ]
            
            atoms.append(atom)
        }
        self.atoms = atoms
    }
    
}

extension Conformer: CustomStringConvertible {
    var description: String {
        get {
            return "cid = \(self.cid), " + "atoms = \(self.atoms)" + ", conformerId = \(self.conformerId)"
        }
    }
}
