//
//  SearchPubChemApp.swift
//  SearchPubChem
//
//  Created by Jae Seung Lee on 10/6/21.
//  Copyright © 2021 Jae Seung Lee. All rights reserved.
//

import SwiftUI
import Persistence

@main
struct SearchPubChemApp: App {
    @UIApplicationDelegateAdaptor private var appDelegate: AppDelegate
    
    @AppStorage("HasLaunchedBefore", store: UserDefaults.standard) var hasLaunchedBefore: Bool = false
    @AppStorage("HasDBMigrated", store: UserDefaults.standard) var hasDBMigrated: Bool = false
    
    var body: some Scene {
        WindowGroup {
            if !hasLaunchedBefore {
                FirstLaunchView()
                    .environmentObject(appDelegate.viewModel)
            } else if !hasDBMigrated {
                DataMigrationView()
                    .environmentObject(DataMigrator())
            } else {
                ContentView()
                    .environment(\.managedObjectContext, appDelegate.persistence.container.viewContext)
                    .environmentObject(appDelegate.viewModel)
            }
        }
    }
}
