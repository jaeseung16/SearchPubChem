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
                    if selectedTab == .compound {
                        Image("Compound_Selected", label: Text("Compounds"))
                    } else {
                        Image("Compound", label: Text("Compounds"))
                    }
                    
                    Text("Compounds")
                }
                .tag(SelectedTab.compound)
            
            SolutionListView()
                .tabItem {
                    if selectedTab == .solution {
                        Image("Solution_Selected", label: Text("Solutions"))
                    } else {
                        Image("Solution", label: Text("Solutions"))
                    }
                    
                    Text("Solutions")
                }
                .tag(SelectedTab.solution)
        }
        .alert(isPresented: $viewModel.showAlert, content: {
            Alert(title: Text("Unable to Save Data"),
                  message: Text(viewModel.errorMessage ?? "No information about the error"),
                  dismissButton: .default(Text("Dismiss")))
        })
    }
}

enum SelectedTab: String, Identifiable {
    case compound, solution
    
    var id: String {
        self.rawValue
    }
}
