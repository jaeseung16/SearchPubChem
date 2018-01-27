//
//  PubChemSearch.swift
//  SearchPubChem
//
//  Created by Jae Seung Lee on 1/21/18.
//  Copyright © 2018 Jae Seung Lee. All rights reserved.
//

import Foundation

class PubChemSearch {
    var session = URLSession.shared
    
    func downloadImage(for compound: Compound, completionHandler: @escaping (_ success: Bool) -> Void) {
        guard let cid = compound.cid else {
            print("There is no CID.")
            completionHandler(false)
            return
        }
        
        var component = URLComponents()
        component.scheme = "https"
        component.host = "pubchem.ncbi.nlm.nih.gov"
        component.path = "/rest/pug/compound/cid/" + cid + "/PNG"
        
        _ = dataTask(with: component.url!, completionHandler: { (data, error) in
            func sendError(_ error: String) {
                let userInfo = [NSLocalizedDescriptionKey: error]
                completionHandler(false)
            }
            
            guard let data = data else {
                completionHandler(false)
                return
            }
            
            print("\(data)")
            compound.image = data as NSData
            
            completionHandler(true)
        })
    }

    
    func searchCompound(by name: String, completionHandler: @escaping (_ success: Bool, _ compound: Compound?) -> Void) -> Void {
        let properties = ["MolecularFormula", "MolecularWeight", "IUPACName"]
        
        searchCompound(by: name, for: properties) { (values, error) in
            guard (error == nil) else {
                print("\(String(describing: error!.userInfo[NSLocalizedDescriptionKey]))")
                completionHandler(false, nil)
                return
            }
            
            guard let values = values else {
                return
            }
            
            let CID = String(values["CID"] as! Int)
            let molecularFormula = values["MolecularFormula"] as! String
            let molecularWeight = values["MolecularWeight"] as! Double
            let nameIUPAC = values["IUPACName"] as! String
            
            //let compound = Compound(name: name, formula: molecularFormula, molecularWeight: molecularWeight, CID: CID, nameIUPAC: nameIUPAC, image: nil)
            
            print("CID: \(CID)")
            
            completionHandler(true, nil)
        }

    }
    
    // Change the name later
    func searchCompound(by name: String, for properties: [String], completionHandler: @escaping (_ values: [String: AnyObject]?, _ error: NSError?) -> Void) {
        let url = searchURL(by: name, for: properties)
        
        _ = dataTask(with: url) { (data, error) in
            func sendError(_ error: String) {
                let userInfo = [NSLocalizedDescriptionKey: error]
                completionHandler(nil, NSError(domain: "dataTask", code: 1, userInfo: userInfo))
            }
            
            guard let data = data else {
                completionHandler(nil, error)
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
    
    func searchURL(by name: String, for properties: [String]) -> URL {
        var pathForProperties = "/property/"
        
        for property in properties {
            pathForProperties += property + ","
        }
        pathForProperties.remove(at: pathForProperties.index(before: pathForProperties.endIndex))
        pathForProperties += "/json"
        
        var component = URLComponents()
        component.scheme = "https"
        component.host = "pubchem.ncbi.nlm.nih.gov"
        component.path = "/rest/pug/compound/name/" + name + pathForProperties
        
        return component.url!
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
                
                // errorString based on
                // https://pubchemdocs.ncbi.nlm.nih.gov/pug-rest$_Toc494865562
                switch(statusCode) {
                case 400:
                    errorString = "Request is improperly formed!"
                case 404:
                    errorString = "The input record was not found!"
                case 405:
                    errorString = "Request not allowed!"
                case 503:
                    errorString = "Too many requests or server is busy!"
                case 504:
                    errorString = "The request timed out!"
                default:
                    errorString = "Your request returned a stauts code other than 2xx!"
                }
                
                sendError(errorString)
                return
            }
            
            guard let data = data else {
                sendError("No data was returned by the request!")
                return
            }
            
            completionHandler(data, nil)
        }
        
        task.resume()
        return task
    }
}
