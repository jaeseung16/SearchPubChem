//
//  Elements.swift
//  SearchPubChem
//
//  Created by Jae Seung Lee on 7/28/19.
//  Copyright © 2019 Jae Seung Lee. All rights reserved.
//

import Foundation

enum Elements: Int {
    case hydrogen = 1
    case helium
    case lithium
    case berylium
    case boron
    case carbon
    case nitrogen
    case oxygen
    case fluorine
    case neon
    
    public func getElement() -> ElementStruct {
        var elementToReturn = ElementStruct()
        elementToReturn.atomicNumber = self.rawValue
        switch(self) {
        case .hydrogen:
            elementToReturn.name = "hydrogen"
            elementToReturn.radius = 120
        case .carbon:
            elementToReturn.name = "carbon"
            elementToReturn.radius = 170
        case .nitrogen:
            elementToReturn.name = "nitrogen"
            elementToReturn.radius = 155
        case .oxygen:
            elementToReturn.name = "oxygen"
            elementToReturn.radius = 152
        default:
            elementToReturn.name = ""
            elementToReturn.radius = 0
        }
        
        return elementToReturn;
    }
}
