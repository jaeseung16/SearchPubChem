//
//  DataController.swift
//  SearchPubChem
//
//  Created by Jae Seung Lee on 2/23/18.
//  Copyright © 2018 Jae Seung Lee. All rights reserved.
//

import Foundation
import CoreData

class DataController {
    // MARK: Properties
    // Constants
    let persistentContainer: NSPersistentContainer
    
    // Variables
    var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    // MARK: - Methods
    init(modelName: String) {
        persistentContainer = NSPersistentCloudKitContainer(name: modelName)
        load()
    }
    
    private func configureContexts() {
        viewContext.automaticallyMergesChangesFromParent = true
        viewContext.mergePolicy = NSMergePolicy.mergeByPropertyStoreTrump
    }
    
    private func load(completion: (() -> Void)? = nil) {
        let description = persistentContainer.persistentStoreDescriptions.first
        description?.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        description?.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        description?.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(containerIdentifier: "iCloud.com.resonance.jlee.SearchPubChem")
        
        persistentContainer.loadPersistentStores { (storeDescription, error) in
            if let error = error as NSError? {
                if let error = error as NSError? {
                    PersistenceController.logger.error("Could not load persistent store: \(storeDescription), \(error), \(error.userInfo)")
                } else {
                    let description = NSPersistentStoreDescription()
                    description.shouldMigrateStoreAutomatically = false
                    description.shouldInferMappingModelAutomatically = true
                    self.persistentContainer.persistentStoreDescriptions.append(description)
                }
            }
            self.autoSaveViewContext(interval: 30)
            self.configureContexts()
            completion?()
        }
        
        print("persistentStores = \(persistentContainer.persistentStoreCoordinator.persistentStores)")
        
        persistentContainer.viewContext.name = "SearchPubChem"
        purgeHistory()
    }
    
    private func purgeHistory() {
        let sevenDaysAgo = Date(timeIntervalSinceNow: TimeInterval(exactly: -604_800)!)
        let purgeHistoryRequest = NSPersistentHistoryChangeRequest.deleteHistory(before: sevenDaysAgo)

        do {
            try persistentContainer.newBackgroundContext().execute(purgeHistoryRequest)
        } catch {
            if let error = error as NSError? {
                PersistenceController.logger.error("Could not purge history: \(error), \(error.userInfo)")
            }
        }
    }
}

extension DataController  {
    func dropAllData() throws {
        // delete all the objects in the db. This won't delete the files, it will just leave empty tables.
        let persistentStoreCoordinator = persistentContainer.persistentStoreCoordinator
        let persistentStore = persistentStoreCoordinator.persistentStores[0]
        let urlForPersistentStore = persistentStoreCoordinator.url(for: persistentStore)
        
        try persistentStoreCoordinator.destroyPersistentStore(at: urlForPersistentStore, ofType: NSSQLiteStoreType, options: nil)
        try persistentStoreCoordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: urlForPersistentStore, options: nil)
    }

    private func autoSaveViewContext(interval: TimeInterval = 30) {
        guard interval > 0 else {
            NSLog("The autosave interval cannot be negative.")
            return
        }
        
        if viewContext.hasChanges {
            do {
                try viewContext.save()
            } catch {
                NSLog("Failed to autosave: \(error.localizedDescription)")
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + interval) {
            self.autoSaveViewContext(interval: interval)
        }
    }
}
