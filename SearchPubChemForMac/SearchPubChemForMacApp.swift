//
//  SearchPubChemForMacApp.swift
//  SearchPubChemForMac
//
//  Created by Jae Seung Lee on 2/8/21.
//  Copyright © 2021 Jae Seung Lee. All rights reserved.
//

import SwiftUI

@main
struct SearchPubChemForMacApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
