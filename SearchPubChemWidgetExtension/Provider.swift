//
//  Provider.swift
//  SearchPubChem
//
//  Created by Jae Seung Lee on 6/20/22.
//  Copyright © 2022 Jae Seung Lee. All rights reserved.
//

import WidgetKit
import SwiftUI
import os

struct Provider: TimelineProvider {
    private let logger = Logger()
    
    private let title = "SearchPubChem"
    private let contentsJson = "contents.json"
    
    private var exampleEntry: WidgetEntry {
        WidgetEntry(cid: "cid",
                    name: title,
                    formula: "H2O",
                    image: nil,
                    created: Date(),
                    date: Date())
    }
    
    func placeholder(in context: Context) -> WidgetEntry {
        logger.log("placeholder")
        return exampleEntry
    }

    func getSnapshot(in context: Context, completion: @escaping (WidgetEntry) -> ()) {
        logger.log("snapshot")
        completion(exampleEntry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WidgetEntry>) -> ()) {
        var widgetEntries = [WidgetEntry]()
        
        let archiveURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: SearchPubChemConstants.groupIdentifier.rawValue)!
        logger.log("timeline: archiveURL=\(archiveURL)")
        let decoder = JSONDecoder()
        if let data = try? Data(contentsOf: archiveURL.appendingPathComponent(contentsJson)) {
            do {
                widgetEntries = try decoder.decode([WidgetEntry].self, from: data)
            } catch {
                logger.error("Can't decode contents: data=\(data)")
            }
        }
        logger.log("timeline: widgetEntries.count=\(widgetEntries.count)")
        let currentDate = Date()
        let interval = 1
        for index in 0 ..< widgetEntries.count {
            widgetEntries[index].date = Calendar.current.date(byAdding: .hour, value: index * interval, to: currentDate)!
        }

        let timeline = Timeline(entries: widgetEntries, policy: .atEnd)
        completion(timeline)
    }
}
