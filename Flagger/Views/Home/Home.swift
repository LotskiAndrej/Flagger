//
//  Home.swift
//  Flagger
//
//  Created by Andrej Lotski on 16.9.22.
//

import SwiftUI
import CoreData

struct Home: View {
    @ObservedObject var viewModel: FlaggerViewModel
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack {
                Text("Flagger")
                    .font(.custom("SignPaintohDemo",
                                  size: viewModel.state != .success || viewModel.activeGameMode != nil ? 50 : 90))
                    .foregroundColor(.white)
                    .offset(y: viewModel.state != .success || viewModel.activeGameMode != nil ? 0 : 250)
                    .padding(.top)
                
                VStack(spacing: 60) {
                    if viewModel.state == .loading || viewModel.state == .none {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(.white)
                        
                    } else if viewModel.state == .error {
                        Text("An unknown error occurred.")
                            .foregroundColor(.white)
                        
                    } else if viewModel.state == .success, let gameModeStarted = viewModel.activeGameMode {
                        CountryGuesser(viewModel: viewModel, gameMode: gameModeStarted)
                        
                    } else {
                        Spacer()
                        
                        VStack {
                            highScoreView(gameMode: .easy)
                            highScoreView(gameMode: .medium)
                            highScoreView(gameMode: .hard)
                        }
                        .padding(.top, 32)
                        
                        VStack(spacing: 16) {
                            buttonView(for: .easy)
                            buttonView(for: .medium)
                            buttonView(for: .hard)
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .padding(.horizontal)
            .padding(.bottom)
            .background(
                Gradient(colors: [
                    .cyan, .indigo, .indigo
                ])
            )
            
            if viewModel.activeGameMode != nil {
                Button {
                    withAnimation {
                        viewModel.activeGameMode = nil
                    }
                } label: {
                    Image(systemName: "xmark")
                        .resizable()
                        .frame(width: 25, height: 25)
                        .fontWeight(.light)
                        .foregroundColor(.white)
                }
                .padding([.top, .trailing], 24)
            }
        }
    }
    
    private func highScoreView(gameMode: GameMode) -> Text? {
        let highScore = UserDefaults.standard.integer(forKey: "HIGHSCORE:\(gameMode.rawValue)")
        let bestTime = UserDefaults.standard.double(forKey: "BESTTIME:\(gameMode.rawValue)")
        
        if highScore > 0, bestTime > 0 {
            return Text("\(gameMode.rawValue): \(highScore) flags in \(bestTime, specifier: "%.2f") seconds")
                .font(.title3)
                .foregroundColor(.white)
        } else { return nil }
    }
    
    private func buttonView(for gameMode: GameMode) -> some View {
        Button {
            withAnimation {
                viewModel.activeGameMode = gameMode
            }
        } label: {
            Text("\(gameMode.rawValue)")
                .font(.title2)
                .padding()
                .frame(maxWidth: .infinity)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(.white, lineWidth: 1)
                )
        }
        .foregroundColor(.white)
    }
}

struct Home_Previews: PreviewProvider {
    @ObservedObject static var viewModel = FlaggerViewModel()
    
    static var previews: some View {
        VStack {
            Home(viewModel: viewModel)
        }
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
