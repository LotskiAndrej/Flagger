//
//  FlagService.swift
//  Flagger
//
//  Created by Andrej Lotski on 19.9.22.
//

import Foundation

class FlagService {
    private lazy var urlSession: URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 10
        configuration.timeoutIntervalForResource = 30
        return URLSession(configuration: configuration)
    }()
    
    func fetchCountries() async throws -> [Country] {
        let endpoint = "https://restcountries.com/v3.1/all"
        
        guard let url = URL(string: endpoint) else {
            throw Errors.fetchCountriesURL
        }
        
        let (data, response) = try await urlSession.data(from: url)
        
        guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
            throw Errors.fetchCountriesResponse
        }
        
        return try JSONDecoder().decode([Country].self, from: data)
    }
}
