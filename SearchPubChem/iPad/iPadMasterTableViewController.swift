//
//  iPadMasterTableViewController.swift
//  SearchPubChem
//
//  Created by Jae Seung Lee on 7/16/20.
//  Copyright © 2020 Jae Seung Lee. All rights reserved.
//

import UIKit
import CoreData

class iPadMasterTableViewController: UITableViewController {
    // MARK: - Properties
    // Constants
    let menuItems = ["Compounds", "Solutions"]
    let collectionViewControllerIdentifier = "iPadCompoundCollectionViewController"
    let solutionViewControllerIdentifier = "SolutionTableViewController"
    
    // Variables
    var compoundCollectionViewController: iPadCompoundCollectionViewController?
    var solutionTableViewController: SolutionTableViewController?
    var dataController: DataController!
    var compounds = [Compound]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupCompoundCollectionViewController()
        setupSolutionCollectionViewController()
    }
    
    func setupCompoundCollectionViewController() -> Void {
        compoundCollectionViewController = UIStoryboard(name: "iPad", bundle: nil).instantiateViewController(withIdentifier: collectionViewControllerIdentifier) as? iPadCompoundCollectionViewController
               
        compoundCollectionViewController?.dataController = dataController
    }
    
    func setupSolutionCollectionViewController() -> Void {
        solutionTableViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: solutionViewControllerIdentifier) as? SolutionTableViewController
               
        solutionTableViewController?.dataController = dataController
    }

    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return menuItems.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MenuItemTableCell", for: indexPath)
        
        cell.textLabel!.text = menuItems[indexPath.row]
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let detailViewController = splitViewController?.viewControllers.last as? UINavigationController {
            detailViewController.popToRootViewController(animated: false)
            switch indexPath.row {
            case 0:
                if compoundCollectionViewController! != detailViewController.topViewController {
                    detailViewController.pushViewController(compoundCollectionViewController!, animated: false)
                }
            case 1:
                if solutionTableViewController! != detailViewController.topViewController {
                    detailViewController.pushViewController(solutionTableViewController!, animated: false)
                }
            default:
                if compoundCollectionViewController! != detailViewController.topViewController {
                    detailViewController.pushViewController(compoundCollectionViewController!, animated: false)
                }
            }
        }
    }

}

