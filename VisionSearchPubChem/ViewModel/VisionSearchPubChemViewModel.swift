//
//  VisionSearchPubChemViewModel.swift
//  VisionSearchPubChem
//
//  Created by Jae Seung Lee on 2/25/24.
//  Copyright © 2024 Jae Seung Lee. All rights reserved.
//

import Foundation
import Combine
import CoreData
import SceneKit
import os
import Persistence
import CoreSpotlight

class VisionSearchPubChemViewModel: NSObject, ObservableObject {
    private var session: URLSession = URLSession.shared
    private let logger = Logger()
    
    private let contentsJson = "contents.json"
    private let networkErrorString: String = "The Internet connection appears to be offline"
    
    private let compoundProperties: [String] = [PubChemSearch.PropertyKey.formula, PubChemSearch.PropertyKey.weight, PubChemSearch.PropertyKey.nameIUPAC, PubChemSearch.PropertyKey.title]
    
    private let downloader = PubChemDownloader()
    //private let conformerSceneHelper = ConformerSceneHelper()
    
    @Published var success: Bool = false
    @Published var propertySet: Properties?
    @Published var imageData: Data?
    @Published var conformer: Conformer?
    
    @Published var toggle: Bool = false
    @Published var showAlert: Bool = false
    @Published var errorMessage: String?
    
    @Published var selectedTag: CompoundTag?
    @Published var receivedURL = false
    @Published var selectedCid: String = ""
    @Published var selectedCompoundName: String = ""
    var spotlightFoundCompounds: [CSSearchableItem] = []
    var searchQuery: CSSearchQuery?
    
    @Published var isConformerViewOpen = false
    
    // MARK: - for makings a solution
    @Published var compounds: [Compound]?
    
    private let persistence: Persistence
    private var persistenceContainer: NSPersistentCloudKitContainer {
        persistence.container
    }
    private var viewContext: NSManagedObjectContext {
        persistenceContainer.viewContext
    }
    private let persistenceHelper: VisionPersistenceHelper
    
    private var subscriptions: Set<AnyCancellable> = []
    
    //private(set) var spotlightIndexer: SearchPubChemSpotlightDelegate?
    private var spotlightIndexing = false
    
    init(persistence: Persistence) {
        self.persistence = persistence
        self.persistenceHelper = VisionPersistenceHelper(persistence: persistence)
        super.init()
        
        NotificationCenter.default
          .publisher(for: .NSPersistentStoreRemoteChange)
          .sink { self.fetchUpdates($0) }
          .store(in: &subscriptions)
        
        self.persistence.container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        fetchEntities()
    }
    
    private func fetchEntities() {
        fetchCompounds()
        fetchTags()
    }
    
    func preloadData() -> Void {
        persistenceHelper.preloadData { result in
            switch result {
            case .success(_):
                self.logger.log("Preload succeeded")
            case .failure(let error):
                self.logger.log("Failed to preload: error=\(error.localizedDescription)")
            }
        }
    }
    
    func resetCompound() -> Void {
        success = false
        errorMessage = nil
        propertySet = nil
        imageData = nil
        conformer = nil
    }
    
