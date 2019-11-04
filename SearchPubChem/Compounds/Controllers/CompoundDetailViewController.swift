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
            downloadConformer()
            return
        }
        
        if let conformers = findConformers() {
            conformerButton.isHidden = (conformers.count == 0)
            
            if !conformerButton.isHidden {
                if let atoms = findAtoms(for: conformers[0]) {
                    populateConformer(for: conformers[0], with: atoms)
                }
            }
        }
    }
    
    func downloadConformer() {
        let client = PubChemSearch()
        client.download3DData(for: self.compound.cid!, completionHandler: { (success, conformer, errorString) in
            //self.showNetworkIndicators(false)
            if success, let conformer = conformer {
                //DispatchQueue.main.async {
                self.conformer = conformer
                self.populateConformerEntity()
                //}
            }
            
            self.compound.conformerDownloaded = true
            
            do {
                try self.dataController.viewContext.save()
                NSLog("Saved in CompoundDetailViewController.downloadConformer(:)")
            } catch {
                NSLog("Error while saving in CompoundDetailViewController.downloadConformer(:)")
            }
            
            DispatchQueue.main.async {
                self.activityIndicator.isHidden = true
                if self.conformer != nil {
                    self.conformerButton.isHidden = false
                }
            }
        })
    }
    
    func populateConformerEntity() {
        let conformerEntity = ConformerEntity(context: dataController.viewContext)
        if let conformer = self.conformer {
            conformerEntity.compound = compound
            conformerEntity.conformerId = conformer.conformerId
        
            for atom in conformer.atoms {
                let atomEntity = AtomEntity(context: dataController.viewContext)
                atomEntity.atomicNumber = Int16(atom.number)
                atomEntity.coordX = atom.location[0]
                atomEntity.coordY = atom.location[1]
                atomEntity.coordZ = atom.location[2]
                atomEntity.conformer = conformerEntity
            }
        }
    }
    
    func findConformers() -> [ConformerEntity]? {
        let sortDescription = NSSortDescriptor(key: "created", ascending: false)
        let predicate = NSPredicate(format: "compound == %@", argumentArray: [compound as Any])

        let fetchRequest: NSFetchRequest<ConformerEntity> = ConformerEntity.fetchRequest()
        fetchRequest.sortDescriptors = [sortDescription]
        fetchRequest.predicate = predicate
        
        return fetchObjects(fetchRequest: fetchRequest)
    }
    
    func findAtoms(for conformer: ConformerEntity) -> [AtomEntity]? {
        let sortDescription = NSSortDescriptor(key: "created", ascending: false)
        let predicate = NSPredicate(format: "conformer == %@", argumentArray: [conformer as Any])

        let fetchRequest: NSFetchRequest<AtomEntity> = AtomEntity.fetchRequest()
        fetchRequest.sortDescriptors = [sortDescription]
        fetchRequest.predicate = predicate

        return fetchObjects(fetchRequest: fetchRequest)
    }
    
    func fetchObjects<T>(fetchRequest: NSFetchRequest<T>) -> [T]? {
        let fc = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: nil)
         
        fc.delegate = self
         
        do {
            try fc.performFetch()
        } catch {
            NSLog("Objects \(T.self) cannot be fetched for the compound \(String(describing: self.compound)): \(error.localizedDescription)")
        }
        
        return fc.fetchedObjects
    }
    
    func populateConformer(for conformerEntity: ConformerEntity, with atomEntities: [AtomEntity]) {
        conformer = Conformer()
        conformer?.cid = compound.cid ?? ""
        conformer?.conformerId = conformerEntity.conformerId ?? ""
        
        conformer?.atoms = [Atom]()
        for atomEntity in atomEntities {
            let atom = Atom()
            atom.number = Int(atomEntity.atomicNumber)
            atom.location = [atomEntity.coordX, atomEntity.coordY, atomEntity.coordZ]
            
            conformer?.atoms.append(atom)
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
        let solution = fetchedResultsController.object(at: indexPath)
        let cell = tableView.dequeueReusableCell(withIdentifier: tableViewCellIdentifier)!
        cell.textLabel?.text = solution.name
        cell.detailTextLabel?.text = buildDetailTextLabel(with: solution)
        return cell
    }
    
    func buildDetailTextLabel(with solution: Solution) -> String? {
        var text: String?
        if let date = solution.created {
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            dateFormatter.timeStyle = .none
            dateFormatter.locale = Locale.current
            text = dateFormatter.string(from: date)
        }
        return text
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let solution = fetchedResultsController.object(at: indexPath)
        let detailViewController = setupDetailViewController(for: solution)
        navigationController?.pushViewController(detailViewController, animated: true)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func setupDetailViewController(for solution: Solution) -> SolutionDetailViewController {
        let detailViewController = storyboard?.instantiateViewController(withIdentifier: detailViewControllerIdentifier) as! SolutionDetailViewController
        detailViewController.solution = solution
        detailViewController.delegate = self
        return detailViewController
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
