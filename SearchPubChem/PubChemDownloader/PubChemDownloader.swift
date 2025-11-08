//
//  PubChemDownloader.swift
//  SearchPubChem
//
//  Created by Jae Seung Lee on 7/1/23.
//  Copyright © 2023 Jae Seung Lee. All rights reserved.
//

import Foundation
import os

actor PubChemDownloader: PubChemDownloading {
    static let shared = PubChemDownloader()
    
    private let compoundProperties: [String] = [PubChemSearch.PropertyKey.formula, PubChemSearch.PropertyKey.weight, PubChemSearch.PropertyKey.nameIUPAC, PubChemSearch.PropertyKey.title]
    
    private let session: URLSession = URLSession.shared
    private let logger = Logger()
    
    func downloadProperties(identifier: String, identifierType: SearchType) async throws -> Properties {
        let url = url(for: identifier, type: identifierType)
        
        let data = try await dataTask(with: url)
        if let compoundDTO: CompoundDTO = self.decode(from: data) {
            return compoundDTO.propertyTable.properties[0]
        } else {
            self.logger.log("Cannot parse data=\(data, privacy: .public)")
            throw PubChemDownloadError.unableToParse
        }
    }
    
    func downloadImage(for cid: String) async throws -> Data {
        var component = commonURLComponents()
        component.path = PubChemSearch.Constant.pathForCID + cid + PubChemSearch.QueryResult.png
        return try await dataTask(with: component.url!)
    }
    
    func downloadConformer(for cid: String) async throws -> ConformerDTO {
        var component = commonURLComponents()
        component.path = PubChemSearch.Constant.pathForCID + cid + "/JSON"
        component.query = "\(PubChemSearch.QueryString.recordType)=\(PubChemSearch.RecordType.threeD)"
        
        let data = try await dataTask(with: component.url!)
        if let dto: ConformerDTO = self.decode(from: data) {
            return dto
        } else {
            self.logger.log("Cannot parse data=\(data, privacy: .public)")
            throw PubChemDownloadError.unableToParse
        }
    }
    
    private func url(for value: String, type: SearchType) -> URL {
        var pathForProperties = PubChemSearch.Constant.pathForProperties
        
        for property in compoundProperties {
            pathForProperties += property + ","
        }
        pathForProperties.remove(at: pathForProperties.index(before: pathForProperties.endIndex))
        pathForProperties += PubChemSearch.QueryResult.json
        
        var component = commonURLComponents()
        
        switch type {
        case .name:
            component.path = PubChemSearch.Constant.pathForName + value + pathForProperties
        case .cid:
            component.path = PubChemSearch.Constant.pathForCID + value + pathForProperties
        }
        
        logger.log("url=\(component.url!)")
        return component.url!
    }
    
    private func commonURLComponents() -> URLComponents {
        var component = URLComponents()
        component.scheme = PubChemSearch.Constant.scheme
        component.host = PubChemSearch.Constant.host
        return component
    }
    
    private func dataTask(with url: URL) async throws -> Data {
        let request = URLRequest(url: url, timeoutInterval: 15)
        
        let (data, response) = try await session.data(for: request)
        
        guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else {
            if let statusCode = (response as? HTTPURLResponse)?.statusCode {
                if let code = PubChemSearch.Status(rawValue: statusCode) {
                    var error: PubChemDownloadError
                    switch(code) {
                    case .badRequest:
                        error = .badRequest
                    case .notFound:
                        error = .notFound
                    case .notAllowed:
                        error = .notAllowed
                    case .serverBusy:
                        error = .serverBusy
                    case .timeOut:
                        error = .timeOut
                    default:
                        error = .other
                    }
                    throw error
                }
                throw PubChemDownloadError.other
            } else {
                throw PubChemDownloadError.noStatusCode
            }
        }
        
        return data
    }
    
    private func decode<T: Codable>(from data: Data) -> T? {
        let decoder = JSONDecoder()
        var dto: T
        do {
            dto = try decoder.decode(T.self, from: data)
        } catch {
            logger.log("Cannot parse data as type \(T.self)")
            return nil
        }
        return dto
    }
}
