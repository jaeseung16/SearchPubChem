//
//  PersistenceHelper.swift
//  SearchPubChem
//
//  Created by Jae Seung Lee on 7/2/23.
//  Copyright © 2023 Jae Seung Lee. All rights reserved.
//

import Foundation
import CoreData
import os
import Persistence

final class PersistenceHelper: Sendable {
    private static let logger = Logger()
    
    private let persistence: Persistence
    var viewContext: NSManagedObjectContext {
        persistence.container.viewContext
    }
    
    init(persistence: Persistence) {
        self.persistence = persistence
    }
    
    func save() async throws -> Void {
        try await persistence.save()
    }
    
    func save(completionHandler: @escaping @Sendable (Result<Void, Error>) -> Void) -> Void {
        Task {
            do {
                try await save()
                completionHandler(.success(()))
            } catch {
                completionHandler(.failure(error))
            }
        }
    }
    
    func delete(_ object: NSManagedObject) -> Void {
        viewContext.delete(object)
    }
    
    func save(compound name: String, properties: Properties, image: Data?, conformer: Conformer?) async throws -> Void {
        let compound = Compound(context: viewContext)
        compound.name = name
        compound.firstCharacterInName = String(compound.name!.first!).uppercased()
        compound.formula = properties.MolecularFormula
        compound.molecularWeight = Double(properties.MolecularWeight)!
        compound.cid = "\(properties.CID)"
        compound.nameIUPAC = properties.IUPACName
        compound.image = image
        compound.conformerDownloaded = true
            
        let conformerEntity = ConformerEntity(context: viewContext)
        if let conformer = conformer {
            conformerEntity.conformerId = conformer.conformerId
            
            for atom in conformer.atoms {
                let atomEntity = AtomEntity(context: viewContext)
                atomEntity.atomicNumber = Int16(atom.number)
                atomEntity.coordX = atom.location[0]
                atomEntity.coordY = atom.location[1]
                atomEntity.coordZ = atom.location[2]
                atomEntity.conformer = conformerEntity
                
                conformerEntity.addToAtoms(atomEntity)
            }
            
            compound.addToConformers(conformerEntity)
        }
        
        try await save()
    }
    
    func saveCompound(_ name: String, properties: Properties, imageData: Data?, conformer: Conformer?) async throws -> Void {
        let compound = Compound(context: viewContext)
        compound.name = name
        compound.firstCharacterInName = String(compound.name!.first!).uppercased()
        compound.formula = properties.MolecularFormula
        compound.molecularWeight = Double(properties.MolecularWeight)!
        compound.cid = "\(properties.CID)"
        compound.nameIUPAC = properties.IUPACName
        compound.image = imageData
        compound.conformerDownloaded = true
        
        let conformerEntity = ConformerEntity(context: viewContext)
        if let conformer = conformer {
            conformerEntity.conformerId = conformer.conformerId
            
            for atom in conformer.atoms {
                let atomEntity = AtomEntity(context: viewContext)
                atomEntity.atomicNumber = Int16(atom.number)
                atomEntity.coordX = atom.location[0]
                atomEntity.coordY = atom.location[1]
                atomEntity.coordZ = atom.location[2]
                atomEntity.conformer = conformerEntity
                
                conformerEntity.addToAtoms(atomEntity)
            }
            
            compound.addToConformers(conformerEntity)
        }
        
        try await save()
        return
    }
    
    func saveSolution(_ label: String, ingradients: [SolutionIngradientDTO]) async throws -> Void {
        let solution = Solution(context: viewContext)
        solution.name = label
        
        for ingradient in ingradients {
            let entity = SolutionIngradient(context: viewContext)
            
            entity.compound = ingradient.compound
            entity.compoundName = ingradient.compound.name
            entity.compoundCid = ingradient.compound.cid
            entity.amount = ingradient.amount
            entity.unit = ingradient.unit.rawValue
            
            solution.addToIngradients(entity)
            solution.addToCompounds(ingradient.compound)
        }
        
        try await save()
        return
    }
    
    func saveNewTag(_ name: String, for compoundId: NSManagedObjectID) async throws -> CompoundTag {
        if let compound = fetchObject(with: compoundId, in: viewContext) as? Compound {
            let newTag = CompoundTag(context: viewContext)
            newTag.compoundCount = 1
            newTag.name = name
            newTag.addToCompounds(compound)
            
            do {
                try await save()
                return newTag
            } catch let error {
                throw error
            }
        } else {
            throw SearchPubChemError.noCompoundsFound
        }
    }
   
    func perform<Element>(_ fetchRequest: NSFetchRequest<Element>) -> [Element] {
        var fetchedEntities = [Element]()
        do {
            fetchedEntities = try viewContext.fetch(fetchRequest)
        } catch {
            PersistenceHelper.logger.error("Failed to fetch with fetchRequest=\(fetchRequest, privacy: .public): error=\(error.localizedDescription, privacy: .public)")
        }
        return fetchedEntities
    }
    
    func preloadData() async throws -> Void {
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
        
        try await save()
        return
    }
    
    private func fetchObject(with objectID: NSManagedObjectID, in context: NSManagedObjectContext) -> NSManagedObject? {
        do {
            // Attempt to retrieve the object with the given NSManagedObjectID
            let managedObject = try context.existingObject(with: objectID)
            return managedObject
        } catch {
            // Handle any errors that occur during the fetch
            PersistenceHelper.logger.error("Error fetching object with ID \(objectID, privacy: .public): \(error.localizedDescription, privacy: .public)")
            return nil
        }
    }
}
