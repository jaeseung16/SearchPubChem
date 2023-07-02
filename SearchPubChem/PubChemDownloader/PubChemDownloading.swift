//
//  PubChemDownloading.swift
//  SearchPubChem
//
//  Created by Jae Seung Lee on 7/2/23.
//  Copyright © 2023 Jae Seung Lee. All rights reserved.
//

import Foundation

protocol PubChemDownloading {
    func downloadProperties(identifier: String, identifierType: SearchType, completionHandler: @escaping (Result<Properties, Error>) -> Void) -> Void
    func downloadImage(for cid: String, completionHandler: @escaping (Result<Data, Error>) -> Void) -> Void
    func downloadConformer(for cid: String, completionHandler: @escaping (Result<ConformerDTO, Error>) -> Void)
}
