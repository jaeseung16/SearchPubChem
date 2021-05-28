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
    
    let collectionViewCellIdentifier = "iPadCompoundCollectionViewCell"
    let detailViewControllerIdentifier = "iPadCompoundDetailViewController"

    var dataController: DataController!
    var fetchedResultsController: NSFetchedResultsController<Compound>!
    
    var selectedTag: CompoundTag?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setUpFetchedResultsController()
        adjustFlowLayoutSize(size: view.frame.size)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        compoundCollectionView.reloadData()
    }
    
    func setUpFetchedResultsController() {
        let fetchRequest: NSFetchRequest<Compound> = setupFetchRequest()
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: "firstCharacterInName", cacheName: selectedTag == nil ? "compounds" : nil)
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
        
        if let tag = selectedTag {
            let predicate = NSPredicate(format: "tags CONTAINS %@", argumentArray: [tag])
            fetchRequest.predicate = predicate
        }
        
        return fetchRequest
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
        } else if let compoundTagsViewContoller = segue.destination as? iPadCompoundTagsViewController {
            compoundTagsViewContoller.dataController = dataController
            compoundTagsViewContoller.delegate = self
            compoundTagsViewContoller.selectedTag = selectedTag
        }
    }
    
}

// MARK: - UICollectionViewDelegate, UICollectionViewDataSource
extension iPadCompoundCollectionViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return fetchedResultsController.sections?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return fetchedResultsController.sections?[section].numberOfObjects ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let compound = fetchedResultsController.object(at: indexPath)
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: collectionViewCellIdentifier, for: indexPath) as! iPadCompoundCollectionViewCell
        
        cell.compoundNameLabel.text = compound.name
        
        if let imageData = compound.image {
            cell.compoundImageView.image = UIImage(data: imageData as Data)
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == compoundCollectionView {
            let compound = fetchedResultsController.object(at: indexPath)
            let detailViewController = setupDetailViewController(for: compound)
            detailViewController.delegate = self
            navigationController?.pushViewController(detailViewController, animated: true)
            collectionView.deselectItem(at: indexPath, animated: false)
        } else {
            if let cell = collectionView.cellForItem(at: indexPath) as? iPadCompoundTagCollectionViewCell {
                cell.containerView.backgroundColor = .cyan
            }
        }
    }
    
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
            compoundCollectionView.insertSections(set)
        case .delete:
            compoundCollectionView.deleteSections(set)
        default:
            break
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            compoundCollectionView.insertItems(at: [newIndexPath!])
        case .delete:
            compoundCollectionView.deleteItems(at: [indexPath!])
        case .update:
            compoundCollectionView.reloadItems(at: [indexPath!])
        case .move:
            compoundCollectionView.deleteItems(at: [indexPath!])
            compoundCollectionView.insertItems(at: [newIndexPath!])
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

extension iPadCompoundCollectionViewController: CompoundTagsViewControllerDelegate {
    func update(tag: CompoundTag?) -> Void {
        selectedTag = tag
        fetchedResultsController.delegate = nil
        setUpFetchedResultsController()
        compoundCollectionView.reloadData()
    }
}
