//
//  PubChemSearch.swift
//  SearchPubChem
//
//  Created by Jae Seung Lee on 1/21/18.
//  Copyright © 2018 Jae Seung Lee. All rights reserved.
//

import Foundation

class PubChemSearch {
    // MARK: - Properties
    // Variable
    var session = URLSession.shared
    
    // MARK: - Methods
    
    func downloadImage(for cid: String, completionHandler: @escaping (_ success: Bool, _ image: NSData?) -> Void) {
        var component = URLComponents()
        component.scheme = PubChemSearch.Constant.scheme
        component.host = PubChemSearch.Constant.host
        component.path = PubChemSearch.Constant.pathForCID + cid + PubChemSearch.QueryResult.png
        
        _ = dataTask(with: component.url!, completionHandler: { (data, error) in
            guard error == nil else {
                NSLog("Error while downloading an image: \(String(describing: error!.userInfo[NSLocalizedDescriptionKey]))")
                completionHandler(false, nil)
                return
            }
        
            guard let data = data else {
                NSLog("Missing image data)")
                completionHandler(false, nil)
                return
            }

            completionHandler(true, data as NSData)
        })
    }
    
    func searchCompound(by name: String, completionHandler: @escaping (_ success: Bool, _ compoundInformation: [String: Any]?) -> Void) -> Void {
        let properties = [PubChemSearch.PropertyKey.formula,
                          PubChemSearch.PropertyKey.weight,
                          PubChemSearch.PropertyKey.nameIUPAC]
        
        searchProperties(of: name, properties: properties) { (values, error) in
            guard (error == nil) else {
                NSLog("Error while getting properties: \(String(describing: error!.userInfo[NSLocalizedDescriptionKey]))")
                completionHandler(false, nil)
                return
            }
            
            guard let values = values else {
                NSLog("Missing property values")
                completionHandler(false, nil)
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
            
            completionHandler(true, compoundInformation)
        }
    }
    
    func searchProperties(of name: String, properties: [String], completionHandler: @escaping (_ values: [String: AnyObject]?, _ error: NSError?) -> Void) {
        let url = searchURL(of: name, for: properties)
        
        _ = dataTask(with: url) { (data, error) in
            func sendError(_ error: String) {
                let userInfo = [NSLocalizedDescriptionKey: error]
                completionHandler(nil, NSError(domain: "dataTask", code: 1, userInfo: userInfo))
            }
            
            guard let data = data else {
                sendError("Cannot get the data!")
                return
            }
            
            let parsedResult: [String: AnyObject]!
            
            do {
                parsedResult = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String: AnyObject]
            } catch {
                sendError("Cannot parse JSON!")
                return
            }
            
            guard let propertyTable = parsedResult["PropertyTable"] as? [String: AnyObject] else {
                sendError("There is no PropertyTable in: \(parsedResult)")
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
        
        var component = URLComponents()
        component.scheme = PubChemSearch.Constant.scheme
        component.host = PubChemSearch.Constant.host
        component.path = PubChemSearch.Constant.pathForName + name + pathForProperties
        
        return component.url!
    }
    
    func urlForPubChem(with compound: Compound) -> URL? {
        guard let cid = compound.cid else {
            return nil
        }
        
        var component = URLComponents()
        component.scheme = PubChemSearch.Constant.scheme
        component.host = PubChemSearch.Constant.host
        component.path = PubChemSearch.Constant.pathForWeb + "\(cid)"
        
        return component.url
    }
    
    func dataTask(with url: URL, completionHandler: @escaping (_ data: Data?, _ error: NSError?) -> Void) -> URLSessionTask {
        let request = URLRequest(url: url)
        
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
