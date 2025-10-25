//
//  SolutionListView.swift
//  SearchPubChem
//
//  Created by Jae Seung Lee on 10/6/21.
//  Copyright © 2021 Jae Seung Lee. All rights reserved.
//

import SwiftUI

struct SolutionListView: View {
    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject private var viewModel: SearchPubChemViewModel
    
    @State private var presentMakeSolutionView = false
    @State private var selectedSolution: Solution?
    
    private var dateFormatter: DateFormatter {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none
        dateFormatter.locale = Locale.current
        return dateFormatter
    }
    
    var body: some View {
        GeometryReader { geometry in
            NavigationSplitView {
                List(selection: $selectedSolution) {
                    ForEach(viewModel.allSolutions) { solution in
                        NavigationLink(value: solution) {
                            label(for: solution)
                        }
                    }
                }
            } detail: {
                if let selectedSolution {
                    SolutionDetailView(solution: selectedSolution)
                        .id(selectedSolution)
                } else {
                    EmptyView()
                }
            }
            .navigationTitle(TabItem.Solutions.rawValue)
            .toolbar {
                toolBarContent()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .sheet(isPresented: $presentMakeSolutionView) {
                MakeSolutionView()
                    .environmentObject(viewModel)
            }
        }
    }
    
    private func label(for solution: Solution) -> some View {
        HStack {
            Text(solution.name ?? "N/A")
            Spacer()
            Text("\(dateFormatter.string(from: solution.created ?? Date()))")
        }
    }
    
    private func toolBarContent() -> some View {
        HStack {
            Spacer()
            
            Button {
                presentMakeSolutionView = true
            } label: {
                Image(systemName: "plus")
            }
            .accessibilityIdentifier("makeSolutionButton")
        }
    }
}
