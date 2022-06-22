//
//  SearchPubChemWidgetExtension.swift
//  SearchPubChemWidgetExtension
//
//  Created by Jae Seung Lee on 6/20/22.
//  Copyright © 2022 Jae Seung Lee. All rights reserved.
//

import WidgetKit
import SwiftUI

@main
struct SearchPubChemWidgetExtension: Widget {
    let kind: String = "SearchPubChemWidgetExtension"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            WidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Recents")
        .description("Recently added compounds")
        .supportedFamilies([.systemSmall])
    }
}
