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
}

extension Conformer: CustomStringConvertible {
    var description: String {
        get {
            return "cid = \(self.cid), " + "atoms = \(self.atoms)" + ", conformerId = \(self.conformerId)"
        }
    }
}
