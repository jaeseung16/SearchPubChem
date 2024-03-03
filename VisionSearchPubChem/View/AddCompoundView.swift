//
//  AddCompoundView.swift
//  VisionSearchPubChem
//
//  Created by Jae Seung Lee on 3/3/24.
//  Copyright © 2024 Jae Seung Lee. All rights reserved.
//

import SwiftUI

struct AddCompoundView: View {
    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject private var viewModel: VisionSearchPubChemViewModel
    
    @State private var searchType = SearchType.name
    @State private var searchValue = ""
    @State private var enableSearchButton = false
    @State private var isEditing = false
    @State private var showProgress = false

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
            .pickerStyle(.segmented)
            
            Spacer(minLength: 25)
            
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
            .font(.title)
            .textFieldStyle(RoundedBorderTextFieldStyle())
                
            Spacer(minLength: 25)
            
            Button {
                viewModel.searchCompound(type: searchType, value: searchValue)
                showProgress = true
            } label: {
                Text("Search")
            }
            .disabled(!enableSearchButton)
            .buttonBorderShape(.roundedRectangle)
            
            if (viewModel.propertySet != nil) {
                searchResult()
            } else {
                Spacer()
                
                if showProgress {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                    Spacer()
                }
            }
        }
        .padding()
        .onChange(of: viewModel.errorMessage) {
            showProgress = false
        }
        .alert(viewModel.errorMessage ?? "Cannot download a compound", isPresented: $viewModel.showAlert) {
            Button {
                searchValue = ""
                viewModel.errorMessage = nil
            } label: {
                Text("Dismiss")
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
            .accessibilityIdentifier("cancelAddCompoundButton")
            .buttonBorderShape(.capsule)
            
            Spacer()
            
            Button {
                viewModel.saveCompound(searchType: searchType, searchValue: searchValue)
                presentationMode.wrappedValue.dismiss()
            } label: {
                Text(Action.Save.rawValue)
            }
            .buttonBorderShape(.capsule)
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

