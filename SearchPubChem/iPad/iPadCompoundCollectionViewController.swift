//
//  iPadCompoundCollectionViewController.swift
//  SearchPubChem
//
//  Created by Jae Seung Lee on 7/19/20.
//  Copyright © 2020 Jae Seung Lee. All rights reserved.
//

import UIKit
import CoreData

class iPadCompoundCollectionViewController: UIViewController {
    // MARK: - Properties
    // Outlets
    @IBOutlet weak var compoundCollectionView: UICollectionView!
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    
    @IBOutlet weak var tagCollectionView: UICollectionView!
    @IBOutlet weak var tagCollectionViewFlowLayout: UICollectionViewFlowLayout!
    
    let collectionViewCellIdentifier = "iPadCompoundCollectionViewCell"
    let tagCollectionViewCellIdentifier = "tagCollectionViewCell"
    let detailViewControllerIdentifier = "iPadCompoundDetailViewController"

    var dataController: DataController!
    var fetchedResultsController: NSFetchedResultsController<Compound>!
    var tagFetchedResultsController: NSFetchedResultsController<CompoundTag>!
    
    var selectedTag: CompoundTag?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setUpFetchedResultsController()
        adjustFlowLayoutSize(size: view.frame.size)
        
        setUpTagFetchedResultsController()
        print("tagCollectionViewFlowLayout.itemSize = \(tagCollectionViewFlowLayout.itemSize)")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        compoundCollectionView.reloadData()
    }
    
    func setUpFetchedResultsController() {
        let fetchRequest: NSFetchRequest<Compound> = setupFetchRequest()
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: "firstCharacterInName", cacheName: "compounds")
        fetchedResultsController.delegate = self
        
        do {
            try fetchedResultsController.performFetch()
        } catch {
            fatalError("Compounds cannot be fetched: \(error.localizedDescription)")
        }
    }
    
    func setupFetchRequest() -> NSFetchRequest<Compound> {
        let fetchRequest: NSFetchRequest<Compound> = Compound.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "name", ascending: true, selector: #selector(NSString.caseInsensitiveCompare))
        
        fetchRequest.sortDescriptors = [sortDescriptor]
        return fetchRequest
    }
    
    func setUpTagFetchedResultsController() {
        let fetchRequest: NSFetchRequest<CompoundTag> = setupTagFetchRequest()
        
        tagFetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: "compoundTags")
        tagFetchedResultsController.delegate = self
        
        do {
            try tagFetchedResultsController.performFetch()
        } catch {
            fatalError("Compounds cannot be fetched: \(error.localizedDescription)")
        }
    }
    
    func setupTagFetchRequest() -> NSFetchRequest<CompoundTag> {
        let fetchRequest: NSFetchRequest<CompoundTag> = CompoundTag.fetchRequest()
        let countSortDescriptor = NSSortDescriptor(key: "compoundCount", ascending: false)
        let nameSortDescriptor = NSSortDescriptor(key: "name", ascending: true, selector: #selector(NSString.caseInsensitiveCompare))
        
        fetchRequest.sortDescriptors = [countSortDescriptor, nameSortDescriptor]
        return fetchRequest
    }
    
    // MARK: - Navigation
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let searchByNameViewController = segue.destination as? SearchByNameViewController {
            searchByNameViewController.dataController = dataController
        }
    }
    
}

