//
//  SearchByNameViewController.swift
//  SearchPubChem
//
//  Created by Jae Seung Lee on 1/17/18.
//  Copyright © 2018 Jae Seung Lee. All rights reserved.
//

import UIKit

class SearchByNameViewController: UIViewController {

    @IBOutlet weak var nameToSearch: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func searchByName(_ sender: UIButton) {
        let name = nameToSearch.text!
        
        let properties = ["MolecularFormula", "MolecularWeight", "IUPACName"]
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
        
        print("\(String(describing: component.url))")
        let request = URLRequest(url: component.url!)
        
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            func sendError(_ error: String) {
                let userInfo = [NSLocalizedDescriptionKey: error]
                print("Error: \(String(describing: userInfo[NSLocalizedDescriptionKey]))")
            }
            
            guard (error == nil) else {
                sendError("There was an error with your request: \(String(describing: error))!")
                return
            }
            
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else {
                let statusCode = (response as? HTTPURLResponse)!.statusCode
                var errorString: String
                
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
            
            let parsedResult: [String: AnyObject]!
            
            do {
                parsedResult = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String: AnyObject]
            } catch {
                print("Cannot parse JSON!")
                return
            }
            
            print("\(parsedResult)")
            
            guard let propertyTable = parsedResult["PropertyTable"] as? [String: AnyObject] else {
                sendError("There is no PropertyTable in: \(parsedResult)")
                return
            }
            
            guard let properties = propertyTable["Properties"] as? [[String: AnyObject]] else {
                sendError("There is no properties in: \(propertyTable)")
                return
            }
            
            let CID = properties[0]["CID"] as! Int
            let molecularFormula = properties[0]["MolecularFormula"] as! String
            let molecularWeight = properties[0]["MolecularWeight"] as! Double
            let nameIUPAC = properties[0]["IUPACName"] as! String
            
            print("CID: \(CID)")
            print("Molecular Formula: \(molecularFormula)")
            print("Molecular Weight: \(molecularWeight)")
            print("IUPAC Name: \(nameIUPAC)")
        }
        
        task.resume()
    }
    
    @IBAction func dismiss(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
