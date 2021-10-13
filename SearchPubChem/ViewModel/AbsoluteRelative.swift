//
//  AbsoluteRelative.swift
//  SearchPubChem
//
//  Created by Jae Seung Lee on 10/12/21.
//  Copyright © 2021 Jae Seung Lee. All rights reserved.
//

import Foundation

enum AbsoluteRelatve: String, CaseIterable, Identifiable {
    case absolute = "actual"
    case relative = "%"
    
    var id: String {
        self.rawValue
    }
}
