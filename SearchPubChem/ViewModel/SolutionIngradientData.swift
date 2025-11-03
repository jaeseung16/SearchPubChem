//
//  SolutionIngradientData.swift
//  SearchPubChem
//
//  Created by Jae Seung Lee on 11/2/25.
//  Copyright © 2025 Jae Seung Lee. All rights reserved.
//

import Foundation

struct SolutionIngradientData: Identifiable, CustomStringConvertible {
    var id: Compound {
        return compound
    }
    
    var compound: Compound
    var absoluteAmountByUnit: [Unit: Double]
    var relativeAmountByUnit: [Unit: Double]
    
    var description: String {
        return "SolutionIngradientData[compound=\(compound), absoluteAmountByUnit=\(absoluteAmountByUnit)], relativeAmountByUnit=\(relativeAmountByUnit)]"
    }
    
    var name: String {
        return compound.name ?? "Unknown"
    }
    
    var absoluteAmountInMoles: String {
        return absoluteAmountByUnit[.mol]?.formatted(.number) ?? "Unknown"
    }
    
    var absoluteAmountInMiliMoles: String {
        return absoluteAmountByUnit[.mM]?.formatted(.number) ?? "Unknown"
    }
    
    var absoluteAmountInGrams: String {
        return absoluteAmountByUnit[.gram]?.formatted(.number) ?? "Unknown"
    }
    
    var absoluteAmountInMilliGrams: String {
        return absoluteAmountByUnit[.mg]?.formatted(.number) ?? "Unknown"
    }
    
    var relativeAmountInMoles: String {
        return relativeAmountByUnit[.mol]?.formatted(.number) ?? "Unknown"
    }
    
    var relativeAmountInMiliMoles: String {
        return relativeAmountByUnit[.mM]?.formatted(.number) ?? "Unknown"
    }
    
    var relativeAmountInGrams: String {
        return relativeAmountByUnit[.gram]?.formatted(.number.precision(.fractionLength(3))) ?? "Unknown"
    }
    
    var relativeAmountInMilliGrams: String {
        return relativeAmountByUnit[.mg]?.formatted(.number.precision(.fractionLength(3))) ?? "Unknown"
    }
    
}
