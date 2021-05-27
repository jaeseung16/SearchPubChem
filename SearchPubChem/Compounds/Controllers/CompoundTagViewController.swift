//
//  CompoundTagViewController.swift
//  SearchPubChem
//
//  Created by Jae Seung Lee on 5/25/21.
//  Copyright © 2021 Jae Seung Lee. All rights reserved.
//

import UIKit
import CoreData

protocol CompoundTagViewControllerDelegate: AnyObject {
    func updateTags() -> Void
}

class CompoundTagViewController: UIViewController {

    let collectionViewCellIdentifier = "compoundTagCollectionViewCell"
    
    @IBOutlet weak var compoundTagCollectionView: UICollectionView!
    @IBOutlet weak var compoundTagFlowLayout: UICollectionViewFlowLayout!
    
    @IBOutlet weak var tagsLabel: UILabel!
    
    @IBOutlet weak var addTagButton: UIButton!
    @IBOutlet weak var newTagTextField: UITextField!
    
    var compound: Compound!
    var tagsAttachedToCompound = Set<CompoundTag>()
    var sellectedCells = Set<IndexPath>()
    
    var dataController: DataController!
    var fetchedResultsController: NSFetchedResultsController<CompoundTag>! {
        didSet {
            fetchedResultsController.delegate = self
            
            do {
                try fetchedResultsController.performFetch()
            } catch {
                NSLog("Solutions cannot be fetched for the compound: \(error.localizedDescription)")
            }
        }
    }
    
    weak var delegate: CompoundTagViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        compoundTagCollectionView.register(UINib(nibName: "TagView", bundle: nil), forCellWithReuseIdentifier: collectionViewCellIdentifier)
        
        setUpFetchedResultsController()
        adjustFlowLayoutSize(size: view.frame.size)
        
