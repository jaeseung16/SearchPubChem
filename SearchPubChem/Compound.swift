//
//  Compound.swift
//  SearchPubChem
//
//  Created by Jae Seung Lee on 1/17/18.
//  Copyright © 2018 Jae Seung Lee. All rights reserved.
//

import Foundation

struct Compound {
    let name: String
    let formula: String
    let molecularWeight: Double
    let CID: String
    let nameIUPAC: String
    var image: Data?
}
