//
//  WidgetEntry.swift
//  SearchPubChem
//
//  Created by Jae Seung Lee on 6/20/22.
//  Copyright © 2022 Jae Seung Lee. All rights reserved.
//

import Foundation
import WidgetKit

struct WidgetEntry: TimelineEntry, Codable, Identifiable {
    let cid: String
    let name: String
    let formula: String
    let image: Data?
    let created: Date
    var date: Date = Date()
    
    var id: String {
        "\(cid)_\(created.formatted())"
    }
}
