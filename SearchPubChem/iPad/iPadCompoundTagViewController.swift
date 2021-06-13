//
//  iPadCompoundTagViewController.swift
//  SearchPubChem
//
//  Created by Jae Seung Lee on 5/11/21.
//  Copyright © 2021 Jae Seung Lee. All rights reserved.
//

import UIKit
import CoreData

protocol iPadCompoundTagViewControllerDelegate: AnyObject {
    func updateTags() -> Void
}

class iPadCompoundTagViewController: UIViewController {
    
    private let collectionViewCellIdentifier = "iPadCompoundTagCollectionViewCell"

    @IBOutlet weak var allTagsCollectionView: UICollectionView!
    @IBOutlet weak var allTagsFlowLayout: UICollectionViewFlowLayout!
    
    @IBOutlet weak var addTagButton: UIButton!
    @IBOutlet weak var newTagTextField: UITextField!
    
    @IBOutlet weak var tagsAttachedLabel: UILabel!
    @IBOutlet weak var tagsLabel: UILabel!
    
    var compound: Compound!
    private var tagsAttachedToCompound = Set<CompoundTag>()
    private var sellectedCells = Set<IndexPath>()
    private var lastSelectedCell: IndexPath?
    
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
    
    weak var delegate: iPadCompoundTagViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        allTagsCollectionView.register(UINib(nibName: "TagView", bundle: nil), forCellWithReuseIdentifier: collectionViewCellIdentifier)
        
        setUpFetchedResultsController()
        adjustFlowLayoutSize(size: view.frame.size)
        
