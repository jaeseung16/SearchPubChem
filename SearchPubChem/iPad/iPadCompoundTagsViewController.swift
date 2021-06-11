//
//  iPadCompoundTagsViewController.swift
//  SearchPubChem
//
//  Created by Jae Seung Lee on 5/27/21.
//  Copyright © 2021 Jae Seung Lee. All rights reserved.
//

import UIKit
import CoreData

protocol iPadCompoundTagsViewControllerDelegate: AnyObject {
    func update(tag: CompoundTag?) -> Void
}

class iPadCompoundTagsViewController: UIViewController {

    private let collectionViewCellIdentifier = "iPadCmpoundTagCollectionViewCell"
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    
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
    
    weak var delegate: CompoundTagsViewControllerDelegate?
    var selectedTag: CompoundTag?
    var indexPathForSelectedTag: IndexPath?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        collectionView.register(UINib(nibName: "TagView", bundle: nil), forCellWithReuseIdentifier: collectionViewCellIdentifier)
        
        setUpFetchedResultsController()
        adjustFlowLayoutSize(size: view.frame.size)
        
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
    
    @IBAction func dismiss(_ sender: UIBarButtonItem) {
        delegate?.update(tag: selectedTag)
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func reset(_ sender: UIBarButtonItem) {
        if let indexPath = indexPathForSelectedTag {
            collectionView.deselectItem(at: indexPath, animated: true)
            
            if let cell = collectionView.cellForItem(at: indexPath) as? iPadCompoundTagCollectionViewCell {
                cell.containerView.backgroundColor = .white
            }
            
            selectedTag = nil
            indexPathForSelectedTag = nil
            delegate?.update(tag: selectedTag)
        }
    }

}

// MARK: - UICollectionViewDelegate, UICollectionViewDataSource
extension iPadCompoundTagsViewController: UICollectionViewDelegate, UICollectionViewDataSource {
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
        
        if let selectedTag = selectedTag, selectedTag == tag {
            cell.containerView.backgroundColor = .cyan
            collectionView.selectItem(at: indexPath, animated: false, scrollPosition: .top)
            indexPathForSelectedTag = indexPath
        }
        
        return cell
    }
        
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let cell = collectionView.cellForItem(at: indexPath) as? iPadCompoundTagCollectionViewCell {
            cell.containerView.backgroundColor = .cyan
            selectedTag = fetchedResultsController.object(at: indexPath)
            indexPathForSelectedTag = indexPath
            delegate?.update(tag: selectedTag)
        }
    }

    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        if let cell = collectionView.cellForItem(at: indexPath) as? iPadCompoundTagCollectionViewCell {
            cell.containerView.backgroundColor = .white
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
        if flowLayout != nil {
            flowLayout.invalidateLayout()
            adjustFlowLayoutSize(size: size)
        }
    }
    
    func adjustFlowLayoutSize(size: CGSize) {
        let space: CGFloat = 2.0
        let width = cellSize(size: size, space: space)
        let height = width
        
        flowLayout.minimumInteritemSpacing = space
        flowLayout.minimumLineSpacing = 2 * space
        flowLayout.sectionInset = UIEdgeInsets(top: space, left: space, bottom: space, right: space)
        flowLayout.itemSize = CGSize(width: width, height: height)
    }
    
    func cellSize(size: CGSize, space: CGFloat) -> CGFloat {
        let numberInRow = CGFloat(3.0)
        return ( size.width - 2 * numberInRow * space ) / numberInRow
    }
}

// MARK: - NSFetchedResultsControllerDelegate
extension iPadCompoundTagsViewController: NSFetchedResultsControllerDelegate {
        func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
            let set = IndexSet(integer: sectionIndex)
            
            switch type {
            case .insert:
                collectionView.insertSections(set)
            case .delete:
                collectionView.deleteSections(set)
            default:
                break
            }
        }
        
        func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
            switch type {
            case .insert:
                collectionView.insertItems(at: [newIndexPath!])
            case .delete:
                collectionView.deleteItems(at: [indexPath!])
            case .update:
                collectionView.reloadItems(at: [indexPath!])
            case .move:
                collectionView.deleteItems(at: [indexPath!])
                collectionView.insertItems(at: [newIndexPath!])
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
