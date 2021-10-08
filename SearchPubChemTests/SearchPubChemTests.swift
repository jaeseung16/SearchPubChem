//
//  SearchPubChemTests.swift
//  SearchPubChemTests
//
//  Created by Jae Seung Lee on 1/15/18.
//  Copyright © 2018 Jae Seung Lee. All rights reserved.
//

import XCTest
import CoreData
@testable import SearchPubChem

class SearchPubChemTests: XCTestCase {
    
    private var url: URL {
        return self.getDocumentsDirectory().appendingPathComponent("PubChemSolutionTestURL.sqlite")
    }
    private var newUrl: URL {
        return self.getDocumentsDirectory().appendingPathComponent("PubChemSolutionTestURLNew.sqlite")
    }
    
    // helper to get the doctuments dir
    private func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }
    
    // remore the test sqlite file
    private func clearData() {
        try? FileManager.default.removeItem(at: self.url)
        try? FileManager.default.removeItem(at: self.newUrl)
    }

    override func setUp() {
        self.clearData()
    }

    override func tearDown() {
        //self.clearData()
    }
   
    func testHeavyWeightMigration() {
        // MARK: 1 - read and load the old model
        let oldModelURL = Bundle(for: AppDelegate.self).url(forResource: "PubChemSolution.momd/PubChemSolution v3", withExtension: "mom")!
        let oldManagedObjectModel = NSManagedObjectModel(contentsOf: oldModelURL)
        XCTAssertNotNil(oldManagedObjectModel)
        
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: oldManagedObjectModel!)
        
        try! coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: url, options: nil)
        
        let managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = coordinator
        
        // MARK: 2 - adding a person to the old db
        // Example Compound 1: Water
        let water = NSEntityDescription.insertNewObject(forEntityName: "Compound", into: managedObjectContext)
        water.setValue("water", forKey: "name")
        water.setValue("W", forKey: "firstCharacterInName")
        water.setValue("H2O", forKey: "formula")
        water.setValue(18.015, forKey: "molecularWeight")
        water.setValue("962", forKey: "cid")
        water.setValue("oxidane", forKey: "nameIUPAC")
       
        // Example Compound 2: Sodium Chloride
        let sodiumChloride = NSEntityDescription.insertNewObject(forEntityName: "Compound", into: managedObjectContext)
        sodiumChloride.setValue("sodium chloride", forKey: "name")
        sodiumChloride.setValue("S", forKey: "firstCharacterInName")
        sodiumChloride.setValue("NaCl", forKey: "formula")
        sodiumChloride.setValue(58.44, forKey: "molecularWeight")
        sodiumChloride.setValue("5234", forKey: "cid")
        sodiumChloride.setValue("sodium chloride", forKey: "nameIUPAC")
        
        // Example Solution: Sodium Chloride Aqueous Solution
        let saltyWater = NSEntityDescription.insertNewObject(forEntityName: "Solution", into: managedObjectContext)
        saltyWater.setValue("salty water", forKey: "name")
        saltyWater.setValue(NSSet(array: [water, sodiumChloride]), forKey: "compounds")
        
        let amounts = ["water": 1.0, "sodium chloride": 0.05]
        saltyWater.setValue(amounts, forKey: "amount")
        
        try! managedObjectContext.save()
        
        
        // MARK: 3 - migrate the store to the new model version
        let newModelURL = Bundle(for: AppDelegate.self).url(forResource: "PubChemSolution.momd/PubChemSolution v4", withExtension: "mom")!
        let newManagedObjectModel = NSManagedObjectModel(contentsOf: newModelURL)
        
        let mappingModel = NSMappingModel(from: nil, forSourceModel: oldManagedObjectModel, destinationModel: newManagedObjectModel)
        let migrationManager = NSMigrationManager(sourceModel: oldManagedObjectModel!, destinationModel: newManagedObjectModel!)
        
        try! migrationManager.migrateStore(from: self.url, sourceType: NSSQLiteStoreType, options: nil, with: mappingModel, toDestinationURL: self.newUrl, destinationType: NSSQLiteStoreType, destinationOptions: nil)
        
        let newCoordinbator = NSPersistentStoreCoordinator(managedObjectModel: newManagedObjectModel!)
        try! newCoordinbator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: self.newUrl, options: nil)
        let newManagedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        newManagedObjectContext.persistentStoreCoordinator = newCoordinbator
        
        
        // MARK: 4 - test the migration
        let newSolutionRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Solution")
        let newSolution = try! newManagedObjectContext.fetch(newSolutionRequest) as! [NSManagedObject]
        
        XCTAssertEqual(newSolution.count, 1)
        
        let newSaltyWater = newSolution.first!
        
        print("SearchPubChemTests: newSaltyWater = \(newSaltyWater)")
        
        XCTAssertEqual(newSaltyWater.value(forKey: "name") as? String, "salty water")
        
        let compounds = newSaltyWater.value(forKey: "compounds") as! NSSet
        
        //print("SearchPubChemTests: compounds = \(compounds)")
        print("SearchPubChemTests: compounds.count = \(compounds.count)")
        
        for index in 0..<compounds.count {
            let compound = compounds.allObjects[index] as! NSManagedObject
            let name = compound.primitiveValue(forKey: "name") as! String
            
            let ingradients = compound.value(forKey: "ingradients") as! NSSet
            let solutions = compound.value(forKey: "solutions") as! NSSet
            
            print("SearchPubChemTests: name=\(name)")
            print("SearchPubChemTests: ingradients.count=\(String(describing: ingradients.count))")
            print("SearchPubChemTests: solutions.count=\(String(describing: solutions.count))")
            //ingradient.setValue(compound, forKey: "compound")
            //ingradient.setValue(solution, forKey: "solution")
        }
        
        /*
        let ingradients = newSaltyWater.value(forKey: "ingradients") as! NSSet
        print("SearchPubChemTests: ingradients = \(ingradients)")
        print("SearchPubChemTests: ingradients.count = \(ingradients.count)")
        
        for ingradient in ingradients {
            let ingradient = ingradient as! NSManagedObject
            print("SearchPubChemTests: ingradient = \(ingradient)")
            print("SearchPubChemTests: solution = \(ingradient.value(forKey: "solution"))")
            print("SearchPubChemTests: compound = \(ingradient.value(forKey: "compound"))")
        }
        
        
        let newCompoundRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Compound")
        let newCompounds = try! newManagedObjectContext.fetch(newCompoundRequest) as! [NSManagedObject]
        
        print("SearchPubChemTests: newCompounds = \(newCompounds)")
        print("SearchPubChemTests: newCompounds.count = \(newCompounds.count)")
        
        for compound in newCompounds {
            let compound = compound as! NSManagedObject
            print("SearchPubChemTests: compound.name = \(compound.primitiveValue(forKey: "name")))")
            
            let solutions = compound.value(forKey: "solutions") as! NSSet
            
            print("SearchPubChemTests: solutions.count = \(solutions.count)")
            
            let ingradients = compound.value(forKey: "ingradients") as! NSSet
            
            print("SearchPubChemTests: ingradients.count = \(ingradients.count)")
        }
        */
    }
    
}
