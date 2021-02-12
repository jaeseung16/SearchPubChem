//
//  Element.swift
//  SearchPubChemForMac
//
//  Created by Jae Seung Lee on 2/10/21.
//  Copyright © 2021 Jae Seung Lee. All rights reserved.
//

import Foundation
import SwiftUI

struct Element: Hashable {
    var atomicNumber: Int
    var name: String
    var color: NSColor
    var radius: Int
    // covalent radius from https://en.wikipedia.org/wiki/Covalent_radius
    // check https://en.wikipedia.org/wiki/Atomic_radius
    // check https://en.wikipedia.org/wiki/Atomic_radii_of_the_elements_(data_page)
    
    init() {
        atomicNumber = 1
        name = "hydrogen"
        color = .white
        radius = 31
    }
    
    static func == (lhs: Element, rhs: Element) -> Bool {
        return lhs.atomicNumber == rhs.atomicNumber
    }
    
}
