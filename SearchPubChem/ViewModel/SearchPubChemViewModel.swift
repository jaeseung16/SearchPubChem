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

class SearchPubChemViewModel: NSObject, ObservableObject {
    private var session = URLSession.shared
    
    private let client = PubChemSearch()
    private let networkErrorString = "The Internet connection appears to be offline"
    
    private let compoundProperties = [PubChemSearch.PropertyKey.formula,
                      PubChemSearch.PropertyKey.weight,
                      PubChemSearch.PropertyKey.nameIUPAC,
                      PubChemSearch.PropertyKey.title]
    
    @Published var success = false
    @Published var errorMessage: String?
    @Published var propertySet: Properties?
    @Published var imageData: Data?
    @Published var conformer: Conformer?
    
    // MARK: - for makings a solution
    @Published var compounds: [Compound]?
    @Published var solutionLabel = ""
    
    private let dataController = DataController.shared
    
    private var subscriptions: Set<AnyCancellable> = []
    
    override init() {
        super.init()
        
        NotificationCenter.default
          .publisher(for: .NSPersistentStoreRemoteChange)
          .sink { self.fetchUpdates($0) }
          .store(in: &subscriptions)
    }
    
    func preloadData() -> Void {
        dataController.preloadData()
    }
    
    func resetCompound() -> Void {
        success = false
        errorMessage = nil
        propertySet = nil
        imageData = nil
        conformer = nil
    }
    
    func download3DData(for cid: String) {
        var component = commonURLComponents()
        component.path = PubChemSearch.Constant.pathForCID + cid + "/JSON"
        component.query = "\(PubChemSearch.QueryString.recordType)=\(PubChemSearch.RecordType.threeD)"
        
        _ = dataTask(with: component.url!, completionHandler: { (data, error) in
            func sendError(_ error: String) {
                DispatchQueue.main.async {
                    self.success = false
                    self.conformer = nil
                    self.errorMessage = error
                }
            }
            
            guard error == nil else {
                NSLog("Error while downloading 3d data: \(String(describing: error!.userInfo[NSLocalizedDescriptionKey]))")
                sendError(error!.userInfo[NSLocalizedDescriptionKey] as! String)
                return
            }
            
            guard let data = data else {
                NSLog("Missing 3d data")
                sendError("Missing 3d data")
                return
            }
            
            let dto: ConformerDTO? = self.decode(from: data)
            
            guard let conformerDTO = dto else {
                NSLog("Error while parsing data as conformerDTO = \(String(describing: dto))")
                sendError("Error while parsing 3D data")
                return
            }
            
            let conformer = self.populateConformer(from: conformerDTO.pcCompounds[0])
            
            DispatchQueue.main.async {
                self.success = true
                self.conformer = conformer
                self.errorMessage = nil
            }
        })
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
                    print("Cannot parse coordData.value.sval = \(String(describing: coordData.value.sval))")
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
        var component = commonURLComponents()
        component.path = PubChemSearch.Constant.pathForCID + cid + PubChemSearch.QueryResult.png
        
        _ = dataTask(with: component.url!, completionHandler: { (data, error) in
            func sendError(_ error: String) {
                DispatchQueue.main.async {
                    self.success = false
                    self.imageData = nil
                    self.errorMessage = error
                }
            }
            
            guard error == nil else {
                NSLog("Error while downloading an image: \(String(describing: error!.userInfo[NSLocalizedDescriptionKey]))")
                sendError(error!.userInfo[NSLocalizedDescriptionKey] as! String)
                return
            }
        
            guard let data = data else {
                NSLog("Missing image data")
                sendError("Missing image data")
                return
            }

            DispatchQueue.main.async {
                self.success = true
                self.imageData = data
                self.errorMessage = nil
            }
        })
    }
    
    func searchCompound(type: SearchType, value: String) -> Void {
        searchProperties(type: type, value: value) { (properties, error) in
            func sendError(_ error: String) {
                DispatchQueue.main.async {
                    self.success = false
                    self.propertySet = nil
                    self.errorMessage = error
                }
            }
            
            guard (error == nil) else {
                NSLog("Error while getting properties: \(String(describing: error!.userInfo[NSLocalizedDescriptionKey]))")
                sendError(error!.userInfo[NSLocalizedDescriptionKey] as! String)
                return
            }
            
            guard let properties = properties else {
                NSLog("Missing property values")
                sendError("Missing property values")
                return
            }
            
            DispatchQueue.main.async {
                self.success = true
                self.propertySet = properties
                self.errorMessage = nil
                self.downloadImage(for: "\(properties.CID)")
                self.download3DData(for: "\(properties.CID)")
            }
        }
    }
    
    private func searchProperties(type: SearchType, value: String, completionHandler: @escaping (_ properties: Properties?, _ error: NSError?) -> Void) {
        let url = searchURL(type: type, value: value)
        
        _ = dataTask(with: url) { (data, error) in
            func sendError(_ error: String) {
                let userInfo = [NSLocalizedDescriptionKey: error]
                completionHandler(nil, NSError(domain: "dataTask", code: 1, userInfo: userInfo))
            }
            
            guard (error == nil) else {
                completionHandler(nil, error)
                return
            }
            
            guard let data = data else {
                sendError("Cannot get the data!")
                return
            }
            
            print(String(data: data, encoding: .utf8) ?? "Not utf8")
            
            let dto : CompoundDTO? = self.decode(from: data)
            guard let compoundDTO = dto else {
                sendError("Error while parsing data as compoundDTO = \(String(describing: dto))")
                return
            }
            
            completionHandler(compoundDTO.propertyTable.properties[0], nil)
        }
    }
    
