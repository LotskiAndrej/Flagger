//
//  Country.swift
//  Flagger
//
//  Created by Andrej Lotski on 19.9.22.
//

import Foundation

struct Country: Decodable {
    let name: Name
    let cca2: String
    let capital: [String]?
    let population: Int64
    
    struct Name: Decodable {
        let common: String
    }
}

extension Country: Identifiable {
    var id: String { cca2 }
}

struct CountryGuessModel {
    let countryToGuess: Country
    let possibleAnswers: [Country]
}
