//
//  SolutionListView.swift
//  VisionSearchPubChem
//
//  Created by Jae Seung Lee on 3/11/24.
//  Copyright © 2024 Jae Seung Lee. All rights reserved.
//

import SwiftUI

struct SolutionListView: View {
    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject private var viewModel: VisionSearchPubChemViewModel
    
    @Binding var selectedSolution: Solution?
    @State private var presentMakeSolutionView = false
    
    private var dateFormatter: DateFormatter {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none
        dateFormatter.locale = Locale.current
        return dateFormatter
    }
    
    var body: some View {
        GeometryReader { geometry in
            // TODO: - NavigationSplitView with NavigationStack in detail
            NavigationSplitView {
                List(selection: $selectedSolution) {
                    ForEach(viewModel.allSolutions) { solution in
                        NavigationLink(value: solution) {
                            label(for: solution)
                        }
                        .hoverEffect()
                    }
                }
                .navigationTitle("Solution")
                .toolbar {
                    ToolbarItem(placement: .bottomOrnament) {
                        Button {
                            presentMakeSolutionView = true
                        } label: {
                            Image(systemName: "plus")
                        }
                        .accessibilityIdentifier("makeSolutionButton")
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            } detail: {
                if let selectedSolution {
                    NavigationStack {
                        SolutionDetailView(solution: selectedSolution)
                            .id(selectedSolution)
                    }
                } else {
                    EmptyView()
                }
            }
            .sheet(isPresented: $presentMakeSolutionView) {
                MakeSolutionView()
                    .environmentObject(viewModel)
                    .frame(minWidth: 1.5 * geometry.size.width, minHeight: geometry.size.height)
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
    
}
