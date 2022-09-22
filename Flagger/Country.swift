//
//  Country.swift
//  Flagger
//
//  Created by Andrej Lotski on 19.9.22.
//

import Foundation

struct Country: Decodable {
    let name: String
    let alpha2Code: String
    let capital: String?
    let population: Int64
}

extension Country: Identifiable {
    var id: String { alpha2Code }
}

struct CountryGuessModel {
    let countryToGuess: Country
    let possibleAnswers: [Country]
}
