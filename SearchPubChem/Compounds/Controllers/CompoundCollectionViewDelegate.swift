//
//  CompoundCollectionViewDelegate.swift
//  SearchPubChem
//
//  Created by Jae Seung Lee on 10/12/21.
//  Copyright © 2021 Jae Seung Lee. All rights reserved.
//

import Foundation

protocol CompoundCollectionViewDelegate: AnyObject {
    func selectedCompounds(_ compounds: [Compound], with title: String)
}
