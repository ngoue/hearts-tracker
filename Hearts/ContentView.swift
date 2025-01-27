//
//  ContentView.swift
//  Hearts
//
//  Created by Jordan Gardner on 9/16/24.
//

import ConfettiSwiftUI
import FirebaseAnalytics
import SwiftUI
import TinyStorage

@Observable
class Player: Identifiable {
    let id = UUID()
    var playerIndex: Int
    var name: String {
        didSet {
            savePlayerName(playerIndex: self.playerIndex, name: self.name)
        }
    }

    var scores: [Int] {
        didSet {
            savePlayerScores(playerIndex: self.playerIndex, scores: self.scores)
        }
    }

    var totalScore: Int {
        return self.scores.reduce(0, +)
    }

    init(playerIndex: Int) {
        self.playerIndex = playerIndex
        if let scores = loadPlayerScores(playerIndex: playerIndex) {
            self.scores = scores
        } else {
            self.scores = [0]
        }
        if let name = loadPlayerName(playerIndex: playerIndex) {
            self.name = name
        } else {
            self.name = ""
        }
    }

    func roundScore(_ round: Int) -> Int {
        return round > self.scores.count ? 0 : self.scores[round]
    }

    func runningScore(_ round: Int) -> Int {
        return self.scores.prefix(round).reduce(0, +)
    }

    func adjustPoints(_ points: Int, for round: Int) {
        if self.scores.count < round + 1 {
            self.scores.append(points)
        } else {
            self.scores[round] += points
        }
    }

    func resetRound(_ round: Int) {
        self.scores[round] = 0
    }

    func reset() {
        self.scores = [0]
    }
}

class GameModel: ObservableObject {
    // Persisted settings/state
    @TinyStorageItem(AppStorageKeys.moonRules, storage: .appGroup)
    var moonRules: MoonRules = .old
    @TinyStorageItem(AppStorageKeys.selectedAccentColor, storage: .appGroup)
    var selectedAccentColor: AccentColor = .red
    @TinyStorageItem(AppStorageKeys.round, storage: .appGroup)
    var round = 0 {
        didSet {
            if self.round < 0 {
                self.round = 0
            }
        }
    }

    // Ephemeral settings/state
    @Published var showSettings = false
    @Published var showResetAlert = false
    @Published var showGameOver = false

    var players = [
        Player(playerIndex: 1),
        Player(playerIndex: 2),
        Player(playerIndex: 3),
        Player(playerIndex: 4),
    ]

    var totalScore: Int {
        return self.players
            .map { $0.scores[self.round] }
            .reduce(0, +)
    }

    var pointsRemaining: Int {
        return max(26 - abs(self.totalScore), 0)
    }

    func shootTheMoon(player: Player) {
        if self.totalScore != 0 {
            return
        }

        if self.moonRules == .old {
            self.players.forEach { otherPlayer in
                if player.id != otherPlayer.id {
                    otherPlayer.adjustPoints(26, for: self.round)
                }
            }
        } else {
            player.adjustPoints(-26, for: self.round)
        }
    }

    func dealer() -> Player {
        return self.players[self.roundIndex()]
    }

    func tintColor() -> Color {
        return AccentColor.colorForAccent(accent: self.selectedAccentColor)
    }

    func actionLabel() -> String {
        switch self.roundIndex() {
        case 0:
            return "Pass left"
        case 1:
            return "Pass right"
        case 2:
            return "Pass across"
        case 3:
            return "Hold"
        default:
            return "Dance"
        }
    }

    func roundLabel() -> String {
        return "Round \(self.round + 1)"
    }

    func isRoundComplete() -> Bool {
        // 26 -> all points awarded
        // -26 -> new rules shoot the moon
        // 78 -> old rules shoo the moon
        return self.totalScore == 26 || self.totalScore == -26 || self.totalScore == 78
    }

    func nextRound() {
        if self.isRoundComplete() {
            withAnimation {
                for player in self.players {
                    // make sure there is a round score initialized before moving on
                    if player.scores.count <= self.round + 1 {
                        player.adjustPoints(0, for: self.round + 1)
                    }

                    // end the game!
                    if player.runningScore(self.round + 1) >= 100 {
                        self.showGameOver = true
                    }
                }
                self.round += 1
            }
        }
    }

    func previousRound() {
        withAnimation {
            self.round -= 1
        }
    }

    func roundIndex() -> Int {
        return self.round % 4
    }

    func getPlayerRanks() -> [(Player, String, Int)] {
        let sortedPlayers = self.players.sorted { $0.totalScore < $1.totalScore }
        var ranks: [(Player, String, Int)] = []
        var currentRank = 1
        var lastScore = sortedPlayers.first?.totalScore ?? 0
        var rankCount = 0

        for player in sortedPlayers {
            let score = player.totalScore

            if score == lastScore {
                rankCount += 1
            } else {
                currentRank += rankCount
                rankCount = 1
                lastScore = score
            }

            let rankString = self.getRankString(for: currentRank)
            ranks.append((player, rankString, player.totalScore))
        }

        return ranks
    }

