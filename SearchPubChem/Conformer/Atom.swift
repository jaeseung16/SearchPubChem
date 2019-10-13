//
//  Atom.swift
//  SearchPubChem
//
//  Created by Jae Seung Lee on 7/21/19.
//  Copyright © 2019 Jae Seung Lee. All rights reserved.
//

import Foundation
import UIKit

class Atom: CustomStringConvertible{
    var description: String {
        get {
            return "\(self.number), \(self.location)"
        }
    }
    
    var number: Int
    var location: [Double]
    
    init() {
        number = 1
        location = [0.0, 0.0, 0.0]
    }
}
