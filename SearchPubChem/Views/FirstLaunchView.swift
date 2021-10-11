//
//  FirstLaunchView.swift
//  SearchPubChem
//
//  Created by Jae Seung Lee on 10/11/21.
//  Copyright © 2021 Jae Seung Lee. All rights reserved.
//

import SwiftUI

struct FirstLaunchView: View {
    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject private var viewModel: SearchPubChemViewModel
    
    var body: some View {
        VStack {
            Text("Welcome to SearchPubChem!")
                .font(.headline)
            
            Image("SearchPubChem")
                .resizable()
                .aspectRatio(contentMode: .fit)
            
            Text("Would you like to add some example compounds?")
            
            HStack {
                Spacer()
                
                Button {
                    UserDefaults.standard.set(true, forKey: "HasLaunchedBefore")
                    UserDefaults.standard.set(true, forKey: "HasDBMigrated")
                    presentationMode.wrappedValue.dismiss()
                } label: {
                    Text("No")
                }
                
                Spacer()
                
                Button {
                    UserDefaults.standard.set(true, forKey: "HasLaunchedBefore")
                    UserDefaults.standard.set(true, forKey: "HasDBMigrated")
                    viewModel.preloadData()
                    presentationMode.wrappedValue.dismiss()
                } label: {
                    Text("Yes")
                }
                
                Spacer()
            }
        }
        .padding()
    }
}

struct FirstLaunchView_Previews: PreviewProvider {
    static var previews: some View {
        FirstLaunchView()
    }
}