    func getRankString(for rank: Int) -> String {
        switch rank {
        case 1:
            return "🥇"
        case 2:
            return "🥈"
        case 3:
            return "🥉"
        default:
            return "💩"
        }
    }

    func reset() {
        self.round = 0
        self.players.forEach { player in
            player.reset()
        }
    }
}

struct Settings: View {
    @EnvironmentObject var game: GameModel
    @State var playerNames: [String] = ["", "", "", ""]
    @FocusState var focusedField: Int?
    let availableColors: [Color] = [.red, .blue, .green]

    func sendFeedback() {
        Analytics.logEvent(AnalyticsEventSendFeedback, parameters: nil)
        let email = "jordanthomasg@icloud.com"
        let subject = "Hearts Scoreboard Feedback"
        if let url = URL(string: "mailto:\(email)?subject=\(subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")") {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            }
        }
    }

    func nextPlayerNameField(current: Int) {
        if current < self.game.players.count {
            self.focusedField = current + 1
        } else {
            self.focusedField = nil
        }
    }

    var body: some View {
        NavigationView {
            Form {
                Section {
                    ForEach(self.playerNames.indices, id: \.self) { index in
                        TextField("Player \(index + 1)", text: self.$playerNames[index])
                            .focused(self.$focusedField, equals: index)
                            .submitLabel(index < self.playerNames.count - 1 ? .next : .done)
                            .onSubmit {
                                self.nextPlayerNameField(current: index)
                            }
                    }

                    Button(action: {
                        Analytics.logEvent(AnalyticsEventResetPlayerNames, parameters: nil)
                        for player in self.game.players {
                            player.name = ""
                            TinyStorage.appGroup.remove(key: "PlayerName\(player.playerIndex)")
                        }
                        self.playerNames = ["", "", "", ""]
                    }) {
                        Text("Reset Names")
                    }
                    .foregroundColor(.red)
                }

                Section {
                    Picker(selection: self.$game.moonRules) {
                        ForEach(MoonRules.allCases) { rule in
                            Text(rule.rawValue.capitalized)
                        }
                    } label: {
                        Text("Shoot the Moon Rules")
                    }
                    .onChange(of: self.game.moonRules) { prev, tag in
                        Analytics.logEvent(AnalyticsEventMoonRulesChanged, parameters: [
                            AnalyticsParameterPreviousMoonRule: prev.rawValue,
                            AnalyticsParameterSelectedMoonRule: tag.rawValue,
                        ])
                    }
                } footer: {
                    Text(
                        self.game.moonRules == .old
                            ? "The shooter scores 0 points and each opponent scores 26 points"
                            : "The shooter scores -26 points"
                    )
                }

                Section {
                    HStack(alignment: .center) {
                        Text("Accent Color")
                        Spacer()
                        HStack(spacing: 0) {
                            ForEach(AccentColor.allCases) { accent in
                                Button {
                                    let previous = self.game.selectedAccentColor
                                    self.game.selectedAccentColor = accent
                                    Analytics.logEvent(AnalyticsEventAccentColorChanged, parameters: [
                                        AnalyticsParameterPreviousAccentColor: previous.rawValue,
                                        AnalyticsParameterSelectedAccentColor: accent.rawValue,
                                    ])
                                } label: {
                                    Label("\(accent) accent", systemImage: "circle.fill")
                                        .font(.system(size: 40.0))
                                        .labelStyle(.iconOnly)
                                        .foregroundStyle(AccentColor.colorForAccent(accent: accent))
                                        .symbolRenderingMode(.monochrome)
                                        .overlay {
                                            self.game.selectedAccentColor == accent
                                                ? Circle().stroke(AccentColor.colorForAccent(accent: accent), lineWidth: 2.0).opacity(0.5)
                                                : nil
                                        }
                                }
                                .buttonStyle(NoOpacityButtonStyle())
                            }
                        }
                    }
                } footer: {
                    Text("Change the accent color to spice things up")
                }

                Section {
                    Button(action: {
                        self.sendFeedback()
                    }) {
                        Label("Send Feedback", systemImage: "envelope.fill")
                    }
                    LabeledContent("App Version", value: Bundle.main.appVersionLong)
                    LabeledContent("App Build", value: Bundle.main.appBuild)
                }
            }
            .navigationTitle("Settings")
            .onAppear {
                self.playerNames = self.game.players.map(\.name)
            }
            .onDisappear {
                for (index, name) in self.playerNames.enumerated() {
                    self.game.players[index].name = name
                }
            }
        }
    }
}

