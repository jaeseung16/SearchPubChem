//
//  TabItem.swift
//  SearchPubChem
//
//  Created by Jae Seung Lee on 10/25/21.
//  Copyright © 2021 Jae Seung Lee. All rights reserved.
//

import Foundation

enum TabItem: String {
    case Compounds
    case Solutions
    
    var defaultImageName: String {
        switch self {
        case .Compounds:
            return "Compound"
        case .Solutions:
            return "Solution"
        }
    }
    
    var selectedImageName: String {
        switch self {
        case .Compounds:
            return "Compound_Selected"
        case .Solutions:
            return "Solution_Selected"
        }
    }
}
