//
//  SolutionListView.swift
//  SearchPubChem
//
//  Created by Jae Seung Lee on 10/6/21.
//  Copyright © 2021 Jae Seung Lee. All rights reserved.
//

import SwiftUI

struct SolutionListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject private var viewModel: SearchPubChemViewModel
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Solution.created, ascending: false)],
        animation: .default)
    private var solutions: FetchedResults<Solution>
    
    @State private var presentMakeSolutionView = false
    
    private var dateFormatter: DateFormatter {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none
        dateFormatter.locale = Locale.current
        return dateFormatter
    }
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                VStack {
                    List {
                        ForEach(solutions) { solution in
                            NavigationLink {
                                SolutionDetailView(solution: solution)
                            } label: {
                                label(for: solution)
                            }
                        }
                    }
                    .navigationTitle(TabItem.Solutions.rawValue)
                    .toolbar {
                        toolBarContent()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
        }
        .sheet(isPresented: $presentMakeSolutionView) {
            MakeSolutionView()
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
        }
    }
}
