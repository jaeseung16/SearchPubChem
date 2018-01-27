//
//  Compound+CoreDataClass.swift
//  SearchPubChem
//
//  Created by Jae Seung Lee on 1/26/18.
//  Copyright © 2018 Jae Seung Lee. All rights reserved.
//
//

import Foundation
import CoreData


public class Compound: NSManagedObject {
    convenience init(name: String, formula: String, molecularWeight: Double, CID: String, nameIUPAC: String, context: NSManagedObjectContext) {
        if let entity = NSEntityDescription.entity(forEntityName: "Compound", in: context) {
            self.init(entity: entity, insertInto: context)
            self.name = name
            self.formula = formula
            self.molecularWeight = molecularWeight
            self.cid = CID
            self.nameIUPAC = nameIUPAC
            self.created = NSDate()
        } else {
            fatalError("Unable to find the entity name, \"Compound\".")
        }
    }
}
