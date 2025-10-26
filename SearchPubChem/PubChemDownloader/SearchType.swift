//
//  SearchParameter.swift
//  SearchPubChem
//
//  Created by Jae Seung Lee on 10/6/21.
//  Copyright © 2021 Jae Seung Lee. All rights reserved.
//

enum SearchType: String, CaseIterable, Identifiable {
    case name = "Compound Name"
    case cid = "CID"
    
    var id: String {
        self.rawValue
    }
}
