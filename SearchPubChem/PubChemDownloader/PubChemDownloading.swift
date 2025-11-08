//
//  PubChemDownloading.swift
//  SearchPubChem
//
//  Created by Jae Seung Lee on 7/2/23.
//  Copyright © 2023 Jae Seung Lee. All rights reserved.
//

import Foundation

protocol PubChemDownloading: Actor {
    func downloadProperties(identifier: String, identifierType: SearchType) async throws -> Properties
    func downloadImage(for cid: String) async throws -> Data
    func downloadConformer(for cid: String) async throws -> ConformerDTO
}
