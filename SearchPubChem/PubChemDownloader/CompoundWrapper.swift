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
