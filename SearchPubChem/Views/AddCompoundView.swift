//
//  AddCompoundView.swift
//  SearchPubChem
//
//  Created by Jae Seung Lee on 10/6/21.
//  Copyright © 2021 Jae Seung Lee. All rights reserved.
//

import SwiftUI

struct AddCompoundView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject private var viewModel: SearchPubChemViewModel
    
    @State private var searchType = SearchType.name
    @State private var searchValue = ""
    @State private var presentConformerView = false
    @State private var enableSearchButton = false
    @State private var isEditing = false
    
    var body: some View {
        VStack {
            header()
            
            Divider()
            
            Picker("", selection: $searchType) {
                ForEach(SearchType.allCases) { item in
                    Text(item.rawValue)
                        .tag(item)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            
            TextField("water", text: $searchValue) { isEditing in
                if isEditing {
                    enableSearchButton = false
                }
            } onCommit: {
                enableSearchButton = true
                searchValue = searchValue.trimmingCharacters(in: .whitespaces)
            }
            .autocapitalization(.none)
            .multilineTextAlignment(.center)
            .roundedBackgroundRectangle()
                
            Button {
                viewModel.searchCompound(type: searchType, value: searchValue)
            } label: {
                Text("Search")
            }
            .disabled(!enableSearchButton)
            
            if (viewModel.propertySet != nil) {
                searchResult()
            } else {
                Spacer()
            }
        }
        .padding()
        .sheet(isPresented: $presentConformerView) {
            if let conformer = viewModel.conformer {
                ConformerView(conformer: conformer, name: viewModel.propertySet?.Title ?? "", molecularFormula: viewModel.propertySet?.MolecularFormula ?? "")
            }
        }
    }
    
    private func header() -> some View {
        HStack {
            Button {
                viewModel.resetCompound()
                presentationMode.wrappedValue.dismiss()
            } label: {
                Text(Action.Cancel.rawValue)
            }
            
            Spacer()
            
            Button {
                viewModel.saveCompound(searchType: searchType, searchValue: searchValue, viewContext: viewContext)
                presentationMode.wrappedValue.dismiss()
            } label: {
                Text(Action.Save.rawValue)
            }
        }
    }
    
    private func searchResult() -> some View {
        VStack {
            Divider()
            
            ZStack {
                if let data = viewModel.imageData, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } else {
                    Image(systemName: "photo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                }
                 
                VStack {
                    Text(viewModel.propertySet?.MolecularFormula ?? "")
                        .foregroundColor(.black)
                    Spacer()
                    
                    if viewModel.conformer != nil {
                        Button {
                            presentConformerView = true
                        } label: {
                            Text("Conformer")
                        }
                    }
                }
            }
            
            Text("Molecular Weight (gram/mol)")
            Text(viewModel.propertySet?.MolecularWeight ?? "")
            Text("PubChem Compound Identifier (CID)")
            Text("\(viewModel.propertySet?.CID ?? 0)")
            Text("IUPAC Name")
            Text(viewModel.propertySet?.IUPACName ?? "")
        }
    }
}

