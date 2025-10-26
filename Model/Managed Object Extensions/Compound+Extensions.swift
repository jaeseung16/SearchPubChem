//
//  Compound+Extensions.swift
//  SearchPubChem
//
//  Created by Jae Seung Lee on 2/24/18.
//  Copyright © 2018 Jae Seung Lee. All rights reserved.
//

import Foundation
import CoreData

extension Compound {
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        created = Date()
    }
    
    public override func awakeFromFetch() {
        super.awakeFromFetch()
        
        guard let char = name?.first else {
            return
        }
        
        firstCharacterInName = String(char).uppercased()
    }
    
    public func isTagged(by tag: CompoundTag) -> Bool {
        guard let tags = self.tags else {
            return false
        }
        return tags.contains(tag)
    }
    
    public func nameContains(string: String) -> Bool {
        guard let name = self.name else {
            return false
        }
        return name.lowercased().contains(string.lowercased())
    }
    
    public var id: String {
        "\(cid ?? "")_\(created?.timeIntervalSince1970 ?? 0.0)"
    }
}
