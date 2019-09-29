//
//  AtomEntity+Extensions.swift
//  SearchPubChem
//
//  Created by Jae Seung Lee on 9/29/19.
//  Copyright © 2019 Jae Seung Lee. All rights reserved.
//

import Foundation
import CoreData

extension AtomEntity {
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        created = Date()
    }
}
