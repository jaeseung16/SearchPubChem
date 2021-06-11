//
//  CompoundDTO.swift
//  SearchPubChem
//
//  Created by Jae Seung Lee on 7/4/20.
//  Copyright © 2020 Jae Seung Lee. All rights reserved.
//

import Foundation

struct CompoundDTO: Codable {
    enum CodingKeys: String, CodingKey {
        case propertyTable = "PropertyTable"
    }
    
    var propertyTable: PropertyTable
}

struct PropertyTable: Codable {
    enum CodingKeys: String, CodingKey {
        case properties = "Properties"
    }
    
    var properties: [Properties]
}

struct Properties: Codable {
    var CID: Int
    var IUPACName: String
    var MolecularFormula: String
    var MolecularWeight: String
    var Title: String
}
