//
//  CompoundTag+Extensions.swift
//  SearchPubChem
//
//  Created by Jae Seung Lee on 5/10/21.
//  Copyright © 2021 Jae Seung Lee. All rights reserved.
//

import Foundation
import CoreData

extension CompoundTag {
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        created = Date()
    }
}
