//
//  PubChemSearch.swift
//  SearchPubChem
//
//  Created by Jae Seung Lee on 1/21/18.
//  Copyright © 2018 Jae Seung Lee. All rights reserved.
//

import Foundation
import UIKit

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
            
            let parsedResult: [String: AnyObject]!
            
            do {
                parsedResult = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: AnyObject]
            } catch {
                sendError("Cannot parse JSON!")
                return
            }
            
            guard let pcCompounds = parsedResult[ConformerEnum.pcCompounds.rawValue] as? [[String: AnyObject]] else {
                sendError("There is no pcCompounds in: \(String(describing: parsedResult))")
                return
            }
            
            guard let atoms = pcCompounds[0][ConformerEnum.atoms.rawValue] as? [String: AnyObject] else {
                sendError("There is no atoms in: \(pcCompounds)")
                return
            }
            
            guard let _ = atoms[ConformerEnum.aid.rawValue] as? [Int], let elements = atoms["element"] as? [Int] else {
                sendError("There is no elements in: \(atoms)")
                return
            }
            
            guard let coords = pcCompounds[0][ConformerEnum.coords.rawValue] as? [[String: AnyObject]] else {
                sendError("There is no coords in: \(pcCompounds)")
                return
            }
            
            guard let coordIds = coords[0][ConformerEnum.aid.rawValue] as? [Int] else {
                sendError("There is no coordIds in: \(coords)")
                return
            }
            
            guard let conformers = coords[0][ConformerEnum.conformers.rawValue] as? [[String: AnyObject]] else {
                sendError("There is no conformers in: \(coords)")
                return
            }
            
            guard let xs = conformers[0][ConformerEnum.x.rawValue] as? [Double],
                let ys = conformers[0][ConformerEnum.y.rawValue] as? [Double],
                let zs = conformers[0][ConformerEnum.z.rawValue] as? [Double] else {
                sendError("There is no xyz locations in: \(conformers[0])")
                return
            }
            
            guard let infos = conformers[0][ConformerEnum.data.rawValue] as? [[String: Any]] else {
                sendError("There is no data in: \(conformers[0])")
                return
            }
            
            var conformerId = ""
            for info in infos {
                guard let urn = info["urn"] as? [String: Any], let label = urn["label"] as? String else {
                    continue
                }
                
                if label == "Conformer" {
                    guard let value = info["value"] as? [String: Any], let sval = value["sval"] as? String else {
                        sendError("There is no conformer id in: \(String(describing: info["value"]))")
                        return
                    }
                    conformerId = sval
                }
            }
            
        
            let conformer = Conformer()
            conformer.cid = cid
            conformer.conformerId = conformerId
            
            for id in coordIds.indices {
                let atom = Atom()
                atom.number = elements[id]
                atom.location = [Double](arrayLiteral: xs[id], ys[id], zs[id])
                
                conformer.atoms.append(atom)
            }
            
            completionHandler(true, conformer, nil)
        })
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
    
    func searchCompound(by name: String, completionHandler: @escaping (_ success: Bool, _ compoundInformation: [String: Any]?, _ errorString: String?) -> Void) -> Void {
        let properties = [PubChemSearch.PropertyKey.formula,
                          PubChemSearch.PropertyKey.weight,
                          PubChemSearch.PropertyKey.nameIUPAC]
        
        searchProperties(of: name, properties: properties) { (values, error) in
            guard (error == nil) else {
                NSLog("Error while getting properties: \(String(describing: error!.userInfo[NSLocalizedDescriptionKey]))")
                completionHandler(false, nil, error!.userInfo[NSLocalizedDescriptionKey] as? String)
                return
            }
            
            guard let values = values else {
                NSLog("Missing property values")
                completionHandler(false, nil, "Missing property values")
                return
            }
            
            let cid = String(values["CID"] as! Int)
            let molecularFormula = values["MolecularFormula"] as! String
            let molecularWeight = values["MolecularWeight"] as! Double
            let nameIUPAC = values["IUPACName"] as! String
            
            let compoundInformation: [String: Any] = [PubChemSearch.PropertyKey.cid: cid,
                                                      PubChemSearch.PropertyKey.formula: molecularFormula,
                                                      PubChemSearch.PropertyKey.weight: molecularWeight,
                                                      PubChemSearch.PropertyKey.nameIUPAC: nameIUPAC]
            
            completionHandler(true, compoundInformation, nil)
        }
    }
    
    func searchProperties(of name: String, properties: [String], completionHandler: @escaping (_ values: [String: AnyObject]?, _ error: NSError?) -> Void) {
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
            
            let parsedResult: [String: AnyObject]!
            
            do {
                parsedResult = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: AnyObject]
            } catch {
                sendError("Cannot parse JSON!")
                return
            }
            
            guard let propertyTable = parsedResult["PropertyTable"] as? [String: AnyObject] else {
                sendError("There is no PropertyTable in: \(String(describing: parsedResult))")
                return
            }
            
            guard let properties = propertyTable["Properties"] as? [[String: AnyObject]] else {
                sendError("There is no properties in: \(propertyTable)")
                return
            }
            
            completionHandler(properties[0], nil)
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
    
    func urlForPubChem(with compound: Compound) -> URL? {
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
