//
//  Solution+CoreDataClass.swift
//  SearchPubChem
//
//  Created by Jae Seung Lee on 1/26/18.
//  Copyright © 2018 Jae Seung Lee. All rights reserved.
//
//

import Foundation
import CoreData


public class Solution: NSManagedObject {
    convenience init(name: String, compounds: [Compound], context: NSManagedObjectContext) {
        if let entity = NSEntityDescription.entity(forEntityName: "Solution", in: context) {
            self.init(entity: entity, insertInto: context)
            self.name = name
            self.compounds = NSSet(array: compounds)
            self.created = NSDate()
        } else {
            fatalError("Unable to find the entity name, \"Compound\".")
        }
    }
}
