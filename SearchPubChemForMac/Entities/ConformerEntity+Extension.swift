//
//  ConformerEntity+Extension.swift
//  SearchPubChemForMac
//
//  Created by Jae Seung Lee on 2/10/21.
//  Copyright © 2021 Jae Seung Lee. All rights reserved.
//

import Foundation
import CoreData

extension ConformerEntity {
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        created = Date()
    }
}
