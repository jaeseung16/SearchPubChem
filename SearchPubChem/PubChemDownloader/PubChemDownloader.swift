//
//  PubChemDownloader.swift
//  SearchPubChem
//
//  Created by Jae Seung Lee on 7/1/23.
//  Copyright © 2023 Jae Seung Lee. All rights reserved.
//

import Foundation
import os

class PubChemDownloader: PubChemDownloading {
    static var shared = PubChemDownloader()
    
    private let compoundProperties: [String] = [PubChemSearch.PropertyKey.formula, PubChemSearch.PropertyKey.weight, PubChemSearch.PropertyKey.nameIUPAC, PubChemSearch.PropertyKey.title]
    
    private let session: URLSession = URLSession.shared
    private let logger = Logger()
    
    func downloadProperties(identifier: String, identifierType: SearchType, completionHandler: @escaping (Result<Properties, Error>) -> Void) -> Void {
        let url = url(for: identifier, type: identifierType)
        
        _ = dataTask(with: url) { result in
            switch result {
            case .success(let data):
                if let compoundDTO: CompoundDTO = self.decode(from: data) {
                    completionHandler(.success(compoundDTO.propertyTable.properties[0]))
                } else {
                    self.logger.log("Cannot parse data=\(data, privacy: .public)")
                    completionHandler(.failure(PubChemDownloadError.unableToParse))
                }
            case .failure(let error):
                completionHandler(.failure(error))
            }
        }
    }
    
    func downloadImage(for cid: String, completionHandler: @escaping (Result<Data, Error>) -> Void) -> Void {
        var component = commonURLComponents()
        component.path = PubChemSearch.Constant.pathForCID + cid + PubChemSearch.QueryResult.png
        
        _ = dataTask(with: component.url!) { result in
            switch result {
            case .success(let data):
                completionHandler(.success(data))
            case .failure(let error):
                completionHandler(.failure(error))
            }
        }
    }
    
    func downloadConformer(for cid: String, completionHandler: @escaping (Result<ConformerDTO, Error>) -> Void) {
        var component = commonURLComponents()
        component.path = PubChemSearch.Constant.pathForCID + cid + "/JSON"
        component.query = "\(PubChemSearch.QueryString.recordType)=\(PubChemSearch.RecordType.threeD)"
        
        _ = dataTask(with: component.url!) { result in
            switch result {
            case .success(let data):
                if let dto: ConformerDTO = self.decode(from: data) {
                    completionHandler(.success(dto))
                } else {
                    self.logger.log("Cannot parse data=\(data, privacy: .public)")
                    completionHandler(.failure(PubChemDownloadError.unableToParse))
                }
            case .failure(let error):
                completionHandler(.failure(error))
            }
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
    
    private func dataTask(with url: URL, completionHandler: @escaping (Result<Data, Error>) -> Void) -> URLSessionTask {
        let request = URLRequest(url: url, timeoutInterval: 15)
        
        let task = session.dataTask(with: request) { (data, response, error) in
            if let error = error {
                completionHandler(.failure(error))
                return
            }
            
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
                        completionHandler(.failure(error))
                    }
                } else {
                    completionHandler(.failure(PubChemDownloadError.noStatusCode))
                }
                return
            }
            
            guard let data = data else {
                completionHandler(.failure(PubChemDownloadError.noData))
                return
            }
            
            completionHandler(.success(data))
        }
        
        task.resume()
        return task
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
