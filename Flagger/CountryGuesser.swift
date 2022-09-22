//
//  CountryGuesser.swift
//  Flagger
//
//  Created by Andrej Lotski on 19.9.22.
//

import SwiftUI

struct CountryGuesser: View {
    @ObservedObject var viewModel: FlaggerViewModel
    let gameMode: GameMode
    @State private var countries = [Country]()
    @State private var countryGuessModels = [CountryGuessModel]()
    @State private var selectedAnswer: Country?
    @State private var guessingIndex = 0
    @State private var highScore = 0
    @State private var scale = 1.0
    @State private var resetFlag = false
    @State private var currentImage: Image?
    @State private var nextImage: Image?
    
    var body: some View {
        VStack {
            if !countryGuessModels.isEmpty {
                Spacer()
                
                informationView
                
                Spacer()
                
                flagView
                
                Spacer()
                
                answersView
            } else {
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(.white)
            }
        }
        .background(.clear)
        .onAppear {
            let (countries, countryGuessModels) = viewModel.createCountryGuessModels(for: gameMode)
            self.countries = countries
            self.countryGuessModels = countryGuessModels
        }
    }
    
    private var informationView: some View {
        VStack(spacing: 16) {
            Text("Flag: \(guessingIndex + 1) / \(countryGuessModels.count)")
            Text("Highscore: \(highScore)")
        }
        .font(.title2)
        .foregroundColor(.white)
    }
    
    private var flagView: some View {
        AsyncImage(url: FlaggerViewModel
            .createFlagURL(with: countryGuessModels[guessingIndex].countryToGuess.alpha2Code)) { image in
                if currentImage != nil {
                    currentImage!
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .onAppear {
                            Task { await prefetchTask() }
                        }
                        .onChange(of: currentImage) { _ in
                            Task { await prefetchTask() }
                        }
                } else {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .shadow(color: .black.opacity(0.5), radius: 20)
                        .onAppear {
                            Task { await prefetchTask() }
                        }
                }
                
                EmptyView()
                    .onChange(of: guessingIndex) { _ in
                        withAnimation(.linear(duration: 0.1)) {
                            if nextImage != nil {
                                currentImage = nextImage
                            } else {
                                resetFlag = true
                                currentImage = nil
                            }
                        }
                    }
                
        } placeholder: {
            ProgressView()
                .progressViewStyle(.circular)
                .tint(.white)
        }
        .frame(maxWidth: 200, maxHeight: 150)
    }
    
    private var answersView: some View {
        HStack {
            VStack {
                answerButtonView(index: 0)
                answerButtonView(index: 1)
            }
            
            VStack {
                answerButtonView(index: 2)
                answerButtonView(index: 3)
            }
        }
    }
    
    private func prefetchTask() async {
        if guessingIndex + 1 < countries.count {
            let code = countryGuessModels[guessingIndex + 1].countryToGuess.alpha2Code
            nextImage = await FlaggerViewModel.prefetchNextImage(alpha2Code: code)
        }
    }
    
    private func answerButtonView(index: Int) -> some View {
        let correctAnswer = countryGuessModels[guessingIndex].countryToGuess
        let possibleAnswer = countryGuessModels[guessingIndex].possibleAnswers[index]
        
        let answeredCorrectly = selectedAnswer != nil && correctAnswer.id == possibleAnswer.id
        let answeredWrong = selectedAnswer != nil &&
        selectedAnswer!.id == possibleAnswer.id &&
        selectedAnswer!.id != correctAnswer.id
        
        return ZStack {
                if answeredCorrectly {
                    RoundedRectangle(cornerRadius: 10)
                        .foregroundColor(.green)
                        .scaleEffect(selectedAnswer!.id == possibleAnswer.id ? scale : 1.0)
                } else if answeredWrong {
                    RoundedRectangle(cornerRadius: 10)
                        .foregroundColor(.red)
                        .scaleEffect(selectedAnswer!.id == possibleAnswer.id ? scale : 1.0)
                } else {
                    RoundedRectangle(cornerRadius: 10)
                        .foregroundColor(.white)
                }
                
                if !countryGuessModels.isEmpty {
                    Text(possibleAnswer.name)
                        .font(.title2)
                        .multilineTextAlignment(.center)
                        .minimumScaleFactor(0.5)
                        .foregroundColor(answeredCorrectly || answeredWrong ? .white : .black)
                        .padding(8)
                }
            }
            .frame(height: 100)
            .onTapGesture { tapped(answer: possibleAnswer) }
    }
    
    private func tapped(answer: Country) {
        if selectedAnswer == nil {
            withAnimation(.linear(duration: 0.1)) {
                selectedAnswer = answer
                scale = 0.95
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                withAnimation(.linear(duration: 0.15)) {
                    selectedAnswer = nil
                    scale = 1.0
                }
                
                if countryGuessModels[guessingIndex].countryToGuess.id == answer.id {
                    highScore += 1
                }
                
                if guessingIndex + 1 < countries.count {
                    guessingIndex += 1
                } else {
                    guessingIndex = 0
                    
                    if highScore > viewModel.highScores[gameMode] ?? 0 {
                        viewModel.highScores[gameMode] = highScore
                        UserDefaults.standard.set(highScore, forKey: "\(gameMode.rawValue)")
                    }
                    
                    withAnimation {
                        viewModel.activeGameMode = nil
                    }
                }
            }
        }
    }
}

struct CountryGuesser_Previews: PreviewProvider {
    @ObservedObject static var viewModel = FlaggerViewModel()
    
    static var previews: some View {
        VStack {
            Home(viewModel: viewModel)
        }
        .onAppear {
            Task {
                do {
                    try await viewModel.fetchAllCountries()
                    viewModel.activeGameMode = .medium
                } catch {
                    viewModel.state = .error
                }
            }
        }
    }
}