    private func searchURL(type: SearchType, value: String) -> URL {
        var pathForProperties = PubChemSearch.Constant.pathForProperties
        
        for property in compoundProperties {
            pathForProperties += property + ","
        }
        pathForProperties.remove(at: pathForProperties.index(before: pathForProperties.endIndex))
        pathForProperties += PubChemSearch.QueryResult.json
        
        var component = commonURLComponents()
        
        switch type {
        case .name:
            component.path = PubChemSearch.Constant.pathForName + value + pathForProperties
        case .cid:
            component.path = PubChemSearch.Constant.pathForCID + value + pathForProperties
        }
        
        return component.url!
    }
    
    private func commonURLComponents() -> URLComponents {
        var component = URLComponents()
        component.scheme = PubChemSearch.Constant.scheme
        component.host = PubChemSearch.Constant.host
        return component
    }
    
    private func decode<T: Codable>(from data: Data) -> T? {
        let decoder = JSONDecoder()
        var dto: T
        do {
            dto = try decoder.decode(T.self, from: data)
        } catch {
            print("Cannot parse data as type \(T.self)")
            return nil
        }
        return dto
    }
    
    private func dataTask(with url: URL, completionHandler: @escaping (_ data: Data?, _ error: NSError?) -> Void) -> URLSessionTask {
        let request = URLRequest(url: url, timeoutInterval: 15)
        
        let task = session.dataTask(with: request) { (data, response, error) in
            func sendError(_ error: String) {
                let userInfo = [NSLocalizedDescriptionKey: error]
                completionHandler(nil, NSError(domain: "dataTask", code: 1, userInfo: userInfo))
            }
            
            guard (error == nil) else {
                sendError("There was an error with your request: \(error!)")
                return
            }
            
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else {
                let statusCode = (response as? HTTPURLResponse)!.statusCode
                var errorString: String
                
                if let code = PubChemSearch.Status(rawValue: statusCode) {
                    switch(code) {
                    case .badRequest:
                        errorString = "Request is improperly formed"
                    case .notFound:
                        errorString = "The input record was not found"
                    case .notAllowed:
                        errorString = "Request not allowed"
                    case .serverBusy:
                        errorString = "Too many requests or server is busy"
                    case .timeOut:
                        errorString = "The request timed out"
                    default:
                        errorString = "Your request returned a stauts code other than 2xx"
                    }
                    sendError(errorString + ": HTTP Status = \(statusCode)")
                }
                return
            }
            
            guard let data = data else {
                sendError("No data was returned by the request")
                return
            }
            
            completionHandler(data, nil)
        }
        
        task.resume()
        return task
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
            conformerEntity.compound = compound
            conformerEntity.conformerId = conformer.conformerId
            
            for atom in conformer.atoms {
                let atomEntity = AtomEntity(context: viewContext)
                atomEntity.atomicNumber = Int16(atom.number)
                atomEntity.coordX = atom.location[0]
                atomEntity.coordY = atom.location[1]
                atomEntity.coordZ = atom.location[2]
                atomEntity.conformer = conformerEntity
            }
        }
        
        do {
            try viewContext.save()
            NSLog("Saved in SearchByNameViewController.saveCompound(:)")
        } catch {
            NSLog("Error while saving in SearchByNameViewController.saveCompound(:)")
        }
        
        resetCompound()
    }
    
    // MARK: - Persistence History Request
    private lazy var historyRequestQueue = DispatchQueue(label: "history")
    private func fetchUpdates(_ notification: Notification) -> Void {
        print("fetchUpdates \(Date().description(with: Locale.current))")
        historyRequestQueue.async {
            let backgroundContext = self.dataController.persistentContainer.newBackgroundContext()
            backgroundContext.performAndWait {
                do {
                    let fetchHistoryRequest = NSPersistentHistoryChangeRequest.fetchHistory(after: self.lastToken)
                    
                    if let historyResult = try backgroundContext.execute(fetchHistoryRequest) as? NSPersistentHistoryResult,
                       let history = historyResult.result as? [NSPersistentHistoryTransaction] {
                        for transaction in history.reversed() {
                            self.dataController.viewContext.perform {
                                if let userInfo = transaction.objectIDNotification().userInfo {
                                    NSManagedObjectContext.mergeChanges(fromRemoteContextSave: userInfo,
                                                                        into: [self.dataController.viewContext])
                                }
                            }
                        }
                        
                        self.lastToken = history.last?.token
                    }
                } catch {
                    print("Could not convert history result to transactions after lastToken = \(String(describing: self.lastToken)): \(error)")
                }
                print("fetchUpdates \(Date().description(with: Locale.current))")
            }
        }
    }
    
    private var lastToken: NSPersistentHistoryToken? = nil {
        didSet {
            guard let token = lastToken,
                  let data = try? NSKeyedArchiver.archivedData(withRootObject: token, requiringSecureCoding: true) else {
                return
            }
            
            do {
                try data.write(to: tokenFile)
            } catch {
                let message = "Could not write token data"
                print("###\(#function): \(message): \(error)")
            }
        }
    }
    
    private lazy var tokenFile: URL = {
        let url = NSPersistentContainer.defaultDirectoryURL().appendingPathComponent("LinkCollector",isDirectory: true)
        if !FileManager.default.fileExists(atPath: url.path) {
            do {
                try FileManager.default.createDirectory(at: url,
                                                        withIntermediateDirectories: true,
                                                        attributes: nil)
            } catch {
                let message = "Could not create persistent container URL"
                print("###\(#function): \(message): \(error)")
            }
        }
        return url.appendingPathComponent("token.data", isDirectory: false)
    }()
}

extension SearchPubChemViewModel: CompoundCollectionViewDelegate {
    func selectedCompounds(_ compounds: [Compound], with title: String) {
        self.compounds = compounds
        self.solutionLabel = title
    }
}
