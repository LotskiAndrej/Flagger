//
//  Errors.swift
//  Flagger
//
//  Created by Andrej Lotski on 19.9.22.
//

import Foundation

enum Errors: Error {
    case fetchCountriesURL
    case fetchCountriesResponse
    
    var message: String {
        switch self {
        case .fetchCountriesURL: return "Could not construct URL."
        case .fetchCountriesResponse: return "Failed to fetch countries."
        }
    }
}
