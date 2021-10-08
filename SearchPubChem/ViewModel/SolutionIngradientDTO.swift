//
//  SolutionIngradientDTO.swift
//  SearchPubChem
//
//  Created by Jae Seung Lee on 10/7/21.
//  Copyright © 2021 Jae Seung Lee. All rights reserved.
//

struct SolutionIngradientDTO: Identifiable, CustomStringConvertible {
    var id: String {
        return compound.name ?? "" + "\(amount)" + unit.rawValue
    }
    
    var compound: Compound
    var amount: Double
    var unit: Unit
    
    var description: String {
        return "SolutionIngradientDTO[compound=\(compound), amount=\(amount), unit=\(unit)]"
    }
}
