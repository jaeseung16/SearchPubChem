//
//  ChemicalTableViewController.swift
//  SearchPubChem
//
//  Created by Jae Seung Lee on 1/15/18.
//  Copyright © 2018 Jae Seung Lee. All rights reserved.
//

import UIKit
import CoreData

class ChemicalTableViewController: CoreDataTableViewController {

    let tableViewCellIdentifier = "ChemicalTableViewCell"
    
    var compounds = [Compound]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        fetchCompounds()
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.tableView.reloadData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        if let fc = fetchedResultsController {
            return (fc.sections?.count)!
        } else {
            return 0
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let fc = fetchedResultsController {
            return fc.sections![section].numberOfObjects
        } else {
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if let fc = fetchedResultsController {
            return fc.sections![section].name
        } else {
            return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        if let fc = fetchedResultsController {
            return fc.section(forSectionIndexTitle: title, at: index)
        } else {
            return 0
        }
    }
    
    override func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        if let fc = fetchedResultsController {
            return fc.sectionIndexTitles
        } else {
            return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: tableViewCellIdentifier, for: indexPath)

        let compound = fetchedResultsController?.object(at: indexPath) as! Compound
        
        cell.textLabel?.text = compound.name
        cell.detailTextLabel?.text = compound.formula

        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let compound = fetchedResultsController?.object(at: indexPath) as! Compound
        
        let detailViewController = self.storyboard?.instantiateViewController(withIdentifier: "CompoundDetailViewController") as! CompoundDetailViewController
        detailViewController.compound = compound
        
        present(detailViewController, animated: true, completion: nil)
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

extension ChemicalTableViewController {
    func fetchCompounds() {
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let stack = delegate.stack
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Compound")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "created", ascending: false)]
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: stack.context, sectionNameKeyPath: nil, cacheName: nil)
    }
}
