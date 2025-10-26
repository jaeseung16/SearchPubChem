//
//  ContentView.swift
//  SearchPubChem
//
//  Created by Jae Seung Lee on 10/6/21.
//  Copyright © 2021 Jae Seung Lee. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var viewModel: SearchPubChemViewModel
    
    @State private var selectedTab = SelectedTab.compound
    
    var body: some View {
        TabView(selection: $selectedTab) {
            CompoundListView(compounds: viewModel.allCompounds)
                .tabItem {
                    if selectedTab == .compound {
                        Label(TabItem.Compounds.rawValue, image: TabItem.Compounds.selectedImageName)
                            .accessibilityIdentifier("compoundTabSelected")
                    } else {
                        Label(TabItem.Compounds.rawValue, image: TabItem.Compounds.defaultImageName)
                            .accessibilityIdentifier("compoundTabUnselected")
                    }
                }
                .tag(SelectedTab.compound)
            
            SolutionListView()
                .tabItem {
                    if selectedTab == .solution {
                        Label(TabItem.Solutions.rawValue, image: TabItem.Solutions.selectedImageName)
                            .accessibilityIdentifier("solutionTabSelected")
                    } else {
                        Label(TabItem.Solutions.rawValue, image: TabItem.Solutions.defaultImageName)
                            .accessibilityIdentifier("solutionTabUnselected")
                    }
                }
                .tag(SelectedTab.solution)
        }
        .alert("Unable to Save Data", isPresented: $viewModel.showAlert) {
            Button {
                viewModel.errorMessage = nil
            } label: {
                Text(Action.Dismiss.rawValue)
            }
        }
        .onChange(of: viewModel.receivedURL) { _ in
            selectedTab = .compound
        }
    }
}

enum SelectedTab: String, Identifiable {
    case compound, solution
    
    var id: String {
        self.rawValue
    }
}
