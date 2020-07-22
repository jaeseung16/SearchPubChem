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
    
    let menuItems = ["Compounds", "Solutions"]
    
    var compoundCollectionViewController: iPadCompoundCollectionViewController?
    var solutionTableViewController: SolutionTableViewController?
    var dataController: DataController!
    var compounds = [Compound]()
    let collectionViewControllerIdentifier = "iPadCompoundCollectionViewController"
    let solutionViewControllerIdentifier = "SolutionTableViewController"

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
        
        setupCompoundCollectionViewController()
        setupSolutionCollectionViewController()
    }
    
    func setupCompoundCollectionViewController() -> Void {
        print("setupCompoundCollectionViewController")
        compoundCollectionViewController = UIStoryboard(name: "iPad", bundle: nil).instantiateViewController(withIdentifier: collectionViewControllerIdentifier) as? iPadCompoundCollectionViewController
               
        compoundCollectionViewController?.dataController = dataController
        compoundCollectionViewController?.fetchedResultsController = setupFetchedResultsControllerForCompound()
        //compoundCollectionViewController?.delegate = self
        //compoundCollectionViewController?.compounds = compounds
    }
    
    func setupSolutionCollectionViewController() -> Void {
        solutionTableViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: solutionViewControllerIdentifier) as? SolutionTableViewController
               
        solutionTableViewController?.dataController = dataController
    }
    
    func setupFetchedResultsControllerForCompound() -> NSFetchedResultsController<Compound> {
        let sortDescriptor = NSSortDescriptor(key: "name", ascending: true)
        
        let fetchRequest: NSFetchRequest<Compound> = Compound.fetchRequest()
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        return NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: "firstCharacterInName", cacheName: "compounds")
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return menuItems.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MenuItemTableCell", for: indexPath)
        
        cell.textLabel!.text = menuItems[indexPath.row]
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let detailViewController = splitViewController?.viewControllers.last as? UINavigationController {
            if detailViewController.topViewController != nil {
                detailViewController.popViewController(animated: true)
            }
            switch indexPath.row {
            case 0:
                if compoundCollectionViewController! != detailViewController.topViewController {
                    detailViewController.pushViewController(compoundCollectionViewController!, animated: true)
                }
            case 1:
                if solutionTableViewController! != detailViewController.topViewController {
                    detailViewController.pushViewController(solutionTableViewController!, animated: true)
                }
            default:
                if compoundCollectionViewController! != detailViewController.topViewController {
                    detailViewController.pushViewController(compoundCollectionViewController!, animated: true)
                }
            }
            print("\(detailViewController.viewControllers.count)")
        }
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

