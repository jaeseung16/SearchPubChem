//
//  VisionSearchPubChemApp.swift
//  VisionSearchPubChem
//
//  Created by Jae Seung Lee on 2/25/24.
//  Copyright © 2024 Jae Seung Lee. All rights reserved.
//

import SwiftUI
import Persistence

@main
struct VisionSearchPubChemApp: App {
    @UIApplicationDelegateAdaptor private var appDelegate: VisionAppDelegate
    
    @State private var compound: Compound?
    
    var body: some Scene {
        WindowGroup(id: WindowId.compounds.rawValue) {
            ContentView(compound: $compound)
                .environmentObject(appDelegate.viewModel)
        }
        .windowStyle(.plain)
        
        WindowGroup(id: WindowId.conformer.rawValue) {
            ConformerView(compound: $compound)
                .environmentObject(appDelegate.viewModel)
        }
        .windowStyle(.volumetric)
        .defaultSize(width: 0.6, height: 0.6, depth: 0.6, in: .meters)
        
        WindowGroup(id: WindowId.firstLaunch.rawValue) {
            FirstLaunchView()
                .environmentObject(appDelegate.viewModel)
        }
        .windowStyle(.volumetric)
        .defaultSize(width: 0.6, height: 0.6, depth: 0.6, in: .meters)
        
    }
}
