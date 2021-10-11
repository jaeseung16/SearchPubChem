//
//  RecordLoader.swift
//  SearchPubChem
//
//  Created by Jae Seung Lee on 6/6/21.
//  Copyright © 2021 Jae Seung Lee. All rights reserved.
//

import Foundation
import CoreData
import UIKit

class RecordLoader {
    var viewContext: NSManagedObjectContext
    
    init(viewContext: NSManagedObjectContext) {
        self.viewContext = viewContext
    }
    
    func loadRecords() {
        guard let url = Bundle.main.url(forResource: "records", withExtension: "json") else {
            print("Cannot find records.json")
            return
        }
        
        var records: Data?
        do {
            records = try Data(contentsOf: url, options: [])
            print("records = \(records)")
            
        } catch {
            print("Error: Cannot read the table.")
        }
        
        guard let records = records else {
            print("Cannot read records")
            return
        }
        
        let decoder = JSONDecoder()
        
        var compounds: [CompoundWrapper]?
        do {
            compounds = try decoder.decode([CompoundWrapper].self, from: records)
        } catch {
            print("Cannot parse data as type \([CompoundWrapper].self)")
            return
        }
        
        guard let compounds = compounds else {
            print("No compounds")
            return
        }
        
        var tags = [String: CompoundTag]()
        
        for compound in compounds {
            let compoundEntity = Compound(context: viewContext)
            compoundEntity.cid = compound.cid
            compoundEntity.name = compound.name
            compoundEntity.nameIUPAC = compound.iupacName
            compoundEntity.formula = compound.molecularFormula
            compoundEntity.molecularWeight = Double(compound.molecularWeight) ?? 0.0
            compoundEntity.conformerDownloaded = compound.conformerDownloaded
            compoundEntity.firstCharacterInName = String(compound.name!.first!).uppercased()
            
            if !compound.conformers.isEmpty {
                let conformer = compound.conformers[0]
                let conformerEntity = ConformerEntity(context: viewContext)
                conformerEntity.compound = compoundEntity
                conformerEntity.conformerId = conformer.conformerId
            
                for atom in conformer.atoms {
                    let atomEntity = AtomEntity(context: viewContext)
                    atomEntity.atomicNumber = Int16(atom.atomicNumber)
                    atomEntity.coordX = atom.coordX
                    atomEntity.coordY = atom.coordY
                    atomEntity.coordZ = atom.coordZ
                    atomEntity.conformer = conformerEntity
                }
            }
            
            if !compound.compoundTags.isEmpty {
                var compoundTags = Set<CompoundTag>()
                
                for compoundTag in compound.compoundTags {
                    if let tag = tags[compoundTag] {
                        tag.compoundCount += 1
                        compoundTags.insert(tag)
                    } else {
                        let newTag = CompoundTag(context: viewContext)
                        newTag.name = compoundTag
                        newTag.compoundCount = 1
                        
                        tags[compoundTag] = newTag
                        compoundTags.insert(newTag)
                    }
                }
                
                compoundEntity.tags = NSSet(set: compoundTags)
            }
            
            guard let imageUrl = Bundle.main.url(forResource: "\(compound.cid!)_\(compound.name!)", withExtension: "png") else {
                print("Cannot find \(compound.cid!)_\(compound.name!).png")
                continue
            }
            
            var imageData: Data?
            do {
                imageData = try Data(contentsOf: imageUrl, options: [])
            } catch {
                print("Error: Cannot read an image from \(imageUrl)")
            }
            
            compoundEntity.image = imageData
        }
    }
    
}
