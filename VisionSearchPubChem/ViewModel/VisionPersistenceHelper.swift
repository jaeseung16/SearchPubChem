//
//  VisionPersistenceHelper.swift
//  VisionSearchPubChem
//
//  Created by Jae Seung Lee on 2/25/24.
//  Copyright © 2024 Jae Seung Lee. All rights reserved.
//

import Foundation
import CoreData
import os
import Persistence

final class VisionPersistenceHelper: Sendable {
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
    
    func delete(_ object: NSManagedObject) -> Void {
        viewContext.delete(object)
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
    }
    
    func saveNewTag(_ name: String, for compoundId: NSManagedObjectID) async throws -> CompoundTag {
        if let compound = fetchObject(with: compoundId) as? Compound {
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
            VisionPersistenceHelper.logger.error("Failed to fetch with fetchRequest=\(fetchRequest, privacy: .public): error=\(error.localizedDescription, privacy: .public)")
        }
        return fetchedEntities
    }
    
    func preloadData() async throws -> Void {
        VisionPersistenceHelper.logger.log("Preloading Data...")
        
        await MainActor.run {
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
            saltyWater.name = "salty water"
            
            saltyWater.addToCompounds(water)
            saltyWater.addToIngradients(waterIngradient)
            saltyWater.addToCompounds(sodiumChloride)
            saltyWater.addToIngradients(sodiumChlorideIngradient)
        }
        
        try await save()
        
        // Load additional compounds
        // let recordLoader = RecordLoader(viewContext: viewContext)
        // recordLoader.loadRecords()
        
        try await loadRecords()
    }
    
    private func fetchObject(with objectID: NSManagedObjectID) -> NSManagedObject? {
        do {
            // Attempt to retrieve the object with the given NSManagedObjectID
            let managedObject = try viewContext.existingObject(with: objectID)
            return managedObject
        } catch {
            // Handle any errors that occur during the fetch
            VisionPersistenceHelper.logger.error("Error fetching object with ID \(objectID, privacy: .public): \(error.localizedDescription, privacy: .public)")
            return nil
        }
    }
    
    private func loadRecords() async throws {
        VisionPersistenceHelper.logger.log("loading records")
        guard let url = Bundle.main.url(forResource: "records", withExtension: "json") else {
            VisionPersistenceHelper.logger.log("Cannot find records.json")
            return
        }
        
        var records: Data?
        do {
            records = try Data(contentsOf: url, options: [])
            VisionPersistenceHelper.logger.log("records = \(String(describing: records))")
        } catch {
            VisionPersistenceHelper.logger.error("Cannot read the table: \(error.localizedDescription)")
        }
        
        guard let records = records else {
            VisionPersistenceHelper.logger.log("Cannot read records")
            return
        }
        
        let decoder = JSONDecoder()
        
        var compounds: [CompoundWrapper]?
        do {
            compounds = try decoder.decode([CompoundWrapper].self, from: records)
        } catch {
            VisionPersistenceHelper.logger.log("Cannot parse data as type \([CompoundWrapper].self): \(error.localizedDescription)")
            return
        }
        
        guard let compounds = compounds else {
            VisionPersistenceHelper.logger.log("No compounds")
            return
        }
        
        VisionPersistenceHelper.logger.log("\(compounds.count) compounds to load")
        
        for compound in compounds {
            await MainActor.run {
                VisionPersistenceHelper.logger.log("Processing compound: \(String(describing: compound.name))")
                let compoundEntity = Compound(context: viewContext)
                compoundEntity.cid = compound.cid
                compoundEntity.name = compound.name
                compoundEntity.nameIUPAC = compound.iupacName
                compoundEntity.formula = compound.molecularFormula
                compoundEntity.molecularWeight = Double(compound.molecularWeight) ?? 0.0
                compoundEntity.conformerDownloaded = compound.conformerDownloaded
                compoundEntity.firstCharacterInName = String(compound.name!.first!).uppercased()
                
                if let imageUrl = Bundle.main.url(forResource: "\(compound.cid!)_\(compound.name!)", withExtension: "png") {
                    var imageData: Data?
                    do {
                        imageData = try Data(contentsOf: imageUrl, options: [])
                        compoundEntity.image = imageData
                    } catch {
                        VisionPersistenceHelper.logger.log("Cannot read an image from \(imageUrl): \(error.localizedDescription)")
                    }
                } else {
                    VisionPersistenceHelper.logger.log("Cannot find \(compound.cid!)_\(compound.name!).png")
                }
                
                if !compound.conformers.isEmpty {
                    let conformer = compound.conformers[0]
                    let conformerEntity = ConformerEntity(context: viewContext)
                    conformerEntity.conformerId = conformer.conformerId
                
                    var atoms: [AtomEntity] = []
                    for atom in conformer.atoms {
                        let atomEntity = AtomEntity(context: viewContext)
                        atomEntity.atomicNumber = Int16(atom.atomicNumber)
                        atomEntity.coordX = atom.coordX
                        atomEntity.coordY = atom.coordY
                        atomEntity.coordZ = atom.coordZ
                        atoms.append(atomEntity)
                        
                    }
                    
                    conformerEntity.addToAtoms(NSSet(array: atoms))
                    compoundEntity.addToConformers(conformerEntity)
                }
                
                if !compound.compoundTags.isEmpty {
                    let allTags = fetchAllTags()
                    let tagsByName = Dictionary(uniqueKeysWithValues: allTags.map{ ($0.name!, $0) })
                    for compoundTag in compound.compoundTags {
                        if let tag = tagsByName[compoundTag] {
                            VisionPersistenceHelper.logger.log("tag=\(tag)")
                            tag.compoundCount += 1
                            tag.addToCompounds(compoundEntity)
                        } else {
                            let newTag = CompoundTag(context: viewContext)
                            newTag.name = compoundTag
                            newTag.compoundCount = 1
                            newTag.addToCompounds(compoundEntity)
                        }
                    }
                }
            }
            
            VisionPersistenceHelper.logger.log("Saving \(String(describing: compound.name))")
            try await save()
            VisionPersistenceHelper.logger.log("Saved \(String(describing: compound.name))")
        }
    }
    
    private func fetchAllTags() -> [CompoundTag] {
        let fetchRequet = NSFetchRequest<CompoundTag>(entityName: "CompoundTag")
        return perform(fetchRequet)
    }
    
}
