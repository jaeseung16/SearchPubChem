//
//  PubChemDownloadError.swift
//  SearchPubChem
//
//  Created by Jae Seung Lee on 7/1/23.
//  Copyright © 2023 Jae Seung Lee. All rights reserved.
//

import Foundation

enum PubChemDownloadError: LocalizedError {
    case badRequest
    case notFound
    case notAllowed
    case serverBusy
    case timeOut
    case noStatusCode
    case noData
    case unableToParse
    case other
    
    public var errorDescription: String? {
        switch self {
        case .badRequest:
            return "Request is improperly formed"
        case .notFound:
            return "The input record was not found"
        case .notAllowed:
            return "Request not allowed"
        case .serverBusy:
            return "Too many requests or server is busy"
        case .timeOut:
            return "The request timed out"
        case .noStatusCode:
            return "Didn't receive any status code"
        case .noData:
            return "No data was returned by the request"
        case .unableToParse:
            return "Can't parse downloaded data"
        case .other:
            return "Your request returned a stauts code other than 2xx"
        }
    }
}