// MARK: - UICollectionViewDelegate, UICollectionViewDataSource
extension iPadCompoundCollectionViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        if collectionView == compoundCollectionView {
            return fetchedResultsController.sections?.count ?? 0
        } else {
            return tagFetchedResultsController.sections?.count ?? 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == compoundCollectionView {
            return fetchedResultsController.sections?[section].numberOfObjects ?? 0
        } else {
            return tagFetchedResultsController.sections?[section].numberOfObjects ?? 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == compoundCollectionView {
            let compound = fetchedResultsController.object(at: indexPath)
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: collectionViewCellIdentifier, for: indexPath) as! iPadCompoundCollectionViewCell
            
            cell.compoundNameLabel.text = compound.name
            
            if let imageData = compound.image {
                cell.compoundImageView.image = UIImage(data: imageData as Data)
            }
            
            return cell
        } else {
            let tag = tagFetchedResultsController.object(at: indexPath)
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: tagCollectionViewCellIdentifier, for: indexPath) as! TagCollectionViewCell
            
            cell.nameLabel.text = tag.name
            cell.countLabel.text = "\(tag.compoundCount)"
            
            return cell
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        var shouldSelect = true
        
        if collectionView == tagCollectionView {
            let tag = tagFetchedResultsController.object(at: indexPath)
            
            if (selectedTag == tag) {
                
                selectedTag = nil
               
                if collectionView == tagCollectionView {
                    if let cell = collectionView.cellForItem(at: indexPath) as? TagCollectionViewCell {
                        cell.contentView.backgroundColor = .white
                    }
                }
                
                fetchedResultsController.delegate = nil
                
                setUpFetchedResultsController()
                
                compoundCollectionView.reloadData()
                
                shouldSelect = false
            } else {
                let tag = tagFetchedResultsController.object(at: indexPath)
                selectedTag = tag
                
                let sortDescriptor = NSSortDescriptor(key: "name", ascending: true, selector: #selector(NSString.caseInsensitiveCompare))
                let predicate = NSPredicate(format: "tags CONTAINS %@", argumentArray: [tag])
                
                let fetchRequest: NSFetchRequest<Compound> = Compound.fetchRequest()
                fetchRequest.sortDescriptors = [sortDescriptor]
                fetchRequest.predicate = predicate
                
                fetchedResultsController.delegate = nil
                
                fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: "firstCharacterInName", cacheName: nil)
                fetchedResultsController.delegate = self
                
                do {
                    try fetchedResultsController.performFetch()
                } catch {
                    fatalError("Compounds cannot be fetched: \(error.localizedDescription)")
                }
                
                compoundCollectionView.reloadData()
            }
        }
        return shouldSelect
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == compoundCollectionView {
            let compound = fetchedResultsController.object(at: indexPath)
            let detailViewController = setupDetailViewController(for: compound)
            detailViewController.delegate = self
            navigationController?.pushViewController(detailViewController, animated: true)
            collectionView.deselectItem(at: indexPath, animated: false)
        } else {
            if let cell = collectionView.cellForItem(at: indexPath) as? TagCollectionViewCell {
                cell.contentView.backgroundColor = .cyan
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        if collectionView == tagCollectionView {
            if let cell = collectionView.cellForItem(at: indexPath) as? TagCollectionViewCell {
                cell.contentView.backgroundColor = .white
            }
        }
    }
    
    /*
    func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        if collectionView == compoundCollectionView {
            let compound = fetchedResultsController.object(at: indexPath)
            
            guard let selected = selectedTag, let tags = compound.tags else {
                return false
            }
            
            if tags.contains(selected) {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: collectionViewCellIdentifier, for: indexPath) as! iPadCompoundCollectionViewCell
                cell.compoundNameLabel.backgroundColor = #colorLiteral(red: 1, green: 0.4932718873, blue: 0.4739984274, alpha: 1)
                
                return true
            } else {
                return false
            }
        } else {
            return true
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
        if collectionView == compoundCollectionView {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: collectionViewCellIdentifier, for: indexPath) as! iPadCompoundCollectionViewCell
            cell.contentView.backgroundColor = #colorLiteral(red: 1, green: 0.4932718873, blue: 0.4739984274, alpha: 1)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didUnhighlightItemAt indexPath: IndexPath) {
        if collectionView == compoundCollectionView {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: collectionViewCellIdentifier, for: indexPath) as! iPadCompoundCollectionViewCell
            cell.contentView.backgroundColor = nil
        }
    }
    */
    
    func setupDetailViewController(for compound: Compound) -> iPadCompoundDetailViewController {
        let fetchRequest = buildSolutionFetchRequest(for: compound)
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        let detailViewController = setupDetailViewController(with: fetchedResultsController)
        detailViewController.compound = compound
        return detailViewController
    }
    
    func buildSolutionFetchRequest(for compound: Compound) -> NSFetchRequest<Solution> {
        let sortDescription = NSSortDescriptor(key: "created", ascending: false)
        let predicate = NSPredicate(format: "compounds CONTAINS %@", argumentArray: [compound])
        
        let fetchRequest: NSFetchRequest<Solution> = Solution.fetchRequest()
        fetchRequest.sortDescriptors = [sortDescription]
        fetchRequest.predicate = predicate
        return fetchRequest
    }
    
    func setupDetailViewController(with fetchedResultsController: NSFetchedResultsController<Solution>) -> iPadCompoundDetailViewController {
        let detailViewController = storyboard?.instantiateViewController(withIdentifier: detailViewControllerIdentifier) as! iPadCompoundDetailViewController
        detailViewController.dataController = dataController
        detailViewController.fetchedResultsController = fetchedResultsController
        return detailViewController
    }
    
    // MARK: - Methods for FlowLayout
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        // Checking whether flowLayout exists before updating the collection view
        if flowLayout != nil {
            flowLayout.invalidateLayout()
            adjustFlowLayoutSize(size: size)
        }
    }
    
    func adjustFlowLayoutSize(size: CGSize) {
        let space: CGFloat = 1.0
        let width = cellSize(size: size, space: space)
        let height = width
        
        flowLayout.minimumInteritemSpacing = space
        flowLayout.minimumLineSpacing = 2 * space
        flowLayout.sectionInset = UIEdgeInsets(top: space, left: space, bottom: space, right: space)
        flowLayout.itemSize = CGSize(width: width, height: height)
    }
    
    func cellSize(size: CGSize, space: CGFloat) -> CGFloat {
        let numberInRowPortrait = 4.0
        let numberInRowLandscape = 6.0
        
        let numberInRow = size.height > size.width ? CGFloat(numberInRowPortrait) : CGFloat(numberInRowLandscape)
        
        return ( size.width - 2 * numberInRow * space ) / numberInRow
    }
}

