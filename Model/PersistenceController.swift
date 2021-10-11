//
//  PersistenceController.swift
//  SearchPubChem
//
//  Created by Jae Seung Lee on 10/3/21.
//  Copyright © 2021 Jae Seung Lee. All rights reserved.
//

import CoreData
import os

struct PersistenceController {
    static let shared = PersistenceController()
    static let logger = Logger()

    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        
        /*
        PersistenceController.save(viewContext: viewContext) { error in
            let nsError = error as NSError
            PersistenceController.logger.error("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        */
        return result
    }()

    let container: NSPersistentCloudKitContainer

    init(inMemory: Bool = false) {
        container = NSPersistentCloudKitContainer(name: "PubChemSolution")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        
        let description = container.persistentStoreDescriptions.first
        description?.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        description?.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        description?.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(containerIdentifier: "iCloud.com.resonance.jlee.SearchPubChem")
        
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                if let error = error as NSError? {
                    PersistenceController.logger.error("Could not load persistent store: \(storeDescription), \(error), \(error.userInfo)")
                }
            }
        })
        
        print("persistentStores = \(container.persistentStoreCoordinator.persistentStores)")
        
        container.viewContext.name = "SearchPubChem"
    }
    
    static func save(viewContext: NSManagedObjectContext, completionHandler: (Error) -> Void) {
        if viewContext.hasChanges {
            do {
                try viewContext.save()
            } catch {
                if let error = error as NSError? {
                    PersistenceController.logger.error("Could not save: \(error), \(error.userInfo)")
                }
                completionHandler(error)
            }
        }
    }
}

