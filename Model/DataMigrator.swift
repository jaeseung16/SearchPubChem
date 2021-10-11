//
//  DataMigrator.swift
//  SearchPubChem
//
//  Created by Jae Seung Lee on 10/10/21.
//  Copyright © 2021 Jae Seung Lee. All rights reserved.
//

import Foundation
import CoreData

class DataMigrator {
    static let shared = DataMigrator()
    
    let sourceModelName = "PubChemSolution.momd/PubChemSolution v3"
    let destinationModelName = "PubChemSolution.momd/PubChemSolution v4"
    let modelExtension = "mom"
    
    let storeFilename = "PubChemSolution.sqlite"
    
    //let persistentContainer: NSPersistentContainer
    
    init() {
        //persistentContainer = NSPersistentContainer(name: "PubChemSolution")
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
        applicationSupportDirectory.appendingPathComponent("PubChemSolution.sqlite")
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
        guard let sourceModel = self.sourceModel, let destinationModel = self.destinationModel else {
            return false
        }
        
        guard let storeURL = self.storeURL, let sourceMetaData = self.sourceMetadata(storeURL: storeURL) else {
            return false
        }
        
        print("sourceModel.entityVersionHashesByName = \(sourceModel.entityVersionHashesByName)")
        
        for entityVersionHash in sourceModel.entityVersionHashesByName {
            print("\(entityVersionHash.key): \(entityVersionHash.value) \(entityVersionHash.value.debugDescription) \(entityVersionHash.value.hashValue)")
        }
        
        print("storeURL = \(storeURL)")
        print("sourceMetaData = \(sourceMetaData)")
        
        let isMigrationNecessary = !destinationModel.isConfiguration(withName: nil, compatibleWithStoreMetadata: sourceMetaData)
        
        print("isMigrationNecessary = \(isMigrationNecessary)")
        return isMigrationNecessary
    }
    
    enum PubChemSolutionVersion: String, CaseIterable {
        case v1 = "PubChemSolution.momd/PubChemSolution"
        case v2 = "PubChemSolution.momd/PubChemSolution v2"
        case v3 = "PubChemSolution.momd/PubChemSolution v3"
        case v4 = "PubChemSolution.momd/PubChemSolution v4"
    }
    
    private func compatibleModelForStoreMetadata(_ metadata: [String : Any]) -> NSManagedObjectModel? {
        /*
        print("metadata = \(metadata)")
        
        if let versionHashes = metadata[NSStoreModelVersionHashesKey] as? [String: Any] {
            for key in versionHashes.keys {
                print("\(key), \(versionHashes[key])")
                
                if let data = versionHashes[key] as? Data {
                    print("\(data.base64EncodedString())")
                }
            }
        }
        */
        
        if let sourceModel = self.sourceModel, sourceModel.isConfiguration(withName: nil, compatibleWithStoreMetadata: metadata) {
            return sourceModel
        } else {
            return nil
        }
        
        /*
        for version in PubChemSolutionVersion.allCases {
            print("version = \(version.rawValue)")
            if let momURL = Bundle.main.url(forResource: version.rawValue, withExtension: modelExtension), let model = NSManagedObjectModel(contentsOf: momURL) {
                
                print("model.entityVersionHashesByName = \(model.entityVersionHashesByName)")
                for entityVersionHash in model.entityVersionHashesByName {
                    print("\(entityVersionHash.key): \(entityVersionHash.value.hashValue) \(entityVersionHash.value.base64EncodedString(options: []))")
                }
                
                if model.isConfiguration(withName: nil, compatibleWithStoreMetadata: metadata) {
                    return model
                }
            }
        }
        print("returning nil")
        return nil
        */
    }
    
    func forceWALCheckpointingForStore(at storeURL: URL) {
        let metadata = try? NSPersistentStoreCoordinator.metadataForPersistentStore(ofType: NSSQLiteStoreType, at: storeURL, options: nil)
        
        guard let metadata = metadata, let currentModel = compatibleModelForStoreMetadata(metadata) else {
            print("currentModel = nil")
            return
        }

        print("currentModel = \(currentModel)")
        
        do {
            let persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: currentModel)
            let options = [NSSQLitePragmasOption: ["journal_mode": "DELETE"]]
            let store = try persistentStoreCoordinator.addPersistentStore(type: .sqlite, at: storeURL, options: options)
            try persistentStoreCoordinator.remove(store)
        } catch {
            if let error = error as NSError? {
                fatalError("failed to force WAL checkpointing, error: \(error)")
                //print("Cannot migrate: \(error)")
            }
        }
    }
    
    func makeCopy() -> Void {
        guard let sourceModel = self.sourceModel, let storeURL = self.storeURL, let destinationModel = self.destinationModel else {
            return
        }
        
        forceWALCheckpointingForStore(at: storeURL)
        
        let temporaryPeristentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: sourceModel)
        let temporaryStoreURL = temporaryDirectory.appendingPathComponent(storeURL.lastPathComponent)
        
        print("metadataForPersistentStore=\(try? NSPersistentStoreCoordinator.metadataForPersistentStore(type: .sqlite, at: storeURL, options: nil))")
        
        do {
            let originalStore = try temporaryPeristentStoreCoordinator.addPersistentStore(type: .sqlite, configuration: nil, at: storeURL, options: nil)
            
            let _ = try temporaryPeristentStoreCoordinator.migratePersistentStore(originalStore, to: temporaryStoreURL, options: [NSMigratePersistentStoresAutomaticallyOption: true, NSInferMappingModelAutomaticallyOption: true], type: .sqlite)
        } catch {
            if let error = error as NSError? {
                fatalError("Cannot copy persistent store from \(storeURL) to \(temporaryStoreURL): \(error)")
                //print("Cannot migrate: \(error)")
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
        
        print("sourceModel = \(sourceModel)")
        print("destinationModel = \(destinationModel)")
        
        forceWALCheckpointingForStore(at: storeURL)
        
        let destinationURL = temporaryDirectory.appendingPathComponent("PubChemSolution.sqlite")
        
        let migrationManager = NSMigrationManager(sourceModel: sourceModel, destinationModel: destinationModel)
        let mappingModel = NSMappingModel(from: nil, forSourceModel: sourceModel, destinationModel: destinationModel)
        
        print("migrationManager = \(migrationManager)")
        print("mappingModel = \(mappingModel)")
        
        do {
            try migrationManager.migrateStore(from: storeURL, type: .sqlite, options: nil, mapping: mappingModel!, to: destinationURL, type: .sqlite, options: nil)
        } catch {
            if let error = error as NSError? {
                fatalError("Cannot migrate: \(error)")
            }
        }
        
        replaceStore(at: storeURL, with: destinationURL)
        destoryStore(at: destinationURL)
    }
    
    private func replaceStore(at storeURL: URL, with replacingStoreURL: URL) {
        do {
            let persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: NSManagedObjectModel())
            try persistentStoreCoordinator.replacePersistentStore(at: storeURL, destinationOptions: nil, withPersistentStoreFrom: replacingStoreURL, sourceOptions: nil, type: .sqlite)
            
        } catch let error {
            fatalError("failed to replace persistent store at \(storeURL) with \(replacingStoreURL), error: \(error)")
        }
    }
    
    private func destoryStore(at storeURL: URL) {
        do {
            let persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: NSManagedObjectModel())
            try persistentStoreCoordinator.destroyPersistentStore(at: storeURL, type: .sqlite, options: nil)
        } catch let error {
            fatalError("failed to destroy persistent store at \(storeURL), error: \(error)")
        }
    }
}

