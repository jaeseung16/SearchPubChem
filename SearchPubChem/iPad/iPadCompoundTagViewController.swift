//
//  iPadCompoundTagViewController.swift
//  SearchPubChem
//
//  Created by Jae Seung Lee on 5/11/21.
//  Copyright © 2021 Jae Seung Lee. All rights reserved.
//

import UIKit
import CoreData

class iPadCompoundTagViewController: UIViewController {
    
    let collectionViewCellIdentifier = "iPadCompoundTagCollectionViewCell"

    @IBOutlet weak var allTagsCollectionView: UICollectionView!
    @IBOutlet weak var allTagsFlowLayout: UICollectionViewFlowLayout!
    
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
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

    
    @IBAction func dismiss(_ sender: UIBarButtonItem) {
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
        //let compound = fetchedResultsController.object(at: indexPath)
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: collectionViewCellIdentifier, for: indexPath) as! iPadCompoundCollectionViewCell
        
        /*
        cell.compoundNameLabel.text = compound.name
        
        if let imageData = compound.image {
            cell.compoundImageView.image = UIImage(data: imageData as Data)
        }
         */
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        /*
        let compound = fetchedResultsController.object(at: indexPath)
        let detailViewController = setupDetailViewController(for: compound)
        detailViewController.delegate = self
        navigationController?.pushViewController(detailViewController, animated: true)
        collectionView.deselectItem(at: indexPath, animated: false)
        */
    }
    
    /*
    func setupDetailViewController(for compound: Compound) -> iPadCompoundDetailViewController {
        let fetchRequest = buildSolutionFetchRequest(for: compound)
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        //let detailViewController = setupDetailViewController(with: fetchedResultsController)
        //detailViewController.compound = compound
        return detailViewController
    }
    */
    
    func buildSolutionFetchRequest(for compound: Compound) -> NSFetchRequest<Solution> {
        let sortDescription = NSSortDescriptor(key: "created", ascending: false)
        let predicate = NSPredicate(format: "compounds CONTAINS %@", argumentArray: [compound])
        
        let fetchRequest: NSFetchRequest<Solution> = Solution.fetchRequest()
        fetchRequest.sortDescriptors = [sortDescription]
        fetchRequest.predicate = predicate
        return fetchRequest
    }
    
    /*
    func setupDetailViewController(with fetchedResultsController: NSFetchedResultsController<Solution>) -> iPadCompoundDetailViewController {
        let detailViewController = storyboard?.instantiateViewController(withIdentifier: detailViewControllerIdentifier) as! iPadCompoundDetailViewController
        detailViewController.dataController = dataController
        detailViewController.fetchedResultsController = fetchedResultsController
        return detailViewController
    }
   */
    
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
        let space: CGFloat = 1.0
        let width = cellSize(size: size, space: space)
        let height = width
        
        allTagsFlowLayout.minimumInteritemSpacing = space
        allTagsFlowLayout.minimumLineSpacing = 2 * space
        allTagsFlowLayout.sectionInset = UIEdgeInsets(top: space, left: space, bottom: space, right: space)
        allTagsFlowLayout.itemSize = CGSize(width: width, height: height)
    }
    
    func cellSize(size: CGSize, space: CGFloat) -> CGFloat {
        let numberInRowPortrait = 4.0
        let numberInRowLandscape = 6.0
        
        let numberInRow = size.height > size.width ? CGFloat(numberInRowPortrait) : CGFloat(numberInRowLandscape)
        
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
