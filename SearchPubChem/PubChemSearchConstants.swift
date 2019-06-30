//
//  PubChemSearchConstants.swift
//  SearchPubChem
//
//  Created by Jae Seung Lee on 2/27/18.
//  Copyright © 2018 Jae Seung Lee. All rights reserved.
//

import Foundation

extension PubChemSearch {
    struct Constant {
        static let scheme = "https"
        static let host = "pubchem.ncbi.nlm.nih.gov"
        static let pathForCID = "/rest/pug/compound/cid/"
        static let pathForName = "/rest/pug/compound/name/"
        static let pathForProperties = "/property/"
        static let pathForWeb = "/compound/"
    }
    
    struct PropertyKey {
        static let cid = "CID"
        static let formula = "MolecularFormula"
        static let weight = "MolecularWeight"
        static let nameIUPAC = "IUPACName"
    }
    
    struct QueryResult {
        static let json = "/json"
        static let png = "/png"
    }
    
    struct QueryString {
        static let recordType = "record_type"
    }
    
    struct RecordType {
        static let twoD = "2d"
        static let threeD = "3d"
    }
    
    // Status Codes from https://pubchemdocs.ncbi.nlm.nih.gov/pug-rest$_Toc494865562
    enum Status: Int {
        case success = 200
        case accepted = 202
        case badRequest = 400
        case notFound = 404
        case notAllowed = 405
        case serverError = 500
        case unimplemented = 501
        case serverBusy = 503
        case timeOut = 504
    }
}

