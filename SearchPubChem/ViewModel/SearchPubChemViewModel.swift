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
import CoreSpotlight

class SearchPubChemViewModel: NSObject, ObservableObject {
    private var session: URLSession = URLSession.shared
    private let logger = Logger()
    
    private let contentsJson = "contents.json"
    private let networkErrorString: String = "The Internet connection appears to be offline"
    
    private let compoundProperties: [String] = [PubChemSearch.PropertyKey.formula, PubChemSearch.PropertyKey.weight, PubChemSearch.PropertyKey.nameIUPAC, PubChemSearch.PropertyKey.title]
    
    private let downloader = PubChemDownloader()
    
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
    private var persistenceContainer: NSPersistentCloudKitContainer {
        persistence.container
    }
    private var viewContext: NSManagedObjectContext {
        persistenceContainer.viewContext
    }
    
    private var subscriptions: Set<AnyCancellable> = []
    
    private(set) var spotlightIndexer: SearchPubChemSpotlightDelegate?
    private var spotlightIndexing = false
    
    init(persistence: Persistence) {
        self.persistence = persistence
        super.init()
        
        NotificationCenter.default
          .publisher(for: .NSPersistentStoreRemoteChange)
          .sink { self.fetchUpdates($0) }
          .store(in: &subscriptions)
        
        if let persistentStoreDescription = self.persistenceContainer.persistentStoreDescriptions.first {
            self.spotlightIndexer = SearchPubChemSpotlightDelegate(forStoreWith: persistentStoreDescription, coordinator: self.persistenceContainer.persistentStoreCoordinator)
            self.spotlightIndexing = UserDefaults.standard.bool(forKey: "spotlight_indexing")
            self.toggleSpotlightIndexing(enabled: self.spotlightIndexing)
            NotificationCenter.default.addObserver(self, selector: #selector(defaultsChanged), name: UserDefaults.didChangeNotification, object: nil)
        }
        
        logger.log("spotlightIndexer=\(String(describing: self.spotlightIndexer)) isIndexingEnabled=\(String(describing: self.spotlightIndexer?.isIndexingEnabled))")
        
        fetchCompounds()
    }
    
    @objc private func defaultsChanged() -> Void {
        if spotlightIndexing != UserDefaults.standard.bool(forKey: "spotlight_indexing") {
            spotlightIndexing = UserDefaults.standard.bool(forKey: "spotlight_indexing")
            toggleSpotlightIndexing(enabled: spotlightIndexing)
        }
    }
    
    func preloadData() -> Void {
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
        
        do {
            try viewContext.save()
        } catch {
            NSLog("Error while saving by AppDelegate")
        }
    }
    
    func resetCompound() -> Void {
        success = false
        errorMessage = nil
        propertySet = nil
        imageData = nil
        conformer = nil
    }
    
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

    func saveCompound(searchType: SearchType, searchValue: String, viewContext: NSManagedObjectContext) {
        guard let propertySet = propertySet else {
            return
        }
        
        let compound = Compound(context: viewContext)
        compound.name = searchType == .cid ? propertySet.Title : searchValue
        compound.firstCharacterInName = String(compound.name!.first!).uppercased()
        compound.formula = propertySet.MolecularFormula
        compound.molecularWeight = Double(propertySet.MolecularWeight)!
        compound.cid = "\(propertySet.CID)"
        compound.nameIUPAC = propertySet.IUPACName
        compound.image = imageData
        compound.conformerDownloaded = true
        
        let conformerEntity = ConformerEntity(context: viewContext)
        if let conformer = self.conformer {
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
        
        save(viewContext: viewContext) { _ in
            self.logger.log("Error while saving compound=\(compound, privacy: .public)")
        }
        
        resetCompound()
    }
    
    func saveSolution(solutionLabel: String, ingradients: [SolutionIngradientDTO], viewContext: NSManagedObjectContext) -> Void {
        let solution = Solution(context: viewContext)
        solution.name = solutionLabel.isEmpty ? self.solutionLabel : solutionLabel
        
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
        
        save(viewContext: viewContext) { _ in
            self.logger.log("Error while saving solution=\(solution, privacy: .public)")
        }
    }
    
    func save(viewContext: NSManagedObjectContext, completionHandler: @escaping (Error) -> Void) -> Void {
        persistence.save { result in
            switch result {
            case .success(_):
                DispatchQueue.main.async {
                    self.toggle.toggle()
                }
            case .failure(let error):
                self.logger.log("Error while saving data: \(error.localizedDescription, privacy: .public)")
                self.logger.log("Error while saving data: \(Thread.callStackSymbols, privacy: .public)")
                DispatchQueue.main.async {
                    self.errorMessage = "Error while saving data"
                    self.showAlert.toggle()
                    completionHandler(error)
                }
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
                }
            case .failure(let error):
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
    
    func panGesture(translation: CGSize, isEnded: Bool) {
        let newRotation = coordinateTransform(for: makeRotation(from: translation), with: self.oldRotation)

        self.rotation = SCNMatrix4Mult(newRotation, self.oldRotation)
        
        if isEnded {
            self.oldRotation = SCNMatrix4Mult(newRotation, self.oldRotation)
        }
    }
    
    func pinchGesture(scale: CGFloat, isEnded: Bool) {
        let scale = Float(scale)
        let newScale = SCNMatrix4MakeScale(scale, scale, scale)

        self.rotation = SCNMatrix4Mult(newScale, self.oldRotation)
        
        if isEnded {
            self.oldRotation = SCNMatrix4Mult(newScale, self.oldRotation)
        }
    }
    
    func resetRotation() {
        self.rotation = SCNMatrix4Identity
        self.oldRotation = SCNMatrix4Identity
    }
    
    private func makeRotation(from translation: CGSize) -> SCNMatrix4 {
        let length = sqrt( translation.width * translation.width + translation.height * translation.height )
        let angle = Float(length) * .pi / 180.0
        let rotationAxis = [CGFloat](arrayLiteral: translation.height / length, translation.width / length)
        let rotation = SCNMatrix4MakeRotation(angle, Float(rotationAxis[0]), Float(rotationAxis[1]), 0)
        return rotation
    }
    
    private func coordinateTransform(for rotation: SCNMatrix4, with reference: SCNMatrix4) -> SCNMatrix4 {
        let inverseOfReference = SCNMatrix4Invert(reference)
        let transformed = SCNMatrix4Mult(reference, SCNMatrix4Mult(rotation, inverseOfReference))
        return transformed
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
    
    // MARK: - Widget
    func writeWidgetEntries() {
        let fetchRequest: NSFetchRequest<Compound> = Compound.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "created", ascending: false)]
        
        let fc = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: viewContext, sectionNameKeyPath: nil, cacheName: nil)
        
        do {
            try fc.performFetch()
        } catch {
            logger.log("Failed fetch Compound")
        }
        
        guard let entities = fc.fetchedObjects else {
            return
        }
        
        guard entities.count > 0 else {
            return
        }
        
        var widgetEntries = [WidgetEntry]()
    
        let numberOfWidgetEntries = 6
        
        // Randomly select 6 records to provide widgets per hour
        for _ in 0..<numberOfWidgetEntries {
            let entity = entities[Int.random(in: 0..<entities.count)]
            if let cid = entity.cid, let name = entity.name, let formula = entity.formula, let created = entity.created {
                widgetEntries.append(WidgetEntry(cid: cid, name: name, formula: formula, image: entity.image, created: created))
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
    
    private func fetchCompounds() {
        let fetchRequet = NSFetchRequest<Compound>(entityName: "Compound")
        fetchRequet.sortDescriptors = [NSSortDescriptor(keyPath: \Compound.name, ascending: true)]
        allCompounds = fetch(fetchRequet)
    }
    
    private func fetch<Element>(_ fetchRequest: NSFetchRequest<Element>) -> [Element] {
        var fetchedEntities = [Element]()
        do {
            fetchedEntities = try persistenceContainer.viewContext.fetch(fetchRequest)
        } catch {
            self.logger.error("Failed to fetch: \(error.localizedDescription)")
        }
        return fetchedEntities
    }
    
    func searchCompounds(nameContaining searchString: String) -> [Compound] {
        logger.log("filteredCompounds: spotlightIndexing=\(self.spotlightIndexing)")
        if spotlightIndexing {
            searchCompound(searchString)
            return allCompounds
        } else {
            return allCompounds.filter { compound in
                searchString.isEmpty || compound.nameContains(string: searchString)
            }
        }
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
    
    func continueActivity(_ activity: NSUserActivity, completionHandler: (String) -> Void) {
        guard let info = activity.userInfo else {
            return
        }
        
        guard let objectIdentifier = info[CSSearchableItemActivityIdentifier] as? String else {
            return
        }
        
        guard let objectURI = URL(string: objectIdentifier) else {
            return
        }
        
        if let compound = selectCompound(for: objectURI), let cid = compound.cid {
            completionHandler(cid)
        }
    }
    
    func selectCompound(for url: URL) -> Compound? {
        guard let objectID = viewContext.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: url) else {
            return nil
        }
        return viewContext.object(with: objectID) as? Compound
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
            
            return CSSearchableItem(uniqueIdentifier: nil, domainIdentifier: spotlightIndexer.domainIdentifier(), attributeSet: attributeSet)
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
        
        searchQuery = CSSearchQuery(queryString: queryString, attributes: ["title"])
        
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
        allCompounds = foundCompounds
    }
}
