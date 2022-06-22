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
    @Environment(\.scenePhase) private var scenePhase
    
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
                    .onChange(of: scenePhase) { phase in
                        if phase == .background {
                            appDelegate.viewModel.writeWidgetEntries()
                        }
                    }
                    .onOpenURL { url in
                        print("url=\(url)")
                        if let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false),
                           let scheme = urlComponents.scheme,
                           scheme == SearchPubChemConstants.widgetURLScheme.rawValue {
                            appDelegate.viewModel.receivedURL.toggle()
                            
                            appDelegate.viewModel.selectedCid = String(urlComponents.path.split(separator: "/")[0])
                            appDelegate.viewModel.selectedCompoundName = urlComponents.queryItems?[0].name ?? ""
                        }
                    }
            }
        }
    }
}
