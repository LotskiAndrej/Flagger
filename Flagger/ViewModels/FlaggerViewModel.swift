//
//  FlaggerViewModel.swift
//  Flagger
//
//  Created by Andrej Lotski on 19.9.22.
//

import SwiftUI

enum FlaggerViewModelState {
    case loading, error, success, none
}

enum GameMode: String {
    case easy = "Easy"
    case medium = "Medium"
    case hard = "Hard"
}

class FlaggerViewModel: ObservableObject {
    @Published var countries = [Country]()
    @Published var state: FlaggerViewModelState = .none
    @Published var activeGameMode: GameMode?
    @Published var highScores = [GameMode: Int]()
    @Published var bestTimes = [GameMode: Int]()
    private let flagService = FlagService()
    
    @MainActor
    func fetchAllCountries() async throws {
        if state != .success {
            withAnimation {
                state = .loading
            }
            countries = try await flagService.fetchCountries().sorted { $0.population > $1.population }
            withAnimation {
                state = .success
            }
        }
    }
    
    func createCountryGuessModels(for gameMode: GameMode) -> ([Country], [CountryGuessModel]) {
        let countries = getCountries(for: gameMode)
        
        var countryGuessModels = [CountryGuessModel]()
        for country in countries {
            let possibleAnswers = createPossibleAnswers(for: country)
            let model = CountryGuessModel(countryToGuess: country, possibleAnswers: possibleAnswers)
            countryGuessModels.append(model)
        }
        
        return (countries, countryGuessModels)
    }
    
    func getCountries(for gameMode: GameMode) -> [Country] {
        switch gameMode {
        case .easy:
            return Array(countries.filter { $0.population > 15000000 }.shuffled().prefix(20))
        case .medium:
            return Array(countries.filter { $0.population > 1000000 && $0.population <= 15000000 }
                .shuffled()
                .prefix(20))
        case .hard:
            return Array(countries.filter { $0.population <= 1000000 }.shuffled().prefix(20))
        }
    }
    
    private func createPossibleAnswers(for country: Country) -> [Country] {
        var answers = Array(countries.filter { $0.id != country.id }.shuffled().prefix(3))
        answers.append(country)
        return answers.shuffled()
    }
    
    class func createFlagURL(with alpha2Code: String?) -> URL? {
        guard let alpha2Code = alpha2Code else { return nil }
        let endpoint = "https://flagcdn.com/h240/\(alpha2Code.lowercased()).jpg"
        return URL(string: endpoint)
    }
    
    class func prefetchNextImage(alpha2Code: String) async -> Image? {
        guard let url = FlaggerViewModel.createFlagURL(with: alpha2Code) else { return nil }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            guard let uiImage = UIImage(data: data) else { return nil }
            return Image(uiImage: uiImage)
            
        } catch { return nil }
    }
}