        tagsAttachedLabel.text = "Tags attached to \(compound.name!)"
        populateTagsAttachedToCompound()
        setTagsLabel()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        allTagsCollectionView.reloadData()
    }
    
    private func setUpFetchedResultsController() {
        let fetchRequest: NSFetchRequest<CompoundTag> = setupFetchRequest()
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: "compoundTags")
        fetchedResultsController.delegate = self
        
        do {
            try fetchedResultsController.performFetch()
        } catch {
            fatalError("Compounds cannot be fetched: \(error.localizedDescription)")
        }
    }
    
    private func setupFetchRequest() -> NSFetchRequest<CompoundTag> {
        let fetchRequest: NSFetchRequest<CompoundTag> = CompoundTag.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "name", ascending: true, selector: #selector(NSString.caseInsensitiveCompare))
        
        fetchRequest.sortDescriptors = [sortDescriptor]
        return fetchRequest
    }
    
    private func populateTagsAttachedToCompound() {
        if let tags = compound.tags {
            for tag in tags {
                if let tag = tag as? CompoundTag {
                    tagsAttachedToCompound.insert(tag)
                }
            }
        }
    }
    
    private func setTagsLabel() {
        var tagsString = [String]()
        
        if tagsAttachedToCompound.isEmpty {
            tagsLabel.text = "No tags"
            if #available(iOS 13.0, *) {
                tagsLabel.textColor = .secondaryLabel
            } else {
                // Fallback on earlier versions
                tagsLabel.textColor = .gray
            }
        } else {
            for tag in tagsAttachedToCompound {
                if let name = tag.name {
                    tagsString.append(name)
                }
            }
        
            tagsLabel.text = tagsString.joined(separator: ",")
            if #available(iOS 13.0, *) {
                tagsLabel.textColor = .label
            } else {
                // Fallback on earlier versions
                tagsLabel.textColor = traitCollection.userInterfaceStyle == .dark ? .white : .black
            }
        }
    }
    
    @IBAction func dismiss(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func addNewTag(_ sender: UIButton) {
        if let newTagName = newTagTextField.text, !newTagName.isEmpty {
            let newTag = CompoundTag(context: dataController.viewContext)
            newTag.compoundCount = 1
            newTag.name = newTagTextField.text
            
            // Add to tagsAttachedToCompound before saving the new tag
            // So the collection view correctly presents the new tag as selected
            tagsAttachedToCompound.insert(newTag)
            setTagsLabel()
            
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
        } else {
            print("New tag is not given")
        }
    }
    
    @IBAction func deleteTags(_ sender: UIButton) {
        if let indexPath = lastSelectedCell {
            let tag = fetchedResultsController.object(at: indexPath)
            dataController.viewContext.delete(tag)
            
            do {
                try dataController.viewContext.save()
                NSLog("Saved in iPadCompoundTagViewController.deleteTags(:)")
            } catch {
                NSLog("Error while saving in iPadCompoundTagViewController.deleteTags(:)")
            }
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
}

// MARK: - UICollectionViewDelegate, UICollectionViewDataSource
extension iPadCompoundTagViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return fetchedResultsController.sections?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return fetchedResultsController.sections?[section].numberOfObjects ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let tag = fetchedResultsController.object(at: indexPath)
        if tagsAttachedToCompound.contains(tag) && !sellectedCells.contains(indexPath) {
            sellectedCells.insert(indexPath)
        }
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: collectionViewCellIdentifier, for: indexPath) as! iPadCompoundTagCollectionViewCell
        
        cell.nameLabel.text = tag.name
        cell.nameLabel.textColor = .black
        cell.countLabel.text = "\(tag.compoundCount)"
        cell.countLabel.textColor = .black
        cell.containerView.backgroundColor = tagsAttachedToCompound.contains(tag) ? .cyan : .white
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        let tag = fetchedResultsController.object(at: indexPath)
        
        if tagsAttachedToCompound.contains(tag) {
            tagsAttachedToCompound.remove(tag)
            sellectedCells.remove(indexPath)
        } else {
            tagsAttachedToCompound.insert(tag)
            sellectedCells.insert(indexPath)
        }

        setTagsLabel()
        
        lastSelectedCell = lastSelectedCell == indexPath ? nil : indexPath
        
        return true
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let cell = collectionView.cellForItem(at: indexPath) as? iPadCompoundTagCollectionViewCell {
            cell.containerView.backgroundColor = sellectedCells.contains(indexPath) ? .cyan : .white
            
            if lastSelectedCell == indexPath {
                cell.containerView.backgroundColor = .red
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        if let cell = collectionView.cellForItem(at: indexPath) as? iPadCompoundTagCollectionViewCell {
            cell.containerView.backgroundColor = sellectedCells.contains(indexPath) ? .cyan : .white
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
        if allTagsFlowLayout != nil {
            allTagsFlowLayout.invalidateLayout()
            adjustFlowLayoutSize(size: size)
        }
    }
    
    func adjustFlowLayoutSize(size: CGSize) {
        let space: CGFloat = 2.0
        let width = cellSize(size: size, space: space)
        let height = width
        
        allTagsFlowLayout.minimumInteritemSpacing = space
        allTagsFlowLayout.minimumLineSpacing = 2 * space
        allTagsFlowLayout.sectionInset = UIEdgeInsets(top: space, left: space, bottom: space, right: space)
        allTagsFlowLayout.itemSize = CGSize(width: width, height: height)
    }
    
    func cellSize(size: CGSize, space: CGFloat) -> CGFloat {
        let numberInRow = CGFloat(3.0)
        return ( size.width - 2 * numberInRow * space ) / numberInRow
    }
}


// MARK: - NSFetchedResultsControllerDelegate
extension iPadCompoundTagViewController: NSFetchedResultsControllerDelegate {
        func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
            let set = IndexSet(integer: sectionIndex)
            
            switch type {
            case .insert:
                allTagsCollectionView.insertSections(set)
            case .delete:
                allTagsCollectionView.deleteSections(set)
            default:
                break
            }
        }
        
        func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
            switch type {
            case .insert:
                allTagsCollectionView.insertItems(at: [newIndexPath!])
            case .delete:
                allTagsCollectionView.deleteItems(at: [indexPath!])
            case .update:
                allTagsCollectionView.reloadItems(at: [indexPath!])
            case .move:
                allTagsCollectionView.deleteItems(at: [indexPath!])
                allTagsCollectionView.insertItems(at: [newIndexPath!])
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