    // MARK: - PubChem API calls
    func download3DData(for cid: String) {
        downloader.downloadConformer(for: cid) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let conformerDTO):
                    self.conformer = self.populateConformer(from: conformerDTO.pcCompounds[0])
                    self.errorMessage = nil
                    self.success = true
                case .failure(let error):
                    self.logger.log("Error while downloading 3d data: \(error.localizedDescription)")
                    self.conformer = nil
                    self.errorMessage = error.localizedDescription
                    self.success = false
                }
            }
        }
    }
    
    private func populateConformer(from pcCompound: PCCompound) -> Conformer {
        let conformer = Conformer()
        conformer.cid = "\(pcCompound.id.cid)"
        conformer.conformerId = getConformerId(from: pcCompound)
        
        for id in pcCompound.atoms.aid {
            let atom = Atom()
            atom.number = pcCompound.atoms.element[id-1]
            atom.location = getAtomLocation(index: id-1, from: pcCompound.coords[0].conformers[0])
            conformer.atoms.append(atom)
        }
        
        return conformer
    }
    
    private func getConformerId(from pcCompound: PCCompound) -> String {
        var value: String?
        for coordData in pcCompound.coords[0].conformers[0].data {
            if (coordData.urn.label == "Conformer") {
                guard let sval = coordData.value.sval else {
                    logger.log("Cannot parse coordData.value.sval = \(String(describing: coordData.value.sval))")
                    continue
                }
                value = sval
            }
        }
        return value ?? ""
    }
    
    private func getAtomLocation(index: Int, from conformerData: ConformerData) -> [Double] {
        let x = conformerData.x[index]
        let y = conformerData.y[index]
        let z = conformerData.z[index]
        
        return [Double](arrayLiteral: x, y, z)
    }
    
    func downloadImage(for cid: String) {
        downloader.downloadImage(for: cid) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let data):
                    self.imageData = data
                    self.errorMessage = nil
                    self.success = true
                case .failure(let error):
                    self.logger.log("Error while downloading an image: \(error.localizedDescription)")
                    self.imageData = nil
                    self.errorMessage = error.localizedDescription
                    self.success = false
                }
            }
        }
    }
    
    func searchCompound(type: SearchType, value: String) -> Void {
        downloader.downloadProperties(identifier: value, identifierType: type) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let properties):
                    self.propertySet = properties
                    self.errorMessage = nil
                    self.success = true
                    self.downloadImage(for: "\(properties.CID)")
                    self.download3DData(for: "\(properties.CID)")
                case .failure(let error):
                    self.logger.log("Error while getting properties: \(error.localizedDescription))")
                    self.propertySet = nil
                    self.errorMessage = error.localizedDescription
                    self.success = false
                    self.showAlert = true
                }
            }
        }
    }
    
    // MARK: - Persistence
    func saveCompound(searchType: SearchType, searchValue: String) {
        guard let properties = propertySet else {
            return
        }
        
        let name = searchType == .cid ? properties.Title : searchValue
        
        persistenceHelper.saveCompound(name, properties: properties, imageData: imageData, conformer: conformer) { result in
            switch result {
            case .success(_):
                self.logger.log("Saved a compound called name=\(name, privacy: .public)")
            case .failure(let error):
                self.logger.log("Failed to save a compound called name=\(name, privacy: .public): \(error.localizedDescription)")
            }
            self.resetCompound()
            self.persistenceResultHandler(result)
        }
    }
    
    func delete(compound: Compound) {
        compound.tags?.forEach { tag in
            if let compoundTag = tag as? CompoundTag {
                compoundTag.removeFromCompounds(compound)
                compoundTag.compoundCount -= 1
            }
        }
        
        compound.conformers?.forEach { conformer in
            if let entity = conformer as? ConformerEntity {
                entity.atoms?.forEach { atom in
                    if let atomEntity = atom as? AtomEntity {
                        entity.removeFromAtoms(atomEntity)
                        delete(atomEntity)
                    }
                }
                
                compound.removeFromConformers(entity)
                delete(entity)
            }
        }
        
        delete(compound)
        
        save()
    }
    
    func saveTag(name: String, compound: Compound, completionHandler: @escaping (CompoundTag) -> Void) -> Void {
        persistenceHelper.saveNewTag(name, for: compound) { result in
            switch result {
            case .success(let tag):
                self.logger.log("Saved a tag named=\(name, privacy: .public)")
                completionHandler(tag)
            case .failure(let error):
                self.logger.log("Failed to save a tag named=\(name, privacy: .public): \(error.localizedDescription)")
                self.errorMessage = "Failed to save a tag named \(name)"
                self.showAlert.toggle()
            }
        }
    }
    
    func saveTag(name: String, compound: Compound) -> CompoundTag {
        let newTag = CompoundTag(context: viewContext)
        newTag.compoundCount = 1
        newTag.name = name
        newTag.addToCompounds(compound)
        
        save()
        
        return newTag
    }
    
    func deleteTags(_ indexSet: IndexSet) -> Void {
        indexSet.map { allTags[$0] }
            .forEach { delete($0) }
        
        save()
    }
    
    func delete(tag: CompoundTag) -> Void {
        if let compounds = tag.compounds {
            tag.removeFromCompounds(compounds)
        }
        
        delete(tag)
        save()
    }
    
    func update(compound: Compound, newTags: [CompoundTag]) -> Void {
        if let oldTags = compound.tags {
            for tag in oldTags {
                if let compoundTag = tag as? CompoundTag {
                    compoundTag.compoundCount -= 1
                    compoundTag.removeFromCompounds(compound)
                }
            }
        }
        
        for tag in newTags {
            tag.compoundCount += 1
            tag.addToCompounds(compound)
        }
        
        save()
    }
    
    private func persistenceResultHandler(_ result: Result<Void, Error>) -> Void {
        DispatchQueue.main.async {
            switch result {
            case .success(_):
                self.toggle.toggle()
            case .failure(let error):
                self.logger.log("Error while saving data: \(error.localizedDescription, privacy: .public)")
                self.logger.log("Error while saving data: \(Thread.callStackSymbols, privacy: .public)")
                self.errorMessage = "Error while saving data"
                self.showAlert.toggle()
            }
            self.fetchEntities()
        }
    }
    
    func save() -> Void {
        persistenceHelper.save { result in
            self.persistenceResultHandler(result)
        }
    }
    
    func delete(_ object: NSManagedObject) -> Void {
        // This doesn't save to DB
        persistenceHelper.delete(object)
    }
    
    func retrieveCompound(id: String) -> Compound? {
        let splitId = id.split(separator: "_")
        logger.log("id=\(id): cid=\(splitId[0]), created=\(splitId[1])")
        
        let fetchRequest: NSFetchRequest<Compound> = Compound.fetchRequest()
        
        fetchRequest.predicate = NSPredicate(format: "cid == %@", "\(splitId[0])")
        
        let compounds = persistenceHelper.perform(fetchRequest)
        
        return compounds.first { compound in
            if let created = compound.created {
                return created.formatted() == "\(splitId[1])"
            } else {
                return false
            }
        }
    }
    
    // MARK: - Persistence History Request
    private lazy var historyRequestQueue = DispatchQueue(label: "history")
    private func fetchUpdates(_ notification: Notification) -> Void {
        persistence.fetchUpdates(notification) { result in
            switch result {
            case .success(()):
                DispatchQueue.main.async {
                    self.toggle.toggle()
                    if self.selectedCompoundName.isEmpty {
                        self.fetchEntities()
                    }
                }
            case .failure(let error):
                self.logger.log("Error while updating history: \(error.localizedDescription, privacy: .public) \(Thread.callStackSymbols, privacy: .public)")
            }
        }
    }
    
    func selectedCompounds(_ compounds: [Compound], with title: String) {
        self.compounds = compounds
    }
    
    // MARK: -
    @Published var allCompounds = [Compound]()
    @Published var allTags = [CompoundTag]()
    
    private func fetchCompounds() {
        let fetchRequet = NSFetchRequest<Compound>(entityName: "Compound")
        fetchRequet.sortDescriptors = [NSSortDescriptor(keyPath: \Compound.name, ascending: true),
                                       NSSortDescriptor(keyPath: \Compound.created, ascending: true)]
        allCompounds = persistenceHelper.perform(fetchRequet)
    }
    
    private func fetchTags() {
        let fetchRequet = NSFetchRequest<CompoundTag>(entityName: "CompoundTag")
        fetchRequet.sortDescriptors = [NSSortDescriptor(keyPath: \Compound.name, ascending: true),
                                       NSSortDescriptor(keyPath: \Compound.created, ascending: true)]
        allTags = persistenceHelper.perform(fetchRequet)
    }
    
}
