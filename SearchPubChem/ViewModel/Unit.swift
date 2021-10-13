//
//  Unit.swift
//  SearchPubChem
//
//  Created by Jae Seung Lee on 10/12/21.
//  Copyright © 2021 Jae Seung Lee. All rights reserved.
//

import Foundation

enum Unit: String, CaseIterable, Identifiable {
    case gram
    case mg
    case mol
    case mM
    
    var id: String {
        self.rawValue
    }
}
