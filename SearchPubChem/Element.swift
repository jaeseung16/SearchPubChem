//
//  Element.swift
//  SearchPubChem
//
//  Created by Jae Seung Lee on 7/21/19.
//  Copyright © 2019 Jae Seung Lee. All rights reserved.
//

import Foundation
import UIKit

struct Element: Hashable {
    var atomicNumber: Int
    var name: String
    var radius: Int // covalent radius from https://en.wikipedia.org/wiki/Covalent_radius
    // check https://en.wikipedia.org/wiki/Atomic_radius
    // check https://en.wikipedia.org/wiki/Atomic_radii_of_the_elements_(data_page)
    
    init() {
        atomicNumber = 1
        name = "hydrogen"
        radius = 31
    }
    
    static func == (lhs: Element, rhs: Element) -> Bool {
        return lhs.atomicNumber == rhs.atomicNumber
    }
    
}
