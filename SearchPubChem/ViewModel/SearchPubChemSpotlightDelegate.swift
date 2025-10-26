//
//  SearchPubChemSpotlightDelegate.swift
//  SearchPubChem
//
//  Created by Jae Seung Lee on 6/19/23.
//  Copyright © 2023 Jae Seung Lee. All rights reserved.
//

import CoreData
import CoreSpotlight

class SearchPubChemSpotlightDelegate: NSCoreDataCoreSpotlightDelegate {
    override func domainIdentifier() -> String {
        return "com.resonance.jlee.SearchPubChem"
    }

    override func indexName() -> String? {
        return "searchpubchem-compound-index"
    }
      
    override func attributeSet(for object: NSManagedObject) -> CSSearchableItemAttributeSet? {
        guard let compound = object as? Compound else {
            return nil
        }

        let attributeSet = CSSearchableItemAttributeSet(contentType: .text)
        let name = compound.name
        attributeSet.title = name
        //attributeSet.thumbnailData = compound.image
        attributeSet.contentDescription = "\(name ?? "") \(compound.formula ?? "")"
        return attributeSet
    }

}
