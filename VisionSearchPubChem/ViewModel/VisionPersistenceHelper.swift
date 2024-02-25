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

class VisionPersistenceHelper {
    private static let logger = Logger()
    
    private let persistence: Persistence
    var viewContext: NSManagedObjectContext {
        persistence.container.viewContext
    }
    
    init(persistence: Persistence) {
        self.persistence = persistence
    }
    
    func save(completionHandler: @escaping (Result<Void, Error>) -> Void) -> Void {
        persistence.save { completionHandler($0) }
    }
    
    func delete(_ object: NSManagedObject) -> Void {
        viewContext.delete(object)
    }
    
    func saveCompound(_ name: String, properties: Properties, imageData: Data?, conformer: Conformer?, completionHandler: @escaping (Result<Void, Error>) -> Void) -> Void {
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
        
        save { completionHandler($0) }
    }
    
    func saveNewTag(_ name: String, for compound: Compound, completionHandler: @escaping (Result<CompoundTag, Error>) -> Void) -> Void {
        let newTag = CompoundTag(context: viewContext)
        newTag.compoundCount = 1
        newTag.name = name
        newTag.addToCompounds(compound)
        
        save() { result in
            switch result {
            case .success(_):
                completionHandler(.success(newTag))
            case .failure(let error):
                completionHandler(.failure(error))
            }
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
    
    func preloadData(completionHandler: @escaping (Result<Void, Error>) -> Void) -> Void {
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
        
        save() { completionHandler($0) }
    }
}
