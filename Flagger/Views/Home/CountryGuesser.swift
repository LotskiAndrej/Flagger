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
    private var timeForGame: Double = 0
    @State private var countries = [Country]()
    @State private var countryGuessModels = [CountryGuessModel]()
    @State private var selectedAnswer: Country?
    @State private var guessingIndex = 0
    @State private var highScore = 0
    @State private var resetFlag = false
    @State private var currentImage: Image?
    @State private var nextImage: Image?
    @State private var timeRemaining: Double
    @State private var timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    @State private var totalTime: Double = 0
    @State private var shouldStartGame = false
    @State private var firstFetchComplete = false
    
    init(viewModel: FlaggerViewModel, gameMode: GameMode) {
        self.viewModel = viewModel
        self.gameMode = gameMode
        
        switch gameMode {
        case .easy:
            timeForGame = 20
        case .medium:
            timeForGame = 10
        case .hard:
            timeForGame = 5
        }
        
        timeRemaining = timeForGame
    }
    
    var body: some View {
        ZStack {
            if !shouldStartGame {
                VStack {
                    
                    if firstFetchComplete {
                        Button {
                            shouldStartGame = true
                        } label: {
                            Text("Start")
                                .foregroundColor(.white)
                                .font(.title2)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .overlay {
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(.white, lineWidth: 1)
                                }
                        }
                        .padding(.bottom)
                        
                    } else {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(.white)
                    }
                }
                
            } else {
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
            }
        }
        .background(.clear)
        .onAppear {
            let (countries, countryGuessModels) = viewModel.createCountryGuessModels(for: gameMode)
            self.countries = countries
            self.countryGuessModels = countryGuessModels
            
            Task {
                await prefetchFirstTask()
                currentImage = nextImage
                firstFetchComplete = true
            }
        }
    }
    
    private var informationView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Flag: \(guessingIndex + 1) / \(countryGuessModels.count)")
            Text("Score: \(highScore)")
            Text("Time remaining: \(timeRemaining, specifier: "%.1f")s")
                .onReceive(timer) { _ in
                    if timeRemaining - 0.1 > 0 {
                        timeRemaining -= 0.1
                        
                    } else {
                        goToNextFlag(answer: nil)
                    }
                }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .font(.title3)
        .foregroundColor(.white)
    }
    
    private var flagView: some View {
        AsyncImage(url: FlaggerViewModel
            .createFlagURL(with: countryGuessModels[guessingIndex].countryToGuess.cca2)) { image in
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
                }
                
                EmptyView()
                    .onChange(of: guessingIndex) { _ in
                        if nextImage != nil {
                            currentImage = nextImage
                        } else {
                            resetFlag = true
                            currentImage = nil
                        }
                    }
                
        } placeholder: {
            ProgressView()
                .progressViewStyle(.circular)
                .tint(.white)
                .onAppear { timer.upstream.connect().cancel() }
                .onDisappear { timer = timer.upstream.autoconnect() }
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
            let code = countryGuessModels[guessingIndex + 1].countryToGuess.cca2
            nextImage = await FlaggerViewModel.prefetchNextImage(alpha2Code: code)
        }
    }
    
    private func prefetchFirstTask() async {
        let code = countryGuessModels[guessingIndex].countryToGuess.cca2
        nextImage = await FlaggerViewModel.prefetchNextImage(alpha2Code: code)
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
                    .overlay {
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(.green.opacity(0.5), lineWidth: selectedAnswer!.id == possibleAnswer.id ? 15 : 0)
                    }
            } else if answeredWrong {
                RoundedRectangle(cornerRadius: 10)
                    .foregroundColor(.red)
                    .overlay {
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(.red.opacity(0.5), lineWidth: selectedAnswer!.id == possibleAnswer.id ? 15 : 0)
                    }
            } else {
                RoundedRectangle(cornerRadius: 10)
                    .foregroundColor(.white)
                    .opacity(selectedAnswer != nil ? 0.3 : 1)
            }
            
            if !countryGuessModels.isEmpty, let name = possibleAnswer.name.common {
                Text(name)
                    .font(.title2)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.5)
                    .foregroundColor(answeredCorrectly || answeredWrong ? .white : .black)
                    .padding(8)
                    .opacity(!(!answeredCorrectly && !answeredWrong) || selectedAnswer == nil ? 1 : 0.3)
            }
        }
        .frame(height: 92)
        .padding(4)
        .onTapGesture { tapped(answer: possibleAnswer) }
    }
    
    private func tapped(answer: Country) {
        if selectedAnswer == nil {
            timer.upstream.connect().cancel()
            selectedAnswer = answer
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
                goToNextFlag(answer: answer)
            }
        }
    }
    
    private func goToNextFlag(answer: Country?) {
        selectedAnswer = nil
        totalTime += timeForGame - timeRemaining
        timeRemaining = timeForGame
        
        if let answer = answer, countryGuessModels[guessingIndex].countryToGuess.id == answer.id {
            highScore += 1
        }
        
        if guessingIndex + 1 < countries.count {
            guessingIndex += 1
            timer = timer.upstream.autoconnect()
            
        } else {
            guessingIndex = 0
            
            if highScore > viewModel.highScores[gameMode] ?? 0 {
                viewModel.highScores[gameMode] = highScore
                UserDefaults.standard.set(highScore, forKey: "HIGHSCORE:\(gameMode.rawValue)")
            }
            
            if viewModel.bestTimes[gameMode] == nil || totalTime < viewModel.bestTimes[gameMode] ?? 0 {
                viewModel.bestTimes[gameMode] = totalTime
                UserDefaults.standard.set(totalTime, forKey: "BESTTIME:\(gameMode.rawValue)")
            }
            
            viewModel.activeGameMode = nil
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