        populateTagsAttachedToCompound()
        setTagsLabel()
    }
    
    func setUpFetchedResultsController() {
        let fetchRequest: NSFetchRequest<CompoundTag> = setupFetchRequest()
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: "compoundTags")
        fetchedResultsController.delegate = self
        
        do {
            try fetchedResultsController.performFetch()
        } catch {
            fatalError("Compounds cannot be fetched: \(error.localizedDescription)")
        }
    }
    
    func setupFetchRequest() -> NSFetchRequest<CompoundTag> {
        let fetchRequest: NSFetchRequest<CompoundTag> = CompoundTag.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "name", ascending: true, selector: #selector(NSString.caseInsensitiveCompare))
        
        fetchRequest.sortDescriptors = [sortDescriptor]
        return fetchRequest
    }
    
    func populateTagsAttachedToCompound() {
        if let tags = compound.tags {
            for tag in tags {
                if let tag = tag as? CompoundTag {
                    tagsAttachedToCompound.insert(tag)
                }
            }
        }
    }
    
    func setTagsLabel() {
        var tagsString = [String]()
        
        for tag in tagsAttachedToCompound {
            if let name = tag.name {
                tagsString.append(name)
            }
        }
    
        tagsLabel.text = tagsString.joined(separator: ",")
    }
    
    
    @IBAction func dismiss(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func addTag(_ sender: UIButton) {
        if let newTagName = newTagTextField.text, !newTagName.isEmpty {
            let newTag = CompoundTag(context: dataController.viewContext)
            newTag.compoundCount = 1
            newTag.name = newTagTextField.text
            
            if let tags = compound.tags, tags.count > 0 {
                tags.adding(newTag)
            } else {
                compound.tags = NSSet(arrayLiteral: newTag)
            }
            
            do {
                try dataController.viewContext.save()
            } catch {
                NSLog("Error while saving in iPadCompoundTagViewController.addNewTag(:)")
            }
            
            tagsAttachedToCompound.insert(newTag)
            setTagsLabel()
        } else {
            print("New tag is not given")
        }
    }
    
    @IBAction func deleteTag(_ sender: UIButton) {
        for indexPath in sellectedCells {
            let tag = fetchedResultsController.object(at: indexPath)
            dataController.viewContext.delete(tag)
        }
        
        do {
            try dataController.viewContext.save()
            NSLog("Saved in iPadCompoundTagViewController.deleteTags(:)")
        } catch {
            NSLog("Error while saving in iPadCompoundTagViewController.deleteTags(:)")
        }
    }
    
    @IBAction func updateTags(_ sender: UIBarButtonItem) {
        if let tags = compound.tags {
            for tag in tags {
                if let compoundTag = tag as? CompoundTag {
                    compoundTag.compoundCount -= 1
                }
            }
        }
        
        for tag in tagsAttachedToCompound {
            tag.compoundCount += 1
        }
        
        compound.tags = NSSet(set: tagsAttachedToCompound)
        
        delegate?.updateTags()
        
        do {
            try dataController.viewContext.save()
        } catch {
            NSLog("Error while saving in iPadCompoundTagViewController.addNewTag(:)")
        }
        
        dismiss(animated: true, completion: nil)
    }
    
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

// MARK: - UICollectionViewDelegate, UICollectionViewDataSource
extension CompoundTagViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return fetchedResultsController.sections?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return fetchedResultsController.sections?[section].numberOfObjects ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let tag = fetchedResultsController.object(at: indexPath)
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: collectionViewCellIdentifier, for: indexPath) as! iPadCompoundTagCollectionViewCell
        
        cell.nameLabel.text = tag.name
        cell.countLabel.text = "\(tag.compoundCount)"
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        let tag = fetchedResultsController.object(at: indexPath)
        
        var selected = false
        
        if tagsAttachedToCompound.contains(tag) {
            tagsAttachedToCompound.remove(tag)
        } else {
            tagsAttachedToCompound.insert(tag)
            selected = true
        }

        setTagsLabel()
        
        return selected
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let cell = collectionView.cellForItem(at: indexPath) as? iPadCompoundTagCollectionViewCell {
            cell.containerView.backgroundColor = .cyan
            sellectedCells.insert(indexPath)
        }
    }

    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        if let cell = collectionView.cellForItem(at: indexPath) as? iPadCompoundTagCollectionViewCell {
            cell.containerView.backgroundColor = .white
            sellectedCells.remove(indexPath)
        }
    }
    
    func buildSolutionFetchRequest(for compound: Compound) -> NSFetchRequest<Solution> {
        let sortDescription = NSSortDescriptor(key: "created", ascending: false)
        let predicate = NSPredicate(format: "compounds CONTAINS %@", argumentArray: [compound])
        
        let fetchRequest: NSFetchRequest<Solution> = Solution.fetchRequest()
        fetchRequest.sortDescriptors = [sortDescription]
        fetchRequest.predicate = predicate
        return fetchRequest
    }
    
    // MARK: - Methods for FlowLayout
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        // Checking whether flowLayout exists before updating the collection view
        if compoundTagFlowLayout != nil {
            compoundTagFlowLayout.invalidateLayout()
            adjustFlowLayoutSize(size: size)
        }
    }
    
    func adjustFlowLayoutSize(size: CGSize) {
        let space: CGFloat = 2.0
        let width = cellSize(size: size, space: space)
        let height = width
        
        compoundTagFlowLayout.minimumInteritemSpacing = space
        compoundTagFlowLayout.minimumLineSpacing = 2 * space
        compoundTagFlowLayout.sectionInset = UIEdgeInsets(top: space, left: space, bottom: space, right: space)
        compoundTagFlowLayout.itemSize = CGSize(width: width, height: height)
    }
    
    func cellSize(size: CGSize, space: CGFloat) -> CGFloat {
        let numberInRow = CGFloat(3.0)
        return ( size.width - 2 * numberInRow * space ) / numberInRow
    }
}

// MARK: - NSFetchedResultsControllerDelegate
extension CompoundTagViewController: NSFetchedResultsControllerDelegate {
        func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
            let set = IndexSet(integer: sectionIndex)
            
            switch type {
            case .insert:
                compoundTagCollectionView.insertSections(set)
            case .delete:
                compoundTagCollectionView.deleteSections(set)
            default:
                break
            }
        }
        
        func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
            switch type {
            case .insert:
                compoundTagCollectionView.insertItems(at: [newIndexPath!])
            case .delete:
                compoundTagCollectionView.deleteItems(at: [indexPath!])
            case .update:
                compoundTagCollectionView.reloadItems(at: [indexPath!])
            case .move:
                compoundTagCollectionView.deleteItems(at: [indexPath!])
                compoundTagCollectionView.insertItems(at: [newIndexPath!])
            @unknown default:
                fatalError()
            }
        }
        
        func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
            do {
                try dataController.viewContext.save()
                NSLog("Saved in controllerDidChangeContent(_:)")
            } catch {
                NSLog("Error while saving in controllerDidChangeContent(_:)")
            }
        }
    
}
