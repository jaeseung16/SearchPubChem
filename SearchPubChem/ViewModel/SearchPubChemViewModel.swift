//
//  SearchPubChemViewModel.swift
//  SearchPubChem
//
//  Created by Jae Seung Lee on 10/6/21.
//  Copyright © 2021 Jae Seung Lee. All rights reserved.
//

import Foundation
import Combine
import CoreData
import SceneKit
import os
import Persistence
@preconcurrency import CoreSpotlight

@MainActor
class SearchPubChemViewModel: NSObject, ObservableObject {
    private var session: URLSession = URLSession.shared
    private let logger = Logger()
    
    private let contentsJson = "contents.json"
    private let networkErrorString: String = "The Internet connection appears to be offline"
    
    private let compoundProperties: [String] = [PubChemSearch.PropertyKey.formula, PubChemSearch.PropertyKey.weight, PubChemSearch.PropertyKey.nameIUPAC, PubChemSearch.PropertyKey.title]
    
    private let downloader = PubChemDownloader()
    private let conformerSceneHelper = ConformerSceneHelper()
    
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
    
    // MARK: - for makings a solution
    @Published var compounds: [Compound]?
    @Published var solutionLabel: String = ""
    
    private let persistence: Persistence
    
    private let persistenceHelper: PersistenceHelper
    
    private var subscriptions: Set<AnyCancellable> = []
    
    private(set) var spotlightIndexer: SearchPubChemSpotlightDelegate?
    private var spotlightIndexing = false
    
