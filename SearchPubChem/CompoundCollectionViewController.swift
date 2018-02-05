//
//  CompoundCollectionViewController.swift
//  SearchPubChem
//
//  Created by Jae Seung Lee on 2/4/18.
//  Copyright © 2018 Jae Seung Lee. All rights reserved.
//

import UIKit
import CoreData

private let reuseIdentifier = "CompoundCollectionViewCell"

protocol CompoundCollectionViewDelegate: AnyObject {
    func selectedCompounds(with cids: [String])
}

class CompoundCollectionViewController: UIViewController {

    @IBOutlet weak var compoundCollectionView: UICollectionView!
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    
    weak var delegate: CompoundCollectionViewDelegate?
    var maxNumberOfCompounds: Int?
    var cids = [String]()
    
    var fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult>? {
        didSet {
            fetchedResultsController?.delegate = self
            
            if let fc = fetchedResultsController {
                do {
                    try fc.performFetch()
                } catch {
                    print("Error while trying to perform a search: \n\(error)\n\(String(describing: fetchedResultsController))")
                }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        adjustFlowLayoutSize(size: self.view.frame.size)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */

    // MARK: UICollectionViewDataSource


    @IBAction func dismiss(_ sender: UIBarButtonItem) {
        delegate?.selectedCompounds(with: cids)
    
        dismiss(animated: true, completion: nil)
    }
    
}

extension CompoundCollectionViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let fc = fetchedResultsController {
            return fc.sections![section].numberOfObjects
        } else {
            return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! CompoundCollectionViewCell
        
        // Set the properties of 'cell' to default values
        cell.compoundImageView.image = nil
        cell.compoundImageView.backgroundColor = .black
        //cell.activityIndicator.startAnimating()
        cell.compoundName.text = ""
        
        // If there is an item in 'fetchedResultsController', present it.
        if let fc = fetchedResultsController {
            let compound = fc.object(at: indexPath) as! Compound
            
            cell.compoundName.text = compound.name
            
            if let imageData = compound.image {
                cell.compoundImageView.image = UIImage(data: imageData as Data)
            }
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        if let fc = fetchedResultsController {
            let compound = fc.object(at: indexPath) as! Compound
            let cid = compound.cid!
            
            if let index = cids.index(of: cid){
                cids.remove(at: index)
                print("selected: \(cids)")
                return false
            } else {
                cids.append(cid)
                print("selected: \(cids)")
                return true
            }
        }
        
        return false
    }
    
    // MARK: Methods for FlowLayout
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        // This method is called when the orientaition of a device changes even before the view controller is loaded.
        // So checking whether flowLayout exists before updating the collection view
        if self.flowLayout != nil {
            self.flowLayout.invalidateLayout()
            adjustFlowLayoutSize(size: size)
        }
    }
    
    func adjustFlowLayoutSize(size: CGSize) {
        let space: CGFloat = 1.0
        let width = cellSize(size: size, space: space)
        let height = width
        
        self.flowLayout.minimumInteritemSpacing = space
        self.flowLayout.minimumLineSpacing = 2 * space
        self.flowLayout.sectionInset = UIEdgeInsets(top: space, left: space, bottom: space, right: space)
        self.flowLayout.itemSize = CGSize(width: width, height: height)
    }
    
    func cellSize(size: CGSize, space: CGFloat) -> CGFloat {
        let height = size.height
        let width = size.width
        
        let numberInRowPortrait = 3.0
        let numberInRowLandscape = 5.0
        
        let numberInRow = height > width ? CGFloat(numberInRowPortrait) : CGFloat(numberInRowLandscape)
        
        return ( width - 2 * numberInRow * space ) / numberInRow
    }
}

extension CompoundCollectionViewController {
    func save(context: NSManagedObjectContext) -> Bool {
        if context.hasChanges {
            do {
                try context.save()
                return true
            } catch {
                return false
            }
        } else {
            print("Context has not changed.")
            return false
        }
    }
}

// MARK: - NSFetchedResultsControllerDelegate
extension CompoundCollectionViewController: NSFetchedResultsControllerDelegate {
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
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        if let context = fetchedResultsController?.managedObjectContext {
            if save(context: context) {
                print("Saved in controllerDidChangeContent(_:)")
            } else {
                print("Error while saving in controllerDidChangeContent(_:)")
            }
        }
    }
}

