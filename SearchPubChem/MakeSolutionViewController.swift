//
//  MakeSolutionViewController.swift
//  SearchPubChem
//
//  Created by Jae Seung Lee on 1/28/18.
//  Copyright © 2018 Jae Seung Lee. All rights reserved.
//

import UIKit
import CoreData

class MakeSolutionViewController: UIViewController {

    @IBOutlet weak var addCompound: UIButton!
    @IBOutlet weak var solutionTableView: UITableView!
    
    let maxNumberOfCompounds = 10
    var cids = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        print(cids)
        solutionTableView.reloadData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func dismiss(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        
        if (sender as? UIButton) != nil {
            // Get the stack
            let delegate = UIApplication.shared.delegate as! AppDelegate
            let stack = delegate.stack
            
            // Fetching compounds
            let fr = NSFetchRequest<NSFetchRequestResult>(entityName: "Compound")
            fr.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
            
            let fc = NSFetchedResultsController(fetchRequest: fr, managedObjectContext: stack.context, sectionNameKeyPath: nil, cacheName: nil)
            
            do {
                try fc.performFetch()
            } catch {
                print("Error while performing search: \n\(error)\n\(String(describing: fc))")
                return
            }
            
            // Set up the fetchedResultsController of CompoundCollectionViewController
            if let compoundCollectionViewController = segue.destination as? CompoundCollectionViewController {
                compoundCollectionViewController.fetchedResultsController = fc
                compoundCollectionViewController.delegate = self
                compoundCollectionViewController.cids = cids
                present(compoundCollectionViewController, animated: true, completion: nil)
            }
        }
    }
    
}

extension MakeSolutionViewController: CompoundCollectionViewDelegate {
    func selectedCompounds(with cids: [String]) {
        self.cids = cids
    }
}

extension MakeSolutionViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cids.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MakeSolutionTableViewCell")!
        
        cell.textLabel?.text = cids[indexPath.row]
        print(cids)
        
        return cell
    }
}

// MARK: - UITextFieldDelegate
extension MakeSolutionViewController: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        textField.text = ""
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
