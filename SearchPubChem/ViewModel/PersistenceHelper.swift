//
//  PersistenceHelper.swift
//  SearchPubChem
//
//  Created by Jae Seung Lee on 7/2/23.
//  Copyright © 2023 Jae Seung Lee. All rights reserved.
//

import Foundation
import CoreData
import os
import Persistence

class PersistenceHelper {
    private static let logger = Logger()
    
    private let persistence: Persistence
    var viewContext: NSManagedObjectContext {
        persistence.container.viewContext
    }
    
    init(persistence: Persistence) {
        self.persistence = persistence
    }
    
    func save(completionHandler: @escaping (Result<Void, Error>) -> Void) -> Void {
        persistence.save { completionHandler($0) }
    }
    
    func delete(_ object: NSManagedObject) -> Void {
        viewContext.delete(object)
    }
   
}
