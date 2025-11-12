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

@MainActor
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
    
    @Published var isMainWindowOpen = false
    @Published var isConformerViewOpen = false
    
    // MARK: - for makings a solution
    @Published var compounds: [Compound]?
    @Published var solutionLabel: String = ""
    
    private let persistence: Persistence
    private var viewContext: NSManagedObjectContext {
        persistence.container.viewContext
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
        fetchSolutions()
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
        Task {
            do {
                let conformerDTO = try await downloader.downloadConformer(for: cid)
                self.conformer = self.populateConformer(from: conformerDTO.pcCompounds[0])
                self.errorMessage = nil
                self.success = true
            } catch {
                self.logger.log("Error while downloading 3d data: \(error.localizedDescription)")
                self.conformer = nil
                self.errorMessage = error.localizedDescription
                self.success = false
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
        Task {
            do {
                let data = try await downloader.downloadImage(for: cid)
                self.imageData = data
                self.errorMessage = nil
                self.success = true
            } catch {
                self.logger.log("Error while downloading an image: \(error.localizedDescription)")
                self.imageData = nil
                self.errorMessage = error.localizedDescription
                self.success = false
            }
        }
    }
    
    func searchCompound(type: SearchType, value: String) -> Void {
        Task {
            do {
                let properties = try await downloader.downloadProperties(identifier: value, identifierType: type)
                self.propertySet = properties
                self.errorMessage = nil
                self.success = true
                self.downloadImage(for: "\(properties.CID)")
                self.download3DData(for: "\(properties.CID)")
            } catch {
                self.logger.log("Error while getting properties: \(error.localizedDescription))")
                self.propertySet = nil
                self.errorMessage = error.localizedDescription
                self.success = false
                self.showAlert = true
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
    
    func saveSolution(solutionLabel: String, ingradients: [SolutionIngradientDTO]) -> Void {
        let label = solutionLabel.isEmpty ? self.solutionLabel : solutionLabel
        
        persistenceHelper.saveSolution(label, ingradients: ingradients) { result in
            switch result {
            case .success(_):
                self.logger.log("Saved a solution: label=\(label, privacy: .public)")
            case .failure(let error):
                self.logger.log("Failed to save a solution: label=\(label, privacy: .public), error=\(error.localizedDescription)")
            }
            self.persistenceResultHandler(result)
        }
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
        Task {
            do {
                let _ = try await persistence.fetchUpdates()
                self.toggle.toggle()
                if self.selectedCompoundName.isEmpty {
                    self.fetchEntities()
                }
            } catch {
                self.logger.log("Error while updating history: \(error.localizedDescription, privacy: .public) \(Thread.callStackSymbols, privacy: .public)")
            }
        }
    }
    
    func selectedCompounds(_ compounds: [Compound], with title: String) {
        self.compounds = compounds
        self.solutionLabel = title
    }
    
    // MARK: -
    @Published var allCompounds = [Compound]()
    @Published var allTags = [CompoundTag]()
    @Published var allSolutions = [Solution]()
    
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
    
    private func fetchSolutions() {
        let fetchRequest = NSFetchRequest<Solution>(entityName: "Solution")
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Compound.created, ascending: false)]
        allSolutions = persistenceHelper.perform(fetchRequest)
    }
    
    // MARK: - Solution
    func generateCSV(solutionName: String, created: Date, ingradients: [SolutionIngradientDTO]) -> URL? {
        let csvString = buildCSV(ingradients: ingradients)

        guard let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            logger.log("Can't get a path for solutionName=\(solutionName), created=\(created)")
            return nil
        }
        
        let filename = solutionName.replacingOccurrences(of: "/", with: "_")
        let csvFileURL = path.appendingPathComponent("\(filename)_\(dateFormatter.string(from: created)).csv")
        
        do {
            try csvString.write(to: csvFileURL, atomically: true, encoding: .utf8)
        } catch {
            logger.log("Failed to save the csv file")
        }
        
        return csvFileURL
    }
    
    private var dateFormatter: ISO8601DateFormatter {
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withYear, .withMonth, .withDay]
        return dateFormatter
    }
    
    private func buildCSV(ingradients: [SolutionIngradientDTO]) -> String {
        var csvString = "CID, Compound, Molecular Weight (gram/mol), Amount (g), Amount (mol)\n"
        
        for ingradient in ingradients {
            let compound = ingradient.compound
            
            csvString += "\(compound.cid!), "
            csvString += "\(compound.name!), "
            csvString += "\(compound.molecularWeight), "
            
            let amountInGram = convert(ingradient.amount, molecularWeight: compound.molecularWeight, originalUnit: ingradient.unit, newUnit: .gram)
            let amountInMol = convert(ingradient.amount, molecularWeight: compound.molecularWeight, originalUnit: ingradient.unit, newUnit: .mol)
            
            csvString += "\(amountInGram), "
            csvString += "\(amountInMol)\n"
        }
        
        return csvString
    }
    
    func convert(_ amount: Double, molecularWeight: Double, originalUnit: Unit, newUnit: Unit) -> Double {
        var convertedAmount = amount
        switch originalUnit {
        case .gram:
            switch newUnit {
            case .gram:
                convertedAmount = amount
            case .mg:
                convertedAmount = 1000.0 * amount
            case .mol:
                convertedAmount = amount / molecularWeight
            case .mM:
                convertedAmount = 1000.0 * amount / molecularWeight
            }
        case .mg:
            switch newUnit {
            case .gram:
                convertedAmount = amount / 1000.0
            case .mg:
                convertedAmount = amount
            case .mol:
                convertedAmount = amount / 1000.0 / molecularWeight
            case .mM:
                convertedAmount = amount / molecularWeight
            }
        case .mol:
            switch newUnit {
            case .gram:
                convertedAmount = amount * molecularWeight
            case .mg:
                convertedAmount = 1000.0 * amount * molecularWeight
            case .mol:
                convertedAmount = amount
            case .mM:
                convertedAmount = 1000.0 * amount
            }
        case .mM:
            switch newUnit {
            case .gram:
                convertedAmount = amount / 1000.0 * molecularWeight
            case .mg:
                convertedAmount = amount * molecularWeight
            case .mol:
                convertedAmount = amount / 1000.0
            case .mM:
                convertedAmount = amount
            }
        }
        return convertedAmount
    }
    
    func getAmounts(of ingradients: [SolutionIngradientDTO], in unit: Unit) -> [String: Double] {
        var amounts = [String: Double]()
        for ingradient in ingradients {
            if let name = ingradient.compound.name {
                amounts[name] = convert(ingradient.amount,
                                        molecularWeight: ingradient.compound.molecularWeight,
                                        originalUnit: ingradient.unit,
                                        newUnit: unit)
            }
        }
        return amounts
    }
}
