//
//  Solution+CoreDataProperties.swift
//  SearchPubChem
//
//  Created by Jae Seung Lee on 1/26/18.
//  Copyright © 2018 Jae Seung Lee. All rights reserved.
//
//

import Foundation
import CoreData


extension Solution {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Solution> {
        return NSFetchRequest<Solution>(entityName: "Solution")
    }

    @NSManaged public var created: NSDate?
    @NSManaged public var name: String?
    @NSManaged public var amount: NSObject?
    @NSManaged public var compounds: NSSet?

}

// MARK: Generated accessors for compounds
extension Solution {

    @objc(addCompoundsObject:)
    @NSManaged public func addToCompounds(_ value: Compound)

    @objc(removeCompoundsObject:)
    @NSManaged public func removeFromCompounds(_ value: Compound)

    @objc(addCompounds:)
    @NSManaged public func addToCompounds(_ values: NSSet)

    @objc(removeCompounds:)
    @NSManaged public func removeFromCompounds(_ values: NSSet)

}