    init(persistence: Persistence) {
        self.persistence = persistence
        self.persistenceHelper = PersistenceHelper(persistence: persistence)
        super.init()
        
        NotificationCenter.default
          .publisher(for: .NSPersistentStoreRemoteChange)
          .receive(on: DispatchQueue.main)
          .sink { self.fetchUpdates($0) }
          .store(in: &subscriptions)
        
        if let spotlightIndexer = persistence.createCoreSpotlightDelegate() as? SearchPubChemSpotlightDelegate {
            self.spotlightIndexer = spotlightIndexer
            self.spotlightIndexing = UserDefaults.standard.bool(forKey: "spotlight_indexing")
            self.toggleSpotlightIndexing(enabled: self.spotlightIndexing)
            NotificationCenter.default.addObserver(self, selector: #selector(defaultsChanged), name: UserDefaults.didChangeNotification, object: nil)
        }
        
        logger.log("spotlightIndexer=\(String(describing: self.spotlightIndexer)) isIndexingEnabled=\(String(describing: self.spotlightIndexer?.isIndexingEnabled))")
        
        self.persistence.container.viewContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        
        fetchEntities()
    }
    
    private func fetchEntities() {
        fetchCompounds()
        fetchTags()
        fetchSolutions()
    }
    
    @objc private func defaultsChanged() -> Void {
        if spotlightIndexing != UserDefaults.standard.bool(forKey: "spotlight_indexing") {
            spotlightIndexing = UserDefaults.standard.bool(forKey: "spotlight_indexing")
            toggleSpotlightIndexing(enabled: spotlightIndexing)
        }
    }
    
    func preloadData() -> Void {
        Task {
            do {
                try await persistenceHelper.preloadData()
                self.logger.log("Preload succeeded")
            } catch {
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
        let conformer = conformer
        
        Task {
            do {
                try await persistenceHelper.save(compound: name, properties: properties, image: imageData, conformer: conformer)
                self.logger.log("Saved a compound called name=\(name, privacy: .public)")
                self.resetCompound()
                self.persistenceResultHandler(error: nil)
            } catch {
                self.logger.log("Failed to save a compound called name=\(name, privacy: .public): \(error.localizedDescription)")
                self.resetCompound()
                self.persistenceResultHandler(error: error)
            }
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
   
    func save(tag name: String, compound: Compound) async -> CompoundTag? {
        let compoundID = compound.objectID
        do {
            let tag = try await persistenceHelper.saveNewTag(name, for: compoundID)
            self.logger.log("Saved a tag named=\(name, privacy: .public)")
            return tag
        } catch let error {
            self.logger.log("Failed to save a tag named=\(name, privacy: .public): \(error.localizedDescription)")
            self.errorMessage = "Failed to save a tag named \(name)"
            self.showAlert.toggle()
            return nil
        }
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
        Task {
            do {
                try await persistenceHelper.saveSolution(label, ingradients: ingradients)
                self.logger.log("Saved a solution: label=\(label, privacy: .public)")
                self.persistenceResultHandler(error: nil)
            } catch {
                self.logger.log("Failed to save a solution: label=\(label, privacy: .public), error=\(error.localizedDescription)")
                self.persistenceResultHandler(error: error)
            }
            
        }
    }
    
    private func persistenceResultHandler(error: Error?) -> Void {
        if let error = error {
            self.logger.log("Error while saving data: \(error.localizedDescription, privacy: .public)")
            self.logger.log("Error while saving data: \(Thread.callStackSymbols, privacy: .public)")
            self.errorMessage = "Error while saving data"
            self.showAlert.toggle()
        } else {
            self.toggle.toggle()
        }
        self.fetchEntities()
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
        Task {
            do {
                try await persistence.save()
                self.persistenceResultHandler(error: nil)
            } catch {
                self.persistenceResultHandler(error: error)
            }
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
    
    // MARK: - SceneKit
    @Published var rotation: SCNMatrix4 = SCNMatrix4Identity
    private var oldRotation: SCNMatrix4 = SCNMatrix4Identity
    
    @available(*, deprecated)
    func panGesture(translation: CGSize, isEnded: Bool) {
        let newRotation = conformerSceneHelper.coordinateTransform(from: translation, with: self.oldRotation)

        self.rotation = SCNMatrix4Mult(newRotation, self.oldRotation)
        
        if isEnded {
            self.oldRotation = SCNMatrix4Mult(newRotation, self.oldRotation)
        }
    }
    
    func panGesture(translation: CGSize, reference: SCNMatrix4, isEnded: Bool, completionHandler: @escaping (SCNMatrix4, SCNMatrix4) -> Void) {
        let transform = conformerSceneHelper.coordinateTransform(from: translation, with: reference)
        completionHandler(SCNMatrix4Mult(transform, reference), isEnded ? SCNMatrix4Mult(transform, reference) : reference)
    }
    
    @available(*, deprecated)
    func pinchGesture(scale: CGFloat, isEnded: Bool) {
        let scale = Float(scale)
        let newScale = SCNMatrix4MakeScale(scale, scale, scale)

        self.rotation = SCNMatrix4Mult(newScale, self.oldRotation)
        
        if isEnded {
            self.oldRotation = SCNMatrix4Mult(newScale, self.oldRotation)
        }
    }
    
    func pinchGesture(scale: CGFloat, reference: SCNMatrix4, isEnded: Bool, completionHandler: @escaping (SCNMatrix4, SCNMatrix4) -> Void) {
        let transform = conformerSceneHelper.coordinateTransform(from: Float(scale))
        completionHandler(SCNMatrix4Mult(transform, reference), isEnded ? SCNMatrix4Mult(transform, reference) : reference)
    }
    
    func resetRotation() {
        self.rotation = SCNMatrix4Identity
        self.oldRotation = SCNMatrix4Identity
    }
    
    func makeScene(_ conformer: Conformer) -> SCNScene {
        return conformerSceneHelper.makeScene(conformer)
    }
    
    // MARK: - Solution
    func generateCSV(solutionName: String, created: Date, ingradients: [SolutionIngradientDTO]) -> URL? {
        let csvString = buildCSV(ingradients: ingradients)

        guard let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
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
    
    func solutionIngradientData(_ solution: Solution) -> [SolutionIngradientData] {
        var result = [SolutionIngradientData]()
        
        let ingradients: [SolutionIngradientDTO]? = solution.ingradients?.compactMap { ingradient in
            if let ingradient = ingradient as? SolutionIngradient {
                if let compound = ingradient.compound, let unitRawValue = ingradient.unit, let unit = Unit(rawValue: unitRawValue) {
                    return SolutionIngradientDTO(compound: compound, amount: ingradient.amount, unit: unit)
                }
            }
            return nil
        }
        
        guard let ingradients = ingradients else {
            return result
        }
        
        var absoluteAmounts: [String: [Unit: Double]] = [:]
        var relativeAmounts: [String: [Unit: Double]] = [:]
        
        for unit in Unit.allCases {
            let amounts = getAmounts(of: ingradients, in: unit)
            let total = total(amounts)
            
            for amount in amounts {
                absoluteAmounts[amount.key, default: [:]][unit] = amount.value
                relativeAmounts[amount.key, default: [:]][unit] = amount.value / total
            }
        }
        
        for ingradient in ingradients {
            guard let name = ingradient.compound.name else {
                continue
            }
            
            guard let absoluteAmountByUnit = absoluteAmounts[name] else {
                continue
            }
            
            guard let relativeAmountByUnit = relativeAmounts[name] else {
                continue
            }
            
            let solutionIngradientData = SolutionIngradientData(compound: ingradient.compound,
                                                                absoluteAmountByUnit: absoluteAmountByUnit,
                                                                relativeAmountByUnit: relativeAmountByUnit)
            
            result.append(solutionIngradientData)
        }
        
        return result
    }
    
    private func total(_ amounts: [String: Double]) -> Double {
        return amounts.values.reduce(0.0, { x, y in x + y })
    }
    
    // MARK: - Widget
    func writeWidgetEntries() {
        let fetchRequest: NSFetchRequest<Compound> = Compound.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "created", ascending: false)]
        
        let compounds = persistenceHelper.perform(fetchRequest)
        
        guard compounds.count > 0 else {
            return
        }
        
        var widgetEntries = [WidgetEntry]()
    
        let numberOfWidgetEntries = 6
        
        // Randomly select 6 records to provide widgets per hour
        for _ in 0..<numberOfWidgetEntries {
            let compound = compounds[Int.random(in: 0..<compounds.count)]
            if let cid = compound.cid, let name = compound.name, let formula = compound.formula, let created = compound.created {
                widgetEntries.append(WidgetEntry(cid: cid, name: name, formula: formula, image: compound.image, created: created))
            }
        }
        
        let archiveURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: SearchPubChemConstants.groupIdentifier.rawValue)!
        logger.log("archiveURL=\(archiveURL)")
        
        let encoder = JSONEncoder()
        
        if let dataToSave = try? encoder.encode(widgetEntries) {
            do {
                try dataToSave.write(to: archiveURL.appendingPathComponent(contentsJson))
                logger.log("Saved \(widgetEntries.count) widgetEntries")
            } catch {
                logger.log("Error: Can't write contents")
                return
            }
        }
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
    
    func searchCompounds(nameContaining searchString: String) -> [Compound] {
        logger.log("filteredCompounds: spotlightIndexing=\(self.spotlightIndexing)")
        if spotlightIndexing {
            searchCompound(searchString)
            return allCompounds
        } else {
            fetchCompounds()
            return allCompounds.filter { compound in
                searchString.isEmpty || compound.nameContains(string: searchString)
            }
        }
    }
    
    private func fetchSolutions() {
        let fetchRequest = NSFetchRequest<Solution>(entityName: "Solution")
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Compound.created, ascending: false)]
        allSolutions = persistenceHelper.perform(fetchRequest)
    }
    
}

extension SearchPubChemViewModel {
    func toggleSpotlightIndexing(enabled: Bool) {
        logger.log("enabled=\(enabled) spotlightIndexer=\(self.spotlightIndexer)")
        guard let spotlightIndexer = spotlightIndexer else { return }

        if enabled {
            indexCompounds()
            spotlightIndexer.startSpotlightIndexing()
        } else {
            spotlightIndexer.stopSpotlightIndexing()
            spotlightIndexer.deleteSpotlightIndex { error in
                guard let error = error else {
                    self.logger.log("Successfully deleted spotlight index")
                    return
                }
                
                self.logger.log("Failed to delete spotlight index: \(error.localizedDescription, privacy: .public)")
            }
        }
    }
    
    func continueActivity(_ activity: NSUserActivity, completionHandler: (Compound) -> Void) {
        guard let info = activity.userInfo else {
            return
        }
        
        guard let objectIdentifier = info[CSSearchableItemActivityIdentifier] as? String else {
            return
        }
        
        guard let objectURI = URL(string: objectIdentifier) else {
            return
        }
        
        if let compound = selectCompound(for: objectURI) {
            completionHandler(compound)
        }
    }
    
    func selectCompound(for url: URL) -> Compound? {
        return persistenceHelper.selectCompound(for: url)
    }
    
    private func indexCompounds() -> Void {
        guard let spotlightIndexer = spotlightIndexer else {
            self.logger.log("No spotlightIndexer initialized")
            return
        }
        
        let searchableItems: [CSSearchableItem] = allCompounds.compactMap { compound in
            // Duplicate from SearchPubChemSpotlightDelegate
            guard let attributeSet = spotlightIndexer.attributeSet(for: compound) else {
                self.logger.log("Cannot generate attribute set for \(compound, privacy: .public)")
                return nil
            }
            
            return CSSearchableItem(uniqueIdentifier: compound.objectID.uriRepresentation().absoluteString, domainIdentifier: spotlightIndexer.domainIdentifier(), attributeSet: attributeSet)
        }
        
        CSSearchableIndex(name: spotlightIndexer.indexName()!).indexSearchableItems(searchableItems) { error in
            guard let error = error else {
                self.logger.log("Indexed compounds: \(searchableItems, privacy: .public)")
                return
            }
            self.logger.log("Error while indexing compounds: \(error.localizedDescription, privacy: .public)")
        }
    }
    
    func searchCompound(_ name: String) {
        if name.isEmpty {
            searchQuery?.cancel()
            fetchCompounds()
        } else {
            searchUsingCoreSpotlight(name)
        }
    }
    
    private func searchUsingCoreSpotlight(_ name: String) {
        let escapedName = name.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"")
        let queryString = "(title == \"*\(escapedName)*\"cd)"
        
        let context = CSSearchQueryContext()
        context.fetchAttributes = ["title"]
        searchQuery = CSSearchQuery(queryString: queryString, queryContext: context)
        
        searchQuery?.foundItemsHandler = { items in
            DispatchQueue.main.async {
                self.spotlightFoundCompounds += items
                self.spotlightFoundCompounds.sort { item1, item2 in
                    item1.attributeSet.title! < item2.attributeSet.title!
                }
            }
        }
        
        searchQuery?.completionHandler = { error in
            if let error = error {
                self.logger.log("Searching \(name) came back with error: \(error.localizedDescription, privacy: .public)")
            } else {
                DispatchQueue.main.async {
                    self.fetchSearchResults(self.spotlightFoundCompounds)
                    self.spotlightFoundCompounds.removeAll()
                }
            }
        }
        
        searchQuery?.start()
    }
    
    private func fetchSearchResults(_ items: [CSSearchableItem]) {
        let foundCompounds = items.compactMap { (item: CSSearchableItem) -> Compound? in
            guard let compoundURL = URL(string: item.uniqueIdentifier) else {
                return nil
            }
            return selectCompound(for: compoundURL)
        }
        logger.log("Found \(foundCompounds.count) compounds")
        allCompounds = foundCompounds.sorted(by: { compound1, compound2 in
            if compound1.name == nil {
                return false
            } else if compound2.name == nil {
                return true
            } else if compound1.name == compound2.name {
                return compound1.created! < compound2.created!
            } else {
                return compound1.name! < compound2.name!
            }
        })
    }
}

