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
        
        print("createRelationships")
        print("createRelationships: dInstance = \(dInstance)")
        print("createRelationships: mapping.name = \(mapping.name)")
        
        if dInstance.entity.name == "Solution" {
            let sInstance = manager.sourceInstances(forEntityMappingName: mapping.name, destinationInstances: [dInstance]).first!
            
            let sCompounds = sInstance.value(forKey: "compounds") as! NSSet
            print("createRelationships: sIntance.compounds.count = \(sCompounds.count)")
            
            let ingradients = dInstance.value(forKey: "ingradients") as! NSSet
            
            var dCompounds = [NSManagedObject]()
            for index in 0..<sCompounds.count {
                let dCompound = manager.destinationInstances(forEntityMappingName: "CompoundToCompound", sourceInstances: [sCompounds.allObjects[index] as! NSManagedObject]).first!
                print("createRelationships: dCompound.name = \(dCompound.primitiveValue(forKey: "name"))")
                
                
                let ingradient = ingradients.allObjects[index] as! NSManagedObject
                ingradient.setValue(dCompound, forKey: "compound")
                
                dCompounds.append(dCompound)
                 
            }
            
            dInstance.setValue(NSSet(array: dCompounds), forKey: "compounds")
            
            /*
            let newCompoundFetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Compound")
            //newCompoundFetchRequest.predicate = NSPredicate(format: "solutions CONTAINS %@", argumentArray: [dInstance])
            let compounds = try! manager.destinationContext.fetch(newCompoundFetchRequest) as! [NSManagedObject]
            
            // let compounds = dInstance.value(forKey: "compounds") as! NSSet
            
            
            print("createRelationships: compounds.count = \(compounds.count)")
            print("createRelationships: ingradients.count = \(ingradients.count)")
            
            for index in 0..<ingradients.count {
                let compound = compounds[index]
                let ingradient = ingradients.allObjects[index] as! NSManagedObject
                
                print("createRelationships: compound.name = \(compound.primitiveValue(forKey: "name"))")
                print("createRelationships: ingradient.amount = \(ingradient.primitiveValue(forKey: "amount"))")
                
                print("createRelationships: solutions = \(compound.value(forKey: "solutions"))")
            }
             */
        }
        
    }
    
    override func createDestinationInstances(forSource sInstance: NSManagedObject, in mapping: NSEntityMapping, manager: NSMigrationManager) throws {
        print("manger = \(manager)")
        print("mapping = \(mapping)")
        
        if sInstance.entity.name == "Solution" {
            print("sInstance = \(sInstance)")
            
            let name = sInstance.primitiveValue(forKey: "name")
            let amount = sInstance.primitiveValue(forKey: "amount") as? [String: Double]
            let created = sInstance.primitiveValue(forKey: "created")
            
            let compounds = sInstance.value(forKey: "compounds") as! NSSet
            
            print("compounds.allObjects = \(compounds.allObjects)")
            
            let newSolution = NSEntityDescription.insertNewObject(forEntityName: "Solution", into: manager.destinationContext)
            
            newSolution.setPrimitiveValue(created, forKey: "created")
            newSolution.setPrimitiveValue(name, forKey: "name")
            
            //try? self.createRelationships(forDestination: newSolution, in: mapping, manager: manager)
            
            for index in 0..<compounds.count {
                let compound = compounds.allObjects[index] as! NSManagedObject
                let name = compound.primitiveValue(forKey: "name") as! String
                
                let ingradient = NSEntityDescription.insertNewObject(forEntityName: "SolutionIngradient", into: manager.destinationContext)
                
                ingradient.setPrimitiveValue(amount![name], forKey: "amount")
                ingradient.setValue("gram", forKey: "unit")

                ingradient.setValue(newSolution, forKey: "solution")
                
                print("ingradient=\(ingradient)")
            }
            
            manager.associate(sourceInstance: sInstance, withDestinationInstance: newSolution, for: mapping)
        }
    }
}
