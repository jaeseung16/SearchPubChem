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
                        Image(TabItem.Compounds.selectedImageName, label: Text(TabItem.Compounds.rawValue))
                    } else {
                        Image(TabItem.Compounds.defaultImageName, label: Text(TabItem.Compounds.rawValue))
                    }
                    
                    Text(TabItem.Compounds.rawValue)
                }
                .tag(SelectedTab.compound)
            
            SolutionListView()
                .tabItem {
                    if selectedTab == .solution {
                        Image(TabItem.Solutions.selectedImageName, label: Text(TabItem.Solutions.rawValue))
                    } else {
                        Image(TabItem.Compounds.defaultImageName, label: Text(TabItem.Solutions.rawValue))
                    }
                    
                    Text(TabItem.Solutions.rawValue)
                }
                .tag(SelectedTab.solution)
        }
        .alert(isPresented: $viewModel.showAlert, content: {
            Alert(title: Text("Unable to Save Data"),
                  message: Text(viewModel.errorMessage ?? "No information about the error"),
                  dismissButton: .default(Text(Action.Dismiss.rawValue)))
        })
    }
}

enum SelectedTab: String, Identifiable {
    case compound, solution
    
    var id: String {
        self.rawValue
    }
}
