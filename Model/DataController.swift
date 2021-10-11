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
    static let shared = DataController(modelName: "PubChemSolution")
    
    // MARK: Properties
    // Constants
    var persistentContainer: NSPersistentContainer
    
    // Variables
    var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    // MARK: - Methods
    init(modelName: String) {
        let dataMigrator = DataMigrator.shared
        let isMigrationNecessary = dataMigrator.isMigrationNecessary()
        if isMigrationNecessary {
            //dataMigrator.makeCopy()
            dataMigrator.migrate()
        }
        
        persistentContainer = NSPersistentContainer(name: modelName)
        load()
    }
    
    private func configureContexts() {
        viewContext.automaticallyMergesChangesFromParent = true
        viewContext.mergePolicy = NSMergePolicy.mergeByPropertyStoreTrump
    }
    
    private func load(completion: (() -> Void)? = nil) {
        let description = persistentContainer.persistentStoreDescriptions.first
        //description?.shouldMigrateStoreAutomatically = true
        //description?.shouldInferMappingModelAutomatically = true
        //description?.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        //description?.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        //description?.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(containerIdentifier: "iCloud.com.resonance.jlee.SearchPubChem")
        //print("description=\(description)")
        
        persistentContainer.loadPersistentStores { (storeDescription, error) in
            if let error = error as NSError? {
                PersistenceController.logger.error("Could not load persistent store: \(storeDescription), \(error), \(error.userInfo)")
                
                /*
                if error.domain == NSCocoaErrorDomain && error.code == CocoaError.Code.persistentStoreIncompatibleVersionHash.rawValue {
                    print("try migrate")
                }
                */
            }
            
            //self.autoSaveViewContext(interval: 30)
            //self.configureContexts()
            //completion?()
        }
        
        print("persistentStores = \(persistentContainer.persistentStoreCoordinator.persistentStores)")
        
        print("HasLaunchedBefore = \(UserDefaults.standard.bool(forKey: "HasLaunchedBefore"))")
        print("HasDBMigrated = \(UserDefaults.standard.bool(forKey: "HasDBMigrated"))")
        
        persistentContainer.viewContext.name = "SearchPubChem"
        
        preloadData()
        //purgeHistory()
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
    
    func checkIfFirstLaunch() {
        DispatchQueue.main.async {
            print("checkIfFirstLaunch()")
            if !UserDefaults.standard.bool(forKey: "HasLaunchedBefore") {
                print("First Launch")
                UserDefaults.standard.set(true, forKey: "HasLaunchedBefore")
                UserDefaults.standard.synchronize()
                self.preloadData()
                //saveData()
            }
        }
    }
    
    private func preloadData() {
        print("preloadData 1")
        do {
            try dropAllData()
        } catch {
            NSLog("Error while dropping all objects in DB")
        }
        
        print("preloadData 2")
        
        // Example Compound 1: Water
        let water = Compound(context: viewContext)
        water.name = "water"
        water.firstCharacterInName = "W"
        water.formula = "H2O"
        water.molecularWeight = 18.015
        water.cid = "962"
        water.nameIUPAC = "oxidane"
        water.image = try? Data(contentsOf: Bundle.main.url(forResource: "962_water", withExtension: "png")!, options: [])
        
        // Example Compound 2: Sodium Chloride
        let sodiumChloride = Compound(context: viewContext)
        sodiumChloride.name = "sodium chloride"
        sodiumChloride.firstCharacterInName = "S"
        sodiumChloride.formula = "NaCl"
        sodiumChloride.molecularWeight = 58.44
        sodiumChloride.cid = "5234"
        sodiumChloride.nameIUPAC = "sodium chloride"
        sodiumChloride.image = try? Data(contentsOf: Bundle.main.url(forResource: "5234_sodium chloride", withExtension: "png")!, options: [])

        // Example Solution: Sodium Chloride Aqueous Solution
        let waterIngradient = SolutionIngradient(context: viewContext)
        waterIngradient.compound = water
        waterIngradient.amount = 1.0
        waterIngradient.unit = "gram"
        
        let sodiumChlorideIngradient = SolutionIngradient(context: viewContext)
        sodiumChlorideIngradient.compound = sodiumChloride
        sodiumChlorideIngradient.amount = 0.05
        sodiumChlorideIngradient.unit = "gram"
        
        let saltyWater = Solution(context: viewContext)
        saltyWater.name = "sakty water"
        saltyWater.ingradients = NSSet(array: [waterIngradient, sodiumChlorideIngradient])
        
        waterIngradient.solution = saltyWater
        sodiumChlorideIngradient.solution = saltyWater
        
        // Load additional compounds
        let recordLoader = RecordLoader(viewContext: viewContext)
        recordLoader.loadRecords()
        
        do {
            try viewContext.save()
        } catch {
            NSLog("Error while saving by AppDelegate")
        }
    }
    
    private func dropAllData() throws {
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
