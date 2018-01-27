//
//  Compound+CoreDataProperties.swift
//  SearchPubChem
//
//  Created by Jae Seung Lee on 1/26/18.
//  Copyright © 2018 Jae Seung Lee. All rights reserved.
//
//

import Foundation
import CoreData


extension Compound {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Compound> {
        return NSFetchRequest<Compound>(entityName: "Compound")
    }

    @NSManaged public var cid: String?
    @NSManaged public var created: NSDate?
    @NSManaged public var formula: String?
    @NSManaged public var image: NSData?
    @NSManaged public var molecularWeight: Double
    @NSManaged public var name: String?
    @NSManaged public var nameIUPAC: String?
    @NSManaged public var partitionCoefficient: Double
    @NSManaged public var solutions: NSSet?

}

// MARK: Generated accessors for solutions
extension Compound {

    @objc(addSolutionsObject:)
    @NSManaged public func addToSolutions(_ value: Solution)

    @objc(removeSolutionsObject:)
    @NSManaged public func removeFromSolutions(_ value: Solution)

    @objc(addSolutions:)
    @NSManaged public func addToSolutions(_ values: NSSet)

    @objc(removeSolutions:)
    @NSManaged public func removeFromSolutions(_ values: NSSet)

}
