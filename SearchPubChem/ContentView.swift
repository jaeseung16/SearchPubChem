//
//  ContentView.swift
//  SearchPubChem
//
//  Created by Jae Seung Lee on 10/6/21.
//  Copyright © 2021 Jae Seung Lee. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var viewModel: SearchPubChemViewModel
    
    @State private var selectedTab = SelectedTab.compound
    
    var body: some View {
        TabView(selection: $selectedTab) {
            CompoundListView()
                .tabItem {
                    Label(TabItem.Compounds.rawValue, systemImage: "allergens")
                }
                .tag(SelectedTab.compound)
            
            SolutionListView()
                .tabItem {
                    Label(TabItem.Solutions.rawValue, systemImage: "testtube.2")
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
    }
}

enum SelectedTab: String, Identifiable {
    case compound, solution
    
    var id: String {
        self.rawValue
    }
}
