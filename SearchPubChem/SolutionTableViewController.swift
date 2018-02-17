//
//  SolutionTableViewController.swift
//  SearchPubChem
//
//  Created by Jae Seung Lee on 2/6/18.
//  Copyright © 2018 Jae Seung Lee. All rights reserved.
//

import UIKit
import CoreData

class SolutionTableViewController: CoreDataTableViewController {

    let tableViewCellIdentifier = "SolutionTableViewCell"
    
    var solutions = [Solution]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        fetchSolutions()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.tableView.reloadData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: tableViewCellIdentifier, for: indexPath)
        
        let solution = fetchedResultsController?.object(at: indexPath) as! Solution
        
        cell.textLabel?.text = solution.name
        
        if let date = solution.created {
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            dateFormatter.timeStyle = .none
            dateFormatter.locale = Locale.current
            
            cell.detailTextLabel?.text = dateFormatter.string(from: date as Date)
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let solution = fetchedResultsController?.object(at: indexPath) as! Solution
        
        let detailViewController = self.storyboard?.instantiateViewController(withIdentifier: "SolutionDetailViewController") as! SolutionDetailViewController
        detailViewController.solution = solution
        
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

extension SolutionTableViewController {
    func fetchSolutions() {
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let stack = delegate.stack
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Solution")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "created", ascending: false)]
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: stack.context, sectionNameKeyPath: nil, cacheName: nil)
    }
}
