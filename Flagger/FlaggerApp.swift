//
//  FlaggerApp.swift
//  Flagger
//
//  Created by Andrej Lotski on 16.9.22.
//

import SwiftUI

@main
struct FlaggerApp: App {
    @ObservedObject private var viewModel = FlaggerViewModel()
    
    var body: some Scene {
        WindowGroup {
            Home(viewModel: viewModel)
                .colorScheme(.light)
                .onAppear {
                    Task {
                        do {
                            try await viewModel.fetchAllCountries()
                        } catch {
                            viewModel.state = .error
                        }
                    }
                }
        }
    }
}
