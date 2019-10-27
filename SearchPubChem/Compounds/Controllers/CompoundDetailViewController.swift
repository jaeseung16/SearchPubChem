//
//  CompoundDetailViewController.swift
//  SearchPubChem
//
//  Created by Jae Seung Lee on 1/21/18.
//  Copyright © 2018 Jae Seung Lee. All rights reserved.
//

import UIKit
import CoreData

class CompoundDetailViewController: UIViewController {
    // MARK: - Properties
    // Outlets
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var formulaLabel: UILabel!
    @IBOutlet weak var weightLabel: UILabel!
    @IBOutlet weak var cidLabel: UILabel!
    @IBOutlet weak var iupacLabel: UILabel!
    @IBOutlet weak var compoundImageView: UIImageView!
    @IBOutlet weak var deleteButton: UIBarButtonItem!
    @IBOutlet weak var solutionsTableView: UITableView!    
    @IBOutlet weak var conformerButton: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    // Constants
    let detailViewControllerIdentifier = "SolutionDetailViewController"
    let tableViewCellIdentifier = "SolutionMadeOfCompoundTableViewCell"
    let webViewControllerIdentifer = "WebPubChemViewController"
    
    // Variables
    var compound: Compound!
    var conformer: Conformer?
    
    var dataController: DataController!
    var fetchedResultsController: NSFetchedResultsController<Solution>! {
        didSet {
            fetchedResultsController.delegate = self
            
            do {
                try fetchedResultsController.performFetch()
            } catch {
                NSLog("Solutions cannot be fetched for the compound: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        solutionsTableView.reloadData()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let conformerViewController = segue.destination as? ConformerViewController {
            guard let conformer = self.conformer else {
                print("No 3D Data")
                return
            }
            
            conformerViewController.conformer = conformer
            conformerViewController.name = compound.name?.uppercased()
            conformerViewController.formula = compound.formula
        }
    }
    
    func configureView() {
        activityIndicator.isHidden = true
        nameLabel.text = compound.name?.uppercased()
        formulaLabel.text = compound.formula
        weightLabel.text = "\(String(describing: compound.molecularWeight)) gram/mol"
        cidLabel.text = "PubChem CID: \(compound.cid!)"
        iupacLabel.text = "IUPAC Name: \(compound.nameIUPAC!)"
        
        if let image = compound.image as Data? {
            compoundImageView.image = UIImage(data: image)
        }
        
        if let solutions = fetchedResultsController.fetchedObjects {
            deleteButton.isEnabled = (solutions.count == 0)
        }
        
        guard compound.conformerDownloaded else {
            activityIndicator.isHidden = false
            conformerButton.isHidden = true
            let client = PubChemSearch()
            client.download3DData(for: self.compound.cid!, completionHandler: { (success, conformer, errorString) in
                //self.showNetworkIndicators(false)
                if success, let conformer = conformer {
                    DispatchQueue.main.async {
                        self.conformer = conformer
                        
                        let conformerEntity = ConformerEntity(context: self.dataController.viewContext)
                        if let conformer = self.conformer {
                            conformerEntity.compound = self.compound
                            conformerEntity.conformerId = conformer.conformerId
                        
                            for atom in conformer.atoms {
                                let atomEntity = AtomEntity(context: self.dataController.viewContext)
                                atomEntity.atomicNumber = Int16(atom.number)
                                atomEntity.coordX = atom.location[0]
                                atomEntity.coordY = atom.location[1]
                                atomEntity.coordZ = atom.location[2]
                                atomEntity.conformer = conformerEntity
                            }
                        }
                    }
                }
                
                self.compound.conformerDownloaded = true
                do {
                    try self.dataController.viewContext.save()
                    NSLog("Saved in SearchByNameViewController.saveCompound(:)")
                } catch {
                    NSLog("Error while saving in SearchByNameViewController.saveCompound(:)")
                }
                
                DispatchQueue.main.async {
                    self.activityIndicator.isHidden = true
                    if self.conformer != nil {
                        self.conformerButton.isHidden = false
                    }
                }
            })
            
            return
        }
    
        let fetchRequest: NSFetchRequest<ConformerEntity> = ConformerEntity.fetchRequest()
        let sortDescription = NSSortDescriptor(key: "created", ascending: false)
        let predicate = NSPredicate(format: "compound == %@", argumentArray: [compound as Any])

        fetchRequest.sortDescriptors = [sortDescription]
        fetchRequest.predicate = predicate
       
        let fc = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        
        fc.delegate = self
        
        do {
            try fc.performFetch()
        } catch {
            NSLog("Conformers cannot be fetched for the compound: \(error.localizedDescription)")
        }
        
        if let conformers = fc.fetchedObjects {
            conformerButton.isHidden = (conformers.count == 0)
            
            if conformers.count > 0 {
                let fetchRequest2: NSFetchRequest<AtomEntity> = AtomEntity.fetchRequest()
                let sortDescription = NSSortDescriptor(key: "created", ascending: false)
                let predicate2 = NSPredicate(format: "conformer == %@", argumentArray: [conformers[0] as Any])

                fetchRequest2.sortDescriptors = [sortDescription]
                fetchRequest2.predicate = predicate2
                
                let fc2 = NSFetchedResultsController(fetchRequest: fetchRequest2, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: nil)
                 
                fc2.delegate = self
                 
                do {
                    try fc2.performFetch()
                } catch {
                    NSLog("Conformers cannot be fetched for the compound: \(error.localizedDescription)")
                }
                
                if let atoms = fc2.fetchedObjects {
                    conformer = Conformer()
                    conformer?.cid = compound.cid ?? ""
                    conformer?.conformerId = conformers[0].conformerId ?? ""
                    
                    conformer?.atoms = [Atom]()
                    for atom in atoms {
                        let a = Atom()
                        a.number = Int(atom.atomicNumber)
                        a.location = [atom.coordX, atom.coordY, atom.coordZ]
                        
                        conformer?.atoms.append(a)
                    }
                }
            }
        }
    }
    
    // Actions
    @IBAction func deleteAndDismiss(_ sender: UIBarButtonItem) {
        dataController.viewContext.delete(compound)
        
        do {
            try dataController.viewContext.save()
        } catch {
            NSLog("Error while saving: \(error.localizedDescription)")
        }
        
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func searchPubChem(_ sender: UIBarButtonItem) {
        let client = PubChemSearch()
        guard let url = client.urlForPubChem(with: compound) else {
            return
        }
        
        let webViewController = storyboard?.instantiateViewController(withIdentifier: webViewControllerIdentifer) as! WebPubChemViewController
        webViewController.url = url
        
        navigationController?.pushViewController(webViewController, animated: true)
    }
}

// MARK: - UITableViewDataSource, UITableViewDelegate
extension CompoundDetailViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return fetchedResultsController.sections?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fetchedResultsController.sections?[section].numberOfObjects ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: tableViewCellIdentifier)!
        let solution = fetchedResultsController.object(at: indexPath)
        
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
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let solution = fetchedResultsController.object(at: indexPath)
        let detailViewController = storyboard?.instantiateViewController(withIdentifier: detailViewControllerIdentifier) as! SolutionDetailViewController
        
        detailViewController.solution = solution
        detailViewController.delegate = self
        
        navigationController?.pushViewController(detailViewController, animated: true)
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

// MARK: - SolutionDetailViewControllerDelegate
extension CompoundDetailViewController: SolutionDetailViewControllerDelegate {
    func remove(solution: Solution) {
        dataController.viewContext.delete(solution)
        solutionsTableView.reloadData()
        
        do {
            try dataController.viewContext.save()
            NSLog("Saved in SolutionTableViewController.remove(solution:)")
        } catch {
            NSLog("Error while saving in SolutionTableViewController.remove(solution:)")
        }
    }
}

// MARK: - NSFetchedResultsControllerDelegate
extension CompoundDetailViewController: NSFetchedResultsControllerDelegate {
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        solutionsTableView.beginUpdates()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        let set = IndexSet(integer: sectionIndex)
        
        switch (type) {
        case .insert:
            solutionsTableView.insertSections(set, with: .fade)
        case .delete:
            solutionsTableView.deleteSections(set, with: .fade)
        default:
            break
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch(type) {
        case .insert:
            solutionsTableView.insertRows(at: [newIndexPath!], with: .fade)
        case .delete:
            solutionsTableView.deleteRows(at: [indexPath!], with: .fade)
        case .update:
            solutionsTableView.reloadRows(at: [indexPath!], with: .fade)
        case .move:
            solutionsTableView.deleteRows(at: [indexPath!], with: .fade)
            solutionsTableView.insertRows(at: [newIndexPath!], with: .fade)
        @unknown default:
            fatalError("Unknown change type: \(type)")
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        solutionsTableView.endUpdates()
    }
}
