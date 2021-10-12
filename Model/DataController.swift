//
//  DataController.swift
//  SearchPubChem
//
//  Created by Jae Seung Lee on 2/23/18.
//  Copyright © 2018 Jae Seung Lee. All rights reserved.
//

import Foundation
import CoreData
import os

class DataController {
    static let shared = DataController(modelName: "PubChemSolution")
    static let logger = Logger()
    
    // MARK: Properties
    // Constants
    var persistentContainer: NSPersistentContainer
    
    // Variables
    var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    // MARK: - Methods
    init(modelName: String) {
        persistentContainer = NSPersistentCloudKitContainer(name: modelName)
        load()
    }
    
    // Tunred off since CloudKit
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
                DataController.logger.error("Could not load persistent store: \(storeDescription), \(error), \(error.userInfo)")
            }
        }
        
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
                DataController.logger.error("Could not purge history: \(error), \(error.userInfo)")
            }
        }
    }
    
    func preloadData() {
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
        
        saltyWater.addToCompounds(water)
        saltyWater.addToIngradients(waterIngradient)
        saltyWater.addToCompounds(sodiumChloride)
        saltyWater.addToIngradients(sodiumChlorideIngradient)
        
        // Load additional compounds
        let recordLoader = RecordLoader(viewContext: viewContext)
        recordLoader.loadRecords()
        
        do {
            try viewContext.save()
        } catch {
            NSLog("Error while saving by AppDelegate")
        }
    }
}
