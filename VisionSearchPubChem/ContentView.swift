//
//  ContentView.swift
//  VisionSearchPubChem
//
//  Created by Jae Seung Lee on 2/25/24.
//  Copyright © 2024 Jae Seung Lee. All rights reserved.
//

import SwiftUI
import RealityKit
import RealityKitContent

struct ContentView: View {
    @EnvironmentObject var viewModel: VisionSearchPubChemViewModel
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissWindow) private var dismissWindow
    @AppStorage("HasLaunchedBefore", store: UserDefaults.standard) var hasLaunchedBefore: Bool = false
    
    @State private var selectedTab: TabItem?
    
    @Binding var compound: Compound?
    @State var solution: Solution?
    
    var body: some View {
        NavigationSplitView {
            List(TabItem.allCases, selection: $selectedTab) {
                Text($0.rawValue)
            }
        } content: {
            switch selectedTab {
            case .Compounds:
                CompoundListView(compounds: viewModel.allCompounds, selectedCompound: $compound)
                    .environmentObject(viewModel)
            case .Solutions:
                SolutionListView(selectedSolution: $solution)
            case .none:
                EmptyView()
            }
        } detail: {
            switch selectedTab {
            case .Compounds:
                if compound != nil {
                    CompoundDetailView(compound: $compound)
                        .environmentObject(viewModel)
                } else {
                    EmptyView()
                }
            case .Solutions:
                if solution != nil {
                    SolutionDetailView(solution: $solution)
                } else {
                    EmptyView()
                }
            case .none:
                EmptyView()
            }
        }
        .padding()
        .onAppear {
            if !hasLaunchedBefore {
                openWindow(id: WindowId.firstLaunch.rawValue)
            }
        }
        .onChange(of: hasLaunchedBefore) { oldValue, newValue in
            if newValue {
                dismissWindow.callAsFunction(id: WindowId.firstLaunch.rawValue)
            }
        }
        .onAppear {
            viewModel.isMainWindowOpen = true
        }
        .onDisappear {
            viewModel.isMainWindowOpen = false
        }
    }
}