struct GameOver: View {
    @EnvironmentObject var game: GameModel
    @State var dismissAnalyticsEvent = AnalyticsEventKeepPlaying
    @State var trigger: Int = 0

    var body: some View {
        NavigationView {
            Form {
                Section {
                    ForEach(self.game.getPlayerRanks(), id: \.0.id) { player, rank, score in
                        LabeledContent("\(rank) \(player.name.isEmpty ? "Player \(player.playerIndex)" : player.name)", value: String(score))
                    }
                }

                Section {
                    Button(action: {
                        self.dismissAnalyticsEvent = AnalyticsEventKeepPlaying
                        self.game.showGameOver.toggle()
                    }) {
                        Text("Keep Playing")
                    }

                    Button(action: {
                        self.dismissAnalyticsEvent = AnalyticsEventNewGame
                        self.game.showGameOver.toggle()
                        self.game.reset()
                    }) {
                        Text("New Game")
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Game Over")
        }
        .onAppear {
            Analytics.logEvent(AnalyticsEventGameOver, parameters: nil)
            self.trigger += 1
        }
        .onDisappear {
            Analytics.logEvent(self.dismissAnalyticsEvent, parameters: nil)
        }
        .confettiCannon(trigger: self.$trigger, confettis: [.text("❤️"), .text("💙"), .text("💚"), .text("💜")])
    }
}

struct HeaderActions: View {
    @EnvironmentObject var game: GameModel

    var body: some View {
        HStack {
            Text("Hearts").font(.largeTitle).fontWeight(.heavy)
            Spacer()
            Button(action: {
                Analytics.logEvent(AnalyticsEventSettingsButtonTapped, parameters: nil)
                withAnimation {
                    self.game.showSettings.toggle()
                }
            }) {
                Label("Settings", systemImage: "gearshape.circle.fill")
                    .font(.largeTitle)
                    .labelStyle(.iconOnly)
                    .symbolRenderingMode(.hierarchical)
            }
            Button(action: {
                Analytics.logEvent(AnalyticsEventResetButtonTapped, parameters: nil)
                self.game.showResetAlert = true
            }) {
                Label("Reset", systemImage: "arrow.clockwise.circle.fill")
                    .font(.largeTitle)
                    .labelStyle(.iconOnly)
                    .symbolRenderingMode(.hierarchical)
            }
        }
        .padding()
        .sheet(isPresented: self.$game.showSettings) {
            Settings()
                .presentationDetents([.large])
        }
        .actionSheet(isPresented: self.$game.showResetAlert) {
            ActionSheet(
                title: Text("Reset Game"),
                message: Text("Are you sure you want to reset the game?"),
                buttons: [
                    .destructive(Text("Reset"), action: {
                        Analytics.logEvent(AnalyticsEventReset, parameters: nil)
                        self.game.reset()
                    }),
                    .cancel(),
                ]
            )
        }
    }
}

struct PlayerView: View {
    @EnvironmentObject var game: GameModel
    @State var player: Player
    @State private var moonBounce: Int = 0
    let compact: Bool

    var spacing: CGFloat {
        self.compact ? 10.0 : 20.0
    }

    var buttonSize: CGFloat {
        self.compact ? 45.0 : 50.0
    }

    var buttonSpacing: CGFloat {
        self.compact ? 5.0 : 7.0
    }

    func isDealer() -> Bool {
        return self.player.id == self.game.dealer().id
    }

    func playerName() -> String {
        return self.player.name.isEmpty ? "Player \(self.playerNumber())" : self.player.name
    }

    func roundScoreLabel() -> String {
        let score = self.player.roundScore(self.game.round)
        return score > 0 ? "+\(score)" : String(score)
    }

    func runningScoreLabel() -> String {
        if self.game.round == 0 {
            return "0"
        } else {
            return String(self.player.runningScore(self.game.round))
        }
    }

    func playerNumber() -> Int {
        if let index = self.game.players.firstIndex(where: { $0.id == self.player.id }) {
            return index + 1
        } else {
            return -1
        }
    }

    func needsBottomBorder() -> Bool {
        if self.playerNumber() == 4 {
            return false
        } else if self.isDealer() {
            return false
        } else if self.playerNumber() == self.game.roundIndex() {
            return false
        }
        return true
    }

    var body: some View {
        HStack(alignment: .center, spacing: self.spacing) {
            VStack {
                HStack {
                    Text(self.playerName())
                        .font(.headline)
                        .lineLimit(1)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                HStack {
                    Text(self.runningScoreLabel())
                        .font(.largeTitle)
                        .bold()
                        .lineLimit(1)
                    if self.player.roundScore(self.game.round) != 0 {
                        Text(self.roundScoreLabel())
                            .font(.title)
                            .bold()
                            .foregroundColor(self.game.tintColor())
                            .lineLimit(1)
                    }
                    VStack(spacing: self.buttonSpacing) {
                        HStack(spacing: self.buttonSpacing) {
                            Button(action: {
                                self.player.adjustPoints(1, for: self.game.round)
                            }) {
                                Text("+1")
                                    .font(.headline)
                                    .frame(width: self.buttonSize, height: self.buttonSize)
                                    .foregroundColor(Color.white)
                                    .background(Circle().fill(Color.accentColor))
                            }
                            .disabled(self.player.roundScore(self.game.round) >= 25 || self.game.pointsRemaining < 1)

                            Button(action: {
                                self.player.adjustPoints(5, for: self.game.round)
                            }) {
                                Text("+5")
                                    .font(.headline)
                                    .frame(width: self.buttonSize, height: self.buttonSize)
                                    .foregroundColor(Color.white)
                                    .background(Circle().fill(Color.accentColor))
                            }
                            .disabled(self.player.roundScore(self.game.round) >= 21 || self.game.pointsRemaining < 5)

                            Button(action: {
                                self.player.adjustPoints(13, for: self.game.round)
                            }) {
                                Text("+13")
                                    .font(.headline)
                                    .frame(width: self.buttonSize, height: self.buttonSize)
                                    .foregroundColor(Color.white)
                                    .background(Circle().fill(Color.accentColor))
                            }
                            .disabled(self.player.roundScore(self.game.round) >= 13 || self.game.pointsRemaining < 13)

                            Button(action: {
                                if self.game.totalScore == 0 {
                                    // shoot the moon
                                    self.game.shootTheMoon(player: self.player)
                                } else {
                                    // reset score to 0 - additionally, reset all players if this was a moon shot
                                    let roundScore = self.player.roundScore(self.game.round)
                                    if roundScore == 26 {
                                        for player in self.game.players {
                                            player.resetRound(self.game.round)
                                        }
                                    } else {
                                        self.player.resetRound(self.game.round)
                                    }
                                }
                                self.moonBounce += 1
                            }) {
                                Label(self.game.totalScore == 0 ? "Shoot the moon" : "Reset round score", systemImage: self.game.totalScore == 0 ? "moon.circle.fill" : "arrow.clockwise.circle.fill")
                                    .font(.system(size: self.buttonSize))
                                    .frame(width: self.buttonSize, height: self.buttonSize)
                                    .foregroundStyle(Color.white, Color.accentColor)
                            }
                            .symbolEffect(.bounce, value: self.moonBounce)
                            .labelStyle(.iconOnly)
                            .disabled(self.game.totalScore != 0 && self.player.roundScore(self.game.round) == 0)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, self.spacing)
        .background(self.isDealer() ? Color.accentColor.opacity(0.15) : .clear)
        .overlay(alignment: .bottom) {
            self.needsBottomBorder()
                ? Rectangle()
                .frame(height: 1)
                .foregroundColor(.secondary.opacity(0.15))
                : nil
        }
    }
}

struct FooterActions: View {
    @EnvironmentObject var game: GameModel

    var body: some View {
        HStack {
            Button(action: {
                Analytics.logEvent(AnalyticsEventPreviousRoundButtonTapped, parameters: nil)
                self.game.previousRound()
            }) {
                Label("Previous round", systemImage: "chevron.left.circle.fill")
                    .font(.largeTitle)
                    .labelStyle(.iconOnly)
                    .symbolRenderingMode(.hierarchical)
            }
            .disabled(self.game.round == 0)

            Spacer()

            VStack {
                Text(self.game.roundLabel()).font(.caption)
                Rectangle().frame(width: 20.0, height: 1.0).foregroundColor(.secondary)
                Text(self.game.actionLabel())
            }

            Spacer()

            Button(action: {
                Analytics.logEvent(AnalyticsEventNextRoundButtonTapped, parameters: nil)
                self.game.nextRound()
            }) {
                Label("Next round", systemImage: "chevron.right.circle.fill")
                    .font(.largeTitle)
                    .labelStyle(.iconOnly)
                    .symbolRenderingMode(.hierarchical)
            }
            .disabled(!self.game.isRoundComplete())
        }
        .padding()
    }
}

struct ContentView: View {
    @StateObject var game = GameModel()
    let compactSize: CGFloat = 700.0

    var body: some View {
        GeometryReader { geometry in
            VStack {
                HeaderActions()

                Spacer()

                VStack(spacing: .zero) {
                    ForEach(self.game.players) { player in
                        PlayerView(player: player, compact: geometry.size.height < self.compactSize)
                    }
                }

                Spacer()

                FooterActions()
            }
        }
        .sheet(isPresented: self.$game.showGameOver) {
            GameOver()
                .presentationDetents([.large])
        }
        .background(Color(UIColor.secondarySystemBackground))
        .environmentObject(self.game)
        .accentColor(self.game.tintColor())
    }
}

#Preview {
    ContentView()
}
