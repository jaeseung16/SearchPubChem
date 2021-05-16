//
//  RecordDumper.swift
//  SearchPubChem
//
//  Created by Jae Seung Lee on 5/15/21.
//  Copyright © 2021 Jae Seung Lee. All rights reserved.
//

import Foundation
import CoreData

class RecordDumper {    
    var dataController: DataController
    
    //var compounds: [Compound]
    //var compoundTags: [CompoundTag]
    //var conformers: [Conformer]
    
    var cidToTags = [Int: [CompoundTag]]()
    
    init(dataController: DataController) {
        self.dataController = dataController
    }
    
    static func convert(from compound: Compound) -> CompoundWrapper? {
        guard let cid = compound.cid else {
            print("No cid in \(compound)")
            return nil
        }
        
        
        var conformerList = [CompoundWrapper.Conformer]()
        if let conformers = compound.conformers as? Set<ConformerEntity> {
            for conformer in conformers {
                var atomList = [CompoundWrapper.Atom]()
                if let atoms = conformer.atoms {
                    for atom in atoms {
                        if let atom = atom as? AtomEntity {
                            atomList.append(
                                CompoundWrapper.Atom(atomicNumber: Int(atom.atomicNumber),
                                                     coordX: atom.coordX,
                                                     coordY: atom.coordY,
                                                     coordZ: atom.coordZ)
                            )
                        }
                    }
                }
                conformerList.append(CompoundWrapper.Conformer(conformerId: conformer.conformerId, atoms: atomList))
            }
        }
        
        var tagList = [String]()
        if let tags = compound.tags as? Set<CompoundTag> {
            for tag in tags {
                if let name = tag.name {
                    tagList.append(name)
                }
            }
        }
        
        return CompoundWrapper(name: compound.name,
                               cid: cid,
                               iupacName: compound.nameIUPAC,
                               molecularFormula: compound.formula,
                               molecularWeight: String(compound.molecularWeight),
                               conformerDownloaded: compound.conformerDownloaded,
                               conformers: conformerList,
                               compoundTags: tagList)
    }
    
    static func convert(from compoundTag: CompoundTag) -> CompoundTagDTO? {
        
        var dto: CompoundTagDTO?
        if let name = compoundTag.name {
            dto = CompoundTagDTO(name: name)
        }
        
        return dto
    }
    
    func dumpRecords() {
        dumpCompounds()
        dumpTags()
        dumpConformers()
        dumpImages()
    }
    
    private func dumpCompounds() {
        let fetchRequest: NSFetchRequest<Compound> = Compound.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "name", ascending: true, selector: #selector(NSString.caseInsensitiveCompare))
        
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: "firstCharacterInName", cacheName: "compounds")
        
        do {
            try fetchedResultsController.performFetch()
        } catch {
            fatalError("Compounds cannot be fetched: \(error.localizedDescription)")
        }
        
        let encoder = JSONEncoder()
        
        var count = 0
        if let fetchedObejcts = fetchedResultsController.fetchedObjects {
            let dateFormatter = DateFormatter()
            dateFormatter.locale = Locale(identifier: "en_US_POSIX")
            dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
            dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
            
            var compounds = [CompoundWrapper]()
            
            for object in fetchedObejcts {
                let compoundWrapper = RecordDumper.convert(from: object)
                
                if let wrapper = compoundWrapper {
                    compounds.append(wrapper)
                }
                
                if let image = object.image {
                    let fileName = "\(object.cid!)_\(object.name!).png"
                    
                    if let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                        let pathWithFileName = documentDirectory.appendingPathComponent(fileName)
                        do {
                            try image.write(to: pathWithFileName)
                            print("Saved to \(pathWithFileName)")
                        } catch {
                            print("Cannot save to a file: \(fileName)") // handle error
                        }
                    }
                }
                
                /*
                var data: Data
                do {
                    data = try encoder.encode(compoundWrapper)
                } catch {
                    print("Cannot convert a record to dto: \(object)")
                    data = Data()
                }
                count += 1
                
                if (!data.isEmpty) {
                    print("object = \(object)")
                    let fileName = "\(object.name!)_\(dateFormatter.string(from: object.created!)).json"
                    
                    if let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                        let pathWithFileName = documentDirectory.appendingPathComponent(fileName)
                        do {
                            try data.write(to: pathWithFileName)
                            print("Saved to \(pathWithFileName)")
                        } catch {
                            print("Cannot save to a file: \(fileName)") // handle error
                        }
                    }
                }
                */
            }
            
            
            var data: Data
            do {
                data = try encoder.encode(compounds)
                print(String(data: data, encoding: .utf8) ?? "data")
            } catch {
                print("Cannot convert compounds to dto: \(compounds)")
                data = Data()
            }
            
            if (!data.isEmpty) {
                let fileName = "records.json"
                
                if let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                    let pathWithFileName = documentDirectory.appendingPathComponent(fileName)
                    do {
                        try data.write(to: pathWithFileName)
                        print("Saved to \(pathWithFileName)")
                    } catch {
                        print("Cannot save to a file: \(fileName)") // handle error
                    }
                }
            }
            
        }
    }
    
    private func dumpTags() {
        /*
        let fetchRequest: NSFetchRequest<CompoundTag> = CompoundTag.fetchRequest()
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: "compoundTags")
        
        do {
            try fetchedResultsController.performFetch()
        } catch {
            fatalError("Compounds cannot be fetched: \(error.localizedDescription)")
        }
        
        let encoder = JSONEncoder()
        
        var count = 0
        if let fetchedObejcts = fetchedResultsController.fetchedObjects {
            let dateFormatter = DateFormatter()
            dateFormatter.locale = Locale(identifier: "en_US_POSIX")
            dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
            dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
            
            var compounds = [CompoundDTO]()
            
            for object in fetchedObejcts {
                let compoundDTO = RecordDumper.convert(from: object)
                if let dto = compoundDTO {
                    compounds.append(dto)
                }
                
                var data: Data
                do {
                    data = try encoder.encode(compoundDTO)
                } catch {
                    print("Cannot convert a record to dto: \(object)")
                    data = Data()
                }
                count += 1
                
                if (!data.isEmpty) {
                    print("object = \(object)")
                    let fileName = "\(object.name!)_\(dateFormatter.string(from: object.created!)).json"
                    
                    if let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                        let pathWithFileName = documentDirectory.appendingPathComponent(fileName)
                        do {
                            try data.write(to: pathWithFileName)
                            print("Saved to \(pathWithFileName)")
                        } catch {
                            print("Cannot save to a file: \(fileName)") // handle error
                        }
                    }
                }
            }
            
            var data: Data
            do {
                data = try encoder.encode(compounds)
                print(String(data: data, encoding: .utf8) ?? "data")
            } catch {
                print("Cannot convert compounds to dto: \(compounds)")
            }
            
        }
 */
    }
    
    private func dumpConformers() {
        
    }
    
    private func dumpImages() {
        
    }
}
