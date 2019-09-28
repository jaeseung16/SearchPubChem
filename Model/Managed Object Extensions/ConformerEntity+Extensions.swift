//
//  Conformer+Extensions.swift
//  SearchPubChem
//
//  Created by Jae Seung Lee on 8/18/19.
//  Copyright © 2019 Jae Seung Lee. All rights reserved.
//

import Foundation
import CoreData

extension ConformerEntity {
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        created = Date()
    }
}
