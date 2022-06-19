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
    @AppStorage("HasLaunchedBefore", store: UserDefaults.standard) var hasLaunchedBefore: Bool = false
    @AppStorage("HasDBMigrated", store: UserDefaults.standard) var hasDBMigrated: Bool = false
    
    var body: some Scene {
        let persistence = Persistence(name: SearchPubChemConstants.modelName.rawValue,
                                      identifier: SearchPubChemConstants.containerIdentifier.rawValue)
        let viewModel = SearchPubChemViewModel(persistence: persistence)
        
        WindowGroup {
            if !hasLaunchedBefore {
                FirstLaunchView()
                    .environmentObject(viewModel)
            } else if !hasDBMigrated {
                DataMigrationView()
                    .environmentObject(DataMigrator())
            } else {
                ContentView()
                    .environment(\.managedObjectContext, persistence.container.viewContext)
                    .environmentObject(viewModel)
            }
        }
    }
}
