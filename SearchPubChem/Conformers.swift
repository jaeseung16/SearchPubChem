//
//  Conformer.swift
//  SearchPubChem
//
//  Created by Jae Seung Lee on 7/21/19.
//  Copyright © 2019 Jae Seung Lee. All rights reserved.
//

import Foundation

class Conformers: CustomStringConvertible {
    var description: String {
        get {
            return "cid = \(self.cid), " + "atoms = \(self.atoms)"
        }
    }
    
    var atoms: [Atoms]
    var cid: String
    var conformerId: String
    
    init() {
        atoms = [Atoms]()
        cid = ""
        conformerId = ""
    }
}
