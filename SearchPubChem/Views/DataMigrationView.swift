//
//  DataMigrationView.swift
//  SearchPubChem
//
//  Created by Jae Seung Lee on 10/11/21.
//  Copyright © 2021 Jae Seung Lee. All rights reserved.
//

import SwiftUI

struct DataMigrationView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var dataMigrator: DataMigrator
    
    @AppStorage("HasDBMigrated", store: UserDefaults.standard) var hasDBMigrated: Bool = false
    
    var body: some View {
        VStack {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
                .onChange(of: hasDBMigrated) {
                    dismiss.callAsFunction()
                }
        }
    }
}
