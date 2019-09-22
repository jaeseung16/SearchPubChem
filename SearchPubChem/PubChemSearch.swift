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
    func download3DData(for cid: String, completionHandler: @escaping (_ success: Bool, _ conformerId: String, _ atoms: [Atoms]?, _ errorString: String?) -> Void) {
        var component = commonURLComponents()
        component.path = PubChemSearch.Constant.pathForCID + cid + "/JSON"
        component.query = "\(QueryString.recordType)=\(RecordType.threeD)"
        
        _ = dataTask(with: component.url!, completionHandler: { (data, error) in
            func sendError(_ error: String) {
                print(error)
                completionHandler(false, "", nil, error)
            }
            
            guard error == nil else {
                NSLog("Error while downloading 3d data: \(String(describing: error!.userInfo[NSLocalizedDescriptionKey]))")
                sendError(error!.userInfo[NSLocalizedDescriptionKey] as! String)
                return
            }
            
            guard let data = data else {
                NSLog("Missing 3d data")
                sendError("Missing image data")
                return
            }
            
            let parsedResult: [String: AnyObject]!
            
            do {
                parsedResult = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: AnyObject]
            } catch {
                sendError("Cannot parse JSON!")
                return
            }
            
            guard let propertyTable = parsedResult[Conformer.pcCompounds.rawValue] as? [[String: AnyObject]] else {
                sendError("There is no PropertyTable in: \(String(describing: parsedResult))")
                return
            }
            
            guard let atoms = propertyTable[0][Conformer.atoms.rawValue] as? [String: AnyObject] else {
                sendError("There is no atoms in: \(propertyTable)")
                return
            }
            
            guard let _ = atoms[Conformer.aid.rawValue] as? [Int], let elements = atoms["element"] as? [Int] else {
                sendError("There is no atoms in: \(propertyTable)")
                return
            }
            
            print("\(elements)")
            var elementArray = [Atoms]()
            for element in elements {
                guard let elem = Elements(rawValue: element) else {
                    print("Not a valid number for an element: \(element)")
                    continue
                }
                
                let atom = Atoms()
                atom.element = elem.getElement()
                switch elem {
                case .hydrogen:
                    atom.color = .black
                case .carbon:
                    atom.color = .darkGray
                case .nitrogen:
                    atom.color = UIColor(displayP3Red: 34/255, green: 51/255, blue: 255/255, alpha: 1.0)
                case .oxygen:
                    atom.color = .red
                default:
                    atom.color = UIColor(displayP3Red: 221/255, green: 119/255, blue: 255/255, alpha: 1.0)
                }
                elementArray.append(atom)
            }
            
            guard let coords = propertyTable[0][Conformer.coords.rawValue] as? [[String: AnyObject]] else {
                sendError("There is no coords in: \(propertyTable)")
                return
            }
            
            guard let coordIds = coords[0][Conformer.aid.rawValue] as? [Int] else {
                sendError("There is no atoms in: \(coords)")
                return
            }
            
            guard let conformers = coords[0][Conformer.conformers.rawValue] as? [[String: AnyObject]] else {
                sendError("There is no conformers in: \(coords)")
                return
            }
            
            guard let xs = conformers[0][Conformer.x.rawValue] as? [Double], let ys = conformers[0][Conformer.y.rawValue] as? [Double], let zs = conformers[0][Conformer.z.rawValue] as? [Double] else {
                sendError("There is no xyz's in: \(conformers)")
                return
            }
            
            guard let infos = conformers[0][Conformer.data.rawValue] as? [[String: Any]] else {
                sendError("There is no conformer id in: \(conformers[0][Conformer.data.rawValue])")
                return
            }
            
            var conformerId = ""
            for info in infos {
                guard let urn = info["urn"] as? [String: Any], let label = urn["label"] as? String else {
                    continue
                }
                
                if label == "Conformer" {
                    guard let value = info["value"] as? [String: Any], let sval = value["sval"] as? String else {
                        sendError("There is no conformer id in: \(info["value"])")
                        return
                    }
                    conformerId = sval
                }
            }
            
//            for id in coordIds.indices {
//                print("\(elements[id]) - (\(xs[id]), \(ys[id]), \(zs[id]))")
//            }
//
            for id in coordIds.indices {
                elementArray[id].location = [Double](arrayLiteral: xs[id], ys[id], zs[id])
            }
            
            completionHandler(true, conformerId, elementArray, nil)
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
