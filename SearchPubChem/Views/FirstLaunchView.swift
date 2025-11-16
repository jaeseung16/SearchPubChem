//
//  FirstLaunchView.swift
//  SearchPubChem
//
//  Created by Jae Seung Lee on 10/11/21.
//  Copyright © 2021 Jae Seung Lee. All rights reserved.
//

import SwiftUI

struct FirstLaunchView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var viewModel: SearchPubChemViewModel
    
    private let hasLaunchedBeforeKey = "HasLaunchedBefore"
    private let hasDBMigratedKey = "HasDBMigrated"
    private let welcomeToSearchPubChem = "Welcome to SearchPubChem!"
    private let wantToAddSomeExamples = "Would you like to add some example compounds?"
    private let iPadIntro = "iPad_Intro"
    
    var body: some View {
        VStack {
            Text(welcomeToSearchPubChem)
                .font(.headline)
            
            Image(iPadIntro)
                .resizable()
                .aspectRatio(contentMode: .fit)
            
            Text(wantToAddSomeExamples)
            
            HStack {
                Spacer()
                
                Button {
                    UserDefaults.standard.set(true, forKey: hasLaunchedBeforeKey)
                    UserDefaults.standard.set(true, forKey: hasDBMigratedKey)
                    dismiss.callAsFunction()
                } label: {
                    Text(Action.No.rawValue)
                }
                
                Spacer()
                
                Button {
                    UserDefaults.standard.set(true, forKey: hasLaunchedBeforeKey)
                    UserDefaults.standard.set(true, forKey: hasDBMigratedKey)
                    viewModel.preloadData()
                    dismiss.callAsFunction()
                } label: {
                    Text(Action.Yes.rawValue)
                }
                
                Spacer()
            }
        }
        .padding()
    }
}

struct FirstLaunchView_Previews: PreviewProvider {
    static var previews: some View {
        ForEach(ColorScheme.allCases, id: \.self) {
            FirstLaunchView().preferredColorScheme($0)
        }
    }
}
