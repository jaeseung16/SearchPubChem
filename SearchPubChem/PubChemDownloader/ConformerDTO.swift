//
//  ConformerDTO.swift
//  SearchPubChem
//
//  Created by Jae Seung Lee on 7/8/20.
//  Copyright © 2020 Jae Seung Lee. All rights reserved.
//

import Foundation

struct ConformerDTO: Codable {
    enum CodingKeys: String, CodingKey {
        case pcCompounds = "PC_Compounds"
    }
    
    var pcCompounds: [PCCompound]
}

struct PCCompound: Codable {
    enum CodingKeys: String, CodingKey {
        case id, atoms, bonds, coords
    }
    
    var id: CompoundID
    var atoms: Atoms
    var bonds: Bonds
    var coords: [Coord]
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(CompoundID.self, forKey: .id)
        atoms = try container.decode(Atoms.self, forKey: .atoms)
        bonds = try container.decode(Bonds.self, forKey: .bonds)
        coords = try container.decode([Coord].self, forKey: .coords)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(atoms, forKey: .atoms)
        try container.encode(bonds, forKey: .bonds)
        try container.encode(coords, forKey: .coords)
    }
}

struct CompoundID: Codable {
    enum CodingKeys: String, CodingKey {
        case id
    }
    
    enum Id: String, CodingKey {
        case cid
    }
    
    var cid: Int
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let firstIdContainer = try container.nestedContainer(keyedBy: Id.self, forKey: .id)
        
        cid = try firstIdContainer.decode(Int.self, forKey: .cid)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        var firstIdContainer = container.nestedContainer(keyedBy: Id.self, forKey: .id)
        
        try firstIdContainer.encode(cid, forKey: .cid)
    }
}

struct Atoms: Codable {
    var aid: [Int]
    var element: [Int]
}

struct Bonds: Codable {
    var aid1: [Int]
    var aid2: [Int]
    var order: [Int]
}

struct Coord: Codable {
    var type: [Int]
    var aid: [Int]
    var conformers: [ConformerData]
}

struct ConformerData: Codable {
    var x: [Double]
    var y: [Double]
    var z: [Double]
    var data: [CoordData]
}

struct CoordData: Codable {
    var urn: URN
    var value: Value
}

struct URN: Codable {
    var label: String
    var name: String
    var datatype: Int
    var version: String
    var software: String
    var source: String
    var release: String
}

struct Value: Codable {
    var fval: Double?
    var fvec: [Double]?
    var sval: String?
    var slist: [String]?
}
