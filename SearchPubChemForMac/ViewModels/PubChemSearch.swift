//
//  PubChemSearcher.swift
//  SearchPubChemForMac
//
//  Created by Jae Seung Lee on 2/9/21.
//  Copyright © 2021 Jae Seung Lee. All rights reserved.
//

import Foundation

class PubChemSearch {
    // MARK: - Properties
    // Variable
    var session = URLSession.shared
    
    // MARK: - Methods
    func download3DData(for cid: String, completionHandler: @escaping (_ success: Bool, _ conformer: Conformer?, _ errorString: String?) -> Void) {
        var component = commonURLComponents()
        component.path = PubChemSearch.Constant.pathForCID + cid + "/JSON"
        component.query = "\(QueryString.recordType)=\(RecordType.threeD)"
        
        _ = dataTask(with: component.url!, completionHandler: { (data, error) in
            func sendError(_ error: String) {
                print(error)
                completionHandler(false, nil, error)
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
                print("Error while parsing data as conformerDTO = \(String(describing: dto))")
                return
            }
            let conformer = self.populateConformer(from: conformerDTO.pcCompounds[0])
            
            completionHandler(true, conformer, nil)
        })
    }
        
    func decode<T: Codable>(from data: Data) -> T? {
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
    
    func populateConformer(from pcCompound: PCCompound) -> Conformer {
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
    
    func getConformerId(from pcCompound: PCCompound) -> String {
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
    
    func getAtomLocation(index: Int, from conformerData: ConformerData) -> [Double] {
        let x = conformerData.x[index]
        let y = conformerData.y[index]
        let z = conformerData.z[index]
        
        return [Double](arrayLiteral: x, y, z)
    }

    
    func downloadImage(for cid: String, completionHandler: @escaping (_ success: Bool, _ image: NSData?, _ errorString: String?) -> Void) {
        var component = commonURLComponents()
        component.path = PubChemSearch.Constant.pathForCID + cid + PubChemSearch.QueryResult.png
        
        _ = dataTask(with: component.url!, completionHandler: { (data, error) in
            guard error == nil else {
                NSLog("Error while downloading an image: \(String(describing: error!.userInfo[NSLocalizedDescriptionKey]))")
                completionHandler(false, nil, error!.userInfo[NSLocalizedDescriptionKey] as? String)
                return
            }
        
            guard let data = data else {
                NSLog("Missing image data")
                completionHandler(false, nil, "Missing image data")
                return
            }

            completionHandler(true, data as NSData, nil)
        })
    }
    
    func searchCompound(name: String, completionHandler: @escaping (_ success: Bool, _ compoundProperties: Properties?, _ errorString: String?) -> Void) -> Void {
        let properties = [PubChemSearch.PropertyKey.formula,
                          PubChemSearch.PropertyKey.weight,
                          PubChemSearch.PropertyKey.nameIUPAC]
        
        searchProperties(of: name, properties: properties) { (properties, error) in
            guard (error == nil) else {
                NSLog("Error while getting properties: \(String(describing: error!.userInfo[NSLocalizedDescriptionKey]))")
                completionHandler(false, nil, error!.userInfo[NSLocalizedDescriptionKey] as? String)
                return
            }
            
            guard let properties = properties else {
                NSLog("Missing property values")
                completionHandler(false, nil, "Missing property values")
                return
            }
            
            completionHandler(true, properties, nil)
        }
    }
    
    func searchProperties(of name: String, properties: [String], completionHandler: @escaping (_ properties: Properties?, _ error: NSError?) -> Void) {
        let url = searchURL(of: name, for: properties)
        
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
            
            let dto : CompoundDTO? = self.decode(from: data)
            guard let compoundDTO = dto else {
                sendError("Error while pasring data as compoundDTO = \(String(describing: dto))")
                return
            }
            
            completionHandler(compoundDTO.propertyTable.properties[0], nil)
        }
    }
    
    func searchURL(of name: String, for properties: [String]) -> URL {
        var pathForProperties = PubChemSearch.Constant.pathForProperties
        
        for property in properties {
            pathForProperties += property + ","
        }
        pathForProperties.remove(at: pathForProperties.index(before: pathForProperties.endIndex))
        pathForProperties += PubChemSearch.QueryResult.json
        
        var component = commonURLComponents()
        component.path = PubChemSearch.Constant.pathForName + name + pathForProperties
        
        return component.url!
    }
    
    func urlForPubChem(with compound: CompoundEntity) -> URL? {
        guard let cid = compound.cid else {
            return nil
        }
        
        var component = commonURLComponents()
        component.path = PubChemSearch.Constant.pathForWeb + "\(cid)"
        
        return component.url
    }
    
    func commonURLComponents() -> URLComponents {
        var component = URLComponents()
        component.scheme = PubChemSearch.Constant.scheme
        component.host = PubChemSearch.Constant.host
        
        return component
    }
    
    func dataTask(with url: URL, completionHandler: @escaping (_ data: Data?, _ error: NSError?) -> Void) -> URLSessionTask {
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
}
