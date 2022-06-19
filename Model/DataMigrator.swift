//
//  DataMigrator.swift
//  SearchPubChem
//
//  Created by Jae Seung Lee on 10/10/21.
//  Copyright © 2021 Jae Seung Lee. All rights reserved.
//

import Foundation
import CoreData
import os
import Persistence

// Reference: https://williamboles.me/progressive-core-data-migration/
class DataMigrator: ObservableObject {
    private static let modelExtension = "mom"
    private static let hasDBMigradtedKey = "HasDBMigrated"
    
    private let logger = Logger()
    
    let migrator: DatabaseMigrator?
    
    init() {
        let sourceModelName = "PubChemSolution.momd/PubChemSolution v3"
        let destinationModelName = "PubChemSolution.momd/PubChemSolution v4"
        
        guard let sourceModelURL = Bundle.main.url(forResource: sourceModelName, withExtension: DataMigrator.modelExtension),
              let destinationModelURL = Bundle.main.url(forResource: destinationModelName, withExtension: DataMigrator.modelExtension) else {
            self.migrator = nil
            return
        }
        
        let paths = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        let storeFilename = "PubChemSolution.sqlite"
        let storeURL = paths[0].appendingPathComponent(storeFilename)
        
        self.migrator = DatabaseMigrator(sourceModelURL: sourceModelURL, destinationModelURL: destinationModelURL, storeURL: storeURL)
        
        if !isMigrationNecessary() {
            UserDefaults.standard.set(true, forKey: DataMigrator.hasDBMigradtedKey)
        } else {
            migrate()
            UserDefaults.standard.set(true, forKey: DataMigrator.hasDBMigradtedKey)
        }
        
    }
    
    func isMigrationNecessary() -> Bool {
        guard let migrator = migrator else {
            return false
        }
        return migrator.isMigrationNecessary()
    }
    
    func migrate() -> Void {
        migrator!.migrate { result in
            switch result {
            case .success(()):
                return
            case .failure(let error):
                self.logger.log("\(error.localizedDescription, privacy: .public)")
            }
        }
    }
    
}

