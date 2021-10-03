//
//  CompoundListView.swift
//  SearchPubChem
//
//  Created by Jae Seung Lee on 10/3/21.
//  Copyright © 2021 Jae Seung Lee. All rights reserved.
//

import SwiftUI

struct CompoundListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) private var presentationMode
    //@EnvironmentObject var viewModel: SearchPubChemViewModel
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Compound.name, ascending: true)],
        animation: .default)
    private var compounds: FetchedResults<Compound>
    
    var filteredCompounds: Array<Compound> {
        compounds.filter { compound in
            return true
        }
    }
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                VStack {
                    List {
                        ForEach(filteredCompounds) { compound in
                            NavigationLink {
                                CompoundDetailView(compound: compound)
                            } label: {
                                HStack {
                                    Text(compound.name ?? "N/A")
                                    Spacer()
                                    Text(compound.formula ?? "N/A")
                                }
                            }
                        }
                    }
                }
            }
        }
        
    }
}

struct CompoundListView_Previews: PreviewProvider {
    static var previews: some View {
        CompoundListView()
    }
}
