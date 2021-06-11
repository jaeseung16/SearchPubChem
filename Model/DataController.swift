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
        persistentContainer = NSPersistentContainer(name: modelName)
    }
    
    private func configureContexts() {
        viewContext.automaticallyMergesChangesFromParent = true
        viewContext.mergePolicy = NSMergePolicy.mergeByPropertyStoreTrump
    }
    
    func load(completion: (() -> Void)? = nil) {
        persistentContainer.loadPersistentStores { (storeDescription, error) in
            guard error == nil else {
                fatalError(error!.localizedDescription)
            }
            self.autoSaveViewContext(interval: 30)
            self.configureContexts()
            completion?()
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
