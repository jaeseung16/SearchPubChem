//
//  CompoundEntity+Extensions.swift
//  SearchPubChemForMac
//
//  Created by Jae Seung Lee on 2/8/21.
//  Copyright © 2021 Jae Seung Lee. All rights reserved.
//

import Foundation
import CoreData

extension CompoundEntity {
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        created = Date()
    }
    
    public override func awakeFromFetch() {
        super.awakeFromFetch()
        
        guard let char = name?.first else {
            return
        }
        
        firstCharacterInName = String(char).uppercased()
    }
}

