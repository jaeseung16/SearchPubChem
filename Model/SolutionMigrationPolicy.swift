//
//  SolutionMigrationPolicy.swift
//  SearchPubChem
//
//  Created by Jae Seung Lee on 10/8/21.
//  Copyright © 2021 Jae Seung Lee. All rights reserved.
//

import Foundation
import CoreData

class SolutionMigrationPolicy: NSEntityMigrationPolicy {
    override func createRelationships(forDestination dInstance: NSManagedObject, in mapping: NSEntityMapping, manager: NSMigrationManager) throws {
        if dInstance.entity.name == "Solution" {
            // From the relationship between source Compound and Solution,
            // recreate the relationships between destination Compound and Solution as well as between destination Compound and SolutionIngradient
            let sInstance = manager.sourceInstances(forEntityMappingName: mapping.name, destinationInstances: [dInstance]).first!
            let sCompounds = sInstance.value(forKey: "compounds") as! NSSet
            let ingradients = dInstance.value(forKey: "ingradients") as! NSSet
            
            var dCompounds = [NSManagedObject]()
            for index in 0..<sCompounds.count {
                let dCompound = manager.destinationInstances(forEntityMappingName: "CompoundToCompound", sourceInstances: [sCompounds.allObjects[index] as! NSManagedObject]).first!
                
                let name = dCompound.primitiveValue(forKey: "name") as! String
                let cid = dCompound.primitiveValue(forKey: "cid") as! String
                
                for ingradient in ingradients {
                    let ingradient = ingradient as! NSManagedObject
                    let compoundName = ingradient.primitiveValue(forKey: "compoundName") as! String
                    let compoundCid = ingradient.primitiveValue(forKey: "compoundCid") as! String
                    
                    if name == compoundName && cid == compoundCid {
                        ingradient.setValue(dCompound, forKey: "compound")
                    }
                }
                
                dCompounds.append(dCompound)
            }
            
            dInstance.setValue(NSSet(array: dCompounds), forKey: "compounds")
        }
    }
    
    override func createDestinationInstances(forSource sInstance: NSManagedObject, in mapping: NSEntityMapping, manager: NSMigrationManager) throws {
        if sInstance.entity.name == "Solution" {
            let name = sInstance.primitiveValue(forKey: "name")
            let amount = sInstance.primitiveValue(forKey: "amount") as? [String: Double]
            let created = sInstance.primitiveValue(forKey: "created")
            let compounds = sInstance.value(forKey: "compounds") as! NSSet
            
            let newSolution = NSEntityDescription.insertNewObject(forEntityName: "Solution", into: manager.destinationContext)
            newSolution.setPrimitiveValue(created, forKey: "created")
            newSolution.setPrimitiveValue(name, forKey: "name")
            
            for index in 0..<compounds.count {
                let compound = compounds.allObjects[index] as! NSManagedObject
                let name = compound.primitiveValue(forKey: "name") as! String
                let cid = compound.primitiveValue(forKey: "cid") as! String
                
                let ingradient = NSEntityDescription.insertNewObject(forEntityName: "SolutionIngradient", into: manager.destinationContext)
                
                ingradient.setPrimitiveValue(name, forKey: "compoundName")
                ingradient.setPrimitiveValue(cid, forKey: "compoundCid")
                ingradient.setPrimitiveValue(amount![name], forKey: "amount")
                ingradient.setPrimitiveValue("gram", forKey: "unit")

                ingradient.setValue(newSolution, forKey: "solution")
            }
            
            // This will trigger the next phase to create relationships
            manager.associate(sourceInstance: sInstance, withDestinationInstance: newSolution, for: mapping)
        }
    }
}
