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

// Reference: https://williamboles.me/progressive-core-data-migration/
class DataMigrator: NSObject, ObservableObject {
    static let shared = DataMigrator()
    static let logger = Logger()
    
    let sourceModelName = "PubChemSolution.momd/PubChemSolution v3"
    let destinationModelName = "PubChemSolution.momd/PubChemSolution v4"
    let modelExtension = "mom"
    let storeFilename = "PubChemSolution.sqlite"
    let hasDBMigradtedKey = "HasDBMigrated"
    
    override init() {
        super.init()
        
        if !isMigrationNecessary() {
            UserDefaults.standard.set(true, forKey: hasDBMigradtedKey)
        } else {
            migrate()
            UserDefaults.standard.set(true, forKey: hasDBMigradtedKey)
        }
    }
    
    private var applicationSupportDirectory: URL {
        let paths = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        let applicationSupportDirectory = paths[0]
        return applicationSupportDirectory
    }
    
    private var temporaryDirectory: URL {
        FileManager.default.temporaryDirectory
    }
    
    private var sourceModelURL: URL? {
        Bundle.main.url(forResource: sourceModelName, withExtension: modelExtension)
    }
    
    private var destinationModelURL: URL? {
        Bundle.main.url(forResource: destinationModelName, withExtension: modelExtension)
    }
    
    private var storeURL: URL? {
        applicationSupportDirectory.appendingPathComponent(storeFilename)
    }
    
    private var _sourceModel: NSManagedObjectModel?
    var sourceModel: NSManagedObjectModel? {
        if _sourceModel == nil {
            _sourceModel = NSManagedObjectModel(contentsOf: sourceModelURL!)
        }
        return _sourceModel
    }
    
    private var _destinationModel: NSManagedObjectModel?
    var destinationModel: NSManagedObjectModel? {
        if _destinationModel == nil {
            _destinationModel = NSManagedObjectModel(contentsOf: destinationModelURL!)
        }
        return _destinationModel
    }
    
    private func sourceMetadata(storeURL: URL) -> [String: Any]? {
        return try? NSPersistentStoreCoordinator.metadataForPersistentStore(type: .sqlite, at: storeURL, options: nil)
    }
    
    func isMigrationNecessary() -> Bool {
        guard self.sourceModel != nil, let destinationModel = self.destinationModel else {
            return false
        }
        
        guard let storeURL = self.storeURL, let sourceMetaData = self.sourceMetadata(storeURL: storeURL) else {
            return false
        }
      
        return !destinationModel.isConfiguration(withName: nil, compatibleWithStoreMetadata: sourceMetaData)
    }
    
    private func compatibleModelForStoreMetadata(_ metadata: [String : Any]) -> NSManagedObjectModel? {
        if let sourceModel = self.sourceModel, sourceModel.isConfiguration(withName: nil, compatibleWithStoreMetadata: metadata) {
            return sourceModel
        } else {
            return nil
        }
    }
    
    func forceWALCheckpointingForStore(at storeURL: URL) {
        let metadata = try? NSPersistentStoreCoordinator.metadataForPersistentStore(ofType: NSSQLiteStoreType, at: storeURL, options: nil)
        
        guard let metadata = metadata, let currentModel = compatibleModelForStoreMetadata(metadata) else {
            return
        }

        do {
            let persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: currentModel)
            let options = [NSSQLitePragmasOption: ["journal_mode": "DELETE"]]
            let store = try persistentStoreCoordinator.addPersistentStore(type: .sqlite, at: storeURL, options: options)
            try persistentStoreCoordinator.remove(store)
        } catch {
            if let error = error as NSError? {
                DataMigrator.logger.error("failed to force WAL checkpointing, error: \(error)")
            }
        }
    }
    
    func migrate() -> Void {
        guard let sourceModel = self.sourceModel, let destinationModel = self.destinationModel else {
            return
        }
        
        guard let storeURL = self.storeURL else {
            return
        }
        
        forceWALCheckpointingForStore(at: storeURL)
        
        let destinationURL = temporaryDirectory.appendingPathComponent("PubChemSolution.sqlite")
        
        let migrationManager = NSMigrationManager(sourceModel: sourceModel, destinationModel: destinationModel)
        let mappingModel = NSMappingModel(from: nil, forSourceModel: sourceModel, destinationModel: destinationModel)
        
        do {
            try migrationManager.migrateStore(from: storeURL, type: .sqlite, options: nil, mapping: mappingModel!, to: destinationURL, type: .sqlite, options: nil)
        } catch {
            if let error = error as NSError? {
                DataMigrator.logger.error("Cannot migrate persistent stores from \(storeURL) to \(destinationURL) with using \(mappingModel.debugDescription): \(error)")
            }
        }
        
        replaceStore(at: storeURL, with: destinationURL)
        destoryStore(at: destinationURL)
    }
    
    private func replaceStore(at storeURL: URL, with replacingStoreURL: URL) {
        do {
            let persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: NSManagedObjectModel())
            try persistentStoreCoordinator.replacePersistentStore(at: storeURL, destinationOptions: nil, withPersistentStoreFrom: replacingStoreURL, sourceOptions: nil, type: .sqlite)
            
        } catch {
            if let error = error as NSError? {
                DataMigrator.logger.error("failed to replace persistent store at \(storeURL) with \(replacingStoreURL), error: \(error)")
            }
        }
    }
    
    private func destoryStore(at storeURL: URL) {
        do {
            let persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: NSManagedObjectModel())
            try persistentStoreCoordinator.destroyPersistentStore(at: storeURL, type: .sqlite, options: nil)
        } catch {
            if let error = error as NSError? {
                DataMigrator.logger.error("failed to destroy persistent store at \(storeURL), error: \(error)")
            }
        }
    }
}

