//
//  HistoryToken.swift
//  SearchPubChem
//
//  Created by Jae Seung Lee on 5/25/22.
//  Copyright © 2022 Jae Seung Lee. All rights reserved.
//

import Foundation
import CoreData

class HistoryToken {
    static let shared = HistoryToken()
    
    static private let pathComponent = "token.data"
    
    var last: NSPersistentHistoryToken? = nil {
        didSet {
            guard let token = last,
                  let data = try? NSKeyedArchiver.archivedData(withRootObject: token, requiringSecureCoding: true) else {
                return
            }
            
            do {
                try data.write(to: tokenFile)
            } catch {
                let message = "Could not write token data"
                print("###\(#function): \(message): \(error)")
            }
        }
    }
    
    private lazy var tokenFile: URL = {
        let url = NSPersistentContainer.defaultDirectoryURL().appendingPathComponent(SearchPubChemConstants.appPathComponent.rawValue, isDirectory: true)
        if !FileManager.default.fileExists(atPath: url.path) {
            do {
                try FileManager.default.createDirectory(at: url,
                                                        withIntermediateDirectories: true,
                                                        attributes: nil)
            } catch {
                let message = "Could not create persistent container URL"
                print("###\(#function): \(message): \(error)")
            }
        }
        return url.appendingPathComponent(HistoryToken.pathComponent, isDirectory: false)
    }()
}

