//
//  CompoundCollectionViewController.swift
//  SearchPubChem
//
//  Created by Jae Seung Lee on 2/4/18.
//  Copyright © 2018 Jae Seung Lee. All rights reserved.
//

import UIKit
import CoreData

protocol CompoundCollectionViewDelegate: AnyObject {
    func selectedCompounds(_ compounds: [Compound], with title: String)
}

class CompoundCollectionViewController: UIViewController {
    // MARK: - Properties
    // Outlets
    @IBOutlet weak var compoundCollectionView: UICollectionView!
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    @IBOutlet weak var selectedCompoundsLabel: UILabel!
    
    // Constants
    let collectionViewCellIdentifier = "CompoundCollectionViewCell"
    
    // Variables
    weak var delegate: CompoundCollectionViewDelegate?
    
    var maxNumberOfCompounds: Int?
    var compounds = [Compound]()
    
    var dataController: DataController!
    var fetchedResultsController: NSFetchedResultsController<Compound>! {
        didSet {
            fetchedResultsController.delegate = self
            
            do {
                try fetchedResultsController.performFetch()
            } catch {
                NSLog("Compounds cannot be fetched for CompoundCollectionViewController: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setSelectedCompoundsLabel()
        adjustFlowLayoutSize(size: self.view.frame.size)
    }
    
    // Actions
    @IBAction func selectionFinished(_ sender: UIButton) {
        if let title = selectedCompoundsLabel.text {
            delegate?.selectedCompounds(compounds, with: title)
        } else {
            delegate?.selectedCompounds(compounds, with: "")
        }
        
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func dismiss(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    func setSelectedCompoundsLabel() {
        var cids = [String]()
        for compound in compounds {
            cids.append(compound.name!)
        }
        selectedCompoundsLabel.text = cids.joined(separator: "/")
    }
}

// MARK: - UICollectionViewDelegate, UICollectionViewDataSource
extension CompoundCollectionViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return fetchedResultsController.sections?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return fetchedResultsController.sections?[section].numberOfObjects ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let compound = fetchedResultsController.object(at: indexPath)
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: collectionViewCellIdentifier, for: indexPath) as! CompoundCollectionViewCell
        
        cell.compoundName.text = compound.name
        
        if let imageData = compound.image {
            cell.compoundImageView.image = UIImage(data: imageData as Data)
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        let compound = fetchedResultsController.object(at: indexPath)
        
        if let index = compounds.index(of: compound){
            compounds.remove(at: index)
            setSelectedCompoundsLabel()
            return false
        } else {
            compounds.append(compound)
            setSelectedCompoundsLabel()
            return true
        }
    }
    
    // MARK: - Methods for FlowLayout
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        // Checking whether flowLayout exists before updating the collection view
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
        let numberInRowPortrait = 3.0
        let numberInRowLandscape = 5.0
        
        let numberInRow = size.height > size.width ? CGFloat(numberInRowPortrait) : CGFloat(numberInRowLandscape)
        
        return ( size.width - 2 * numberInRow * space ) / numberInRow
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
        do {
            try dataController.viewContext.save()
            NSLog("Saved in controllerDidChangeContent(_:)")
        } catch {
            NSLog("Error while saving in controllerDidChangeContent(_:)")
        }
    }
}

