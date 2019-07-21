//
//  Atom.swift
//  SearchPubChem
//
//  Created by Jae Seung Lee on 7/21/19.
//  Copyright © 2019 Jae Seung Lee. All rights reserved.
//

import Foundation
import UIKit

class Atom {
    var element: Element
    var color: UIColor
    var location: [Double]
    
    init() {
        element = Element()
        color = .lightGray
        location = [0.0, 0.0, 0.0]
    }
}
