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
    func selectedCompounds(with compounds: [Compound])
}

class CompoundCollectionViewController: UIViewController {

    @IBOutlet weak var compoundCollectionView: UICollectionView!
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    @IBOutlet weak var selectedCompoundsLabel: UILabel!
    
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
                print("Compounds cannot be fetched for CompoundCollectionViewController: \(error.localizedDescription)")
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        var cids = [String]()
        
        for compound in compounds {
            cids.append(compound.name!)
        }
        
        selectedCompoundsLabel.text = cids.joined(separator: "/")
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
    
    @IBAction func selectionFinished(_ sender: UIButton) {
        delegate?.selectedCompounds(with: compounds)
        dismiss(animated: true, completion: nil)
    }
    
    
    @IBAction func dismiss(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
}

// MARK: UICollectionViewDataSource
extension CompoundCollectionViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return fetchedResultsController.sections?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return fetchedResultsController.sections?[section].numberOfObjects ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! CompoundCollectionViewCell
        
        // Set the properties of 'cell' to default values
        cell.compoundImageView.image = nil
        cell.compoundImageView.backgroundColor = .black
        //cell.activityIndicator.startAnimating()
        cell.compoundName.text = ""

        let compound = fetchedResultsController.object(at: indexPath)
        
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
            
            var cids = [String]()
            for compound in compounds {
                cids.append(compound.name!)
            }
            selectedCompoundsLabel.text = cids.joined(separator: "/")
            return false
        } else {
            compounds.append(compound)
            
            var cids = [String]()
            for compound in compounds {
                cids.append(compound.name!)
            }
            selectedCompoundsLabel.text = cids.joined(separator: "/")
            return true
        }
        
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
            print("Saved in controllerDidChangeContent(_:)")
        } catch {
            print("Error while saving in controllerDidChangeContent(_:)")
        }
    }
}