// MARK: - NSFetchedResultsControllerDelegate
extension iPadCompoundCollectionViewController: NSFetchedResultsControllerDelegate {
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        let set = IndexSet(integer: sectionIndex)
        
        switch type {
        case .insert:
            if controller == fetchedResultsController {
                compoundCollectionView.insertSections(set)
            } else {
                tagCollectionView.insertSections(set)
            }
        case .delete:
            if controller == fetchedResultsController {
                compoundCollectionView.deleteSections(set)
            } else {
                tagCollectionView.deleteSections(set)
            }
        default:
            break
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            if controller == fetchedResultsController {
                compoundCollectionView.insertItems(at: [newIndexPath!])
            } else {
                tagCollectionView.insertItems(at: [newIndexPath!])
            }
        case .delete:
            if controller == fetchedResultsController {
                compoundCollectionView.deleteItems(at: [indexPath!])
            } else {
                tagCollectionView.deleteItems(at: [indexPath!])
            }
        case .update:
            if controller == fetchedResultsController {
                compoundCollectionView.reloadItems(at: [indexPath!])
            } else {
                tagCollectionView.reloadItems(at: [indexPath!])
            }
        case .move:
            if controller == fetchedResultsController {
                compoundCollectionView.deleteItems(at: [indexPath!])
                compoundCollectionView.insertItems(at: [newIndexPath!])
            } else {
                tagCollectionView.deleteItems(at: [indexPath!])
                tagCollectionView.insertItems(at: [newIndexPath!])
            }
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

// MARK: - iPadCompoundDetailViewControllerDelegate
extension iPadCompoundCollectionViewController: iPadCompoundDetailViewControllerDelegate {
    func remove(compound: Compound) {
        dataController.viewContext.delete(compound)
        do {
            try fetchedResultsController.performFetch()
        } catch {
            fatalError("Compounds cannot be fetched: \(error.localizedDescription)")
        }
    }
}
