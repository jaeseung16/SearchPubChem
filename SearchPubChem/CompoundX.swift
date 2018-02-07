//
//  Compound.swift
//  SearchPubChem
//
//  Created by Jae Seung Lee on 1/17/18.
//  Copyright © 2018 Jae Seung Lee. All rights reserved.
//

import Foundation

class CompoundX {
    var name: String?
    var formula: String?
    var molecularWeight: Double?
    var CID: String?
    var nameIUPAC: String?
    var image: Data?
    
    init() {
        
    }
    
    init(name: String?, formula: String?, molecularWeight: Double?, CID: String?, nameIUPAC: String?, image: Data?) {
        self.name = name
        self.formula = formula
        self.molecularWeight = molecularWeight
        self.CID = CID
        self.nameIUPAC = nameIUPAC
        self.image = image
    }
}
