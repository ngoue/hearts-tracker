//
//  ContentView.swift
//  Hearts
//
//  Created by Jordan Gardner on 9/16/24.
//

import FirebaseAnalytics
import SwiftUI

@Observable
class Player: Identifiable {
    let id = UUID()
    var score: Int = 0
    var playerIndex: Int
    var name: String {
        didSet {
            savePlayerName(playerIndex: self.playerIndex, name: self.name)
        }
    }

    init(playerIndex: Int) {
        self.playerIndex = playerIndex
        self.name = loadPlayerName(playerIndex: playerIndex)
    }
}

class GameModel: ObservableObject {
    // Persisted settings/state
    @AppStorage(MoonRuleKey) var moonRules: MoonRules = .Old
    @AppStorage(SavePlayerNamesKey) var savePlayerNames: Bool = true
    @AppStorage(SelectedAccentColorKey) var selectedAccentColor: AccentColor = .Red

    // Ephemeral settings/state
    @Published var showSettings = false
    @Published var showResetAlert = false
    @Published var isEditing = false
    @Published var round = 0 {
        didSet {
            if self.round < 0 {
                self.round = 0
            }
        }
    }

    let players = [
        Player(playerIndex: 1),
        Player(playerIndex: 2),
        Player(playerIndex: 3),
        Player(playerIndex: 4),
    ]

    func shootTheMoon(player: Player) {
        if self.moonRules == .Old {
            self.players.forEach { otherPlayer in
                if player.id != otherPlayer.id {
                    otherPlayer.score += 26
                }
            }
        } else {
            player.score -= 26
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

    func nextRound() {
        withAnimation {
            self.round += 1
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

    func reset() {
        Analytics.logEvent(AnalyticsEventReset, parameters: nil)
        self.round = 0
        self.players.forEach { player in
            player.score = 0
        }
    }
}

struct Settings: View {
    @EnvironmentObject var game: GameModel
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

    var body: some View {
        NavigationView {
            Form {
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
                        self.game.moonRules == .Old
                            ? "The shooter scores 0 points and each opponent scores 26 points"
                            : "The shooter scores -26 points"
                    )
                }

                Section {
                    Toggle("Save Player Names", isOn: self.$game.savePlayerNames)
                } footer: {
                    Text(self.game.savePlayerNames ? "Player names save when you close the app" : "Player names reset when you close the app")
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
        }
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
            .disabled(self.game.isEditing)
            Button(action: {
                if self.game.isEditing {
                    Analytics.logEvent(AnalyticsEventEditDoneButtonTapped, parameters: nil)
                } else {
                    Analytics.logEvent(AnalyticsEventEditButtonTapped, parameters: nil)
                }
                withAnimation {
                    self.game.isEditing.toggle()
                }
            }) {
                Label(self.game.isEditing ? "Done" : "Edit", systemImage: self.game.isEditing ? "checkmark.circle.fill" : "pencil.circle.fill")
                    .font(.largeTitle)
                    .labelStyle(.iconOnly)
                    .symbolRenderingMode(.hierarchical)
            }
            .contentTransition(.symbolEffect(.replace))
            Button(action: {
                Analytics.logEvent(AnalyticsEventResetButtonTapped, parameters: nil)
                self.game.showResetAlert = true
            }) {
                Label("Reset", systemImage: "arrow.clockwise.circle.fill")
                    .font(.largeTitle)
                    .labelStyle(.iconOnly)
                    .symbolRenderingMode(.hierarchical)
            }
            .disabled(self.game.isEditing)
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
                buttons: [.destructive(Text("Reset"), action: self.game.reset), .cancel()]
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
        } else if !self.game.isEditing && self.isDealer() {
            return false
        } else if !self.game.isEditing && self.playerNumber() == self.game.roundIndex() {
            return false
        }
        return true
    }

    var body: some View {
        HStack(alignment: .center, spacing: self.spacing) {
            if self.game.isEditing {
                TextField("Player \(self.playerNumber())", text: self.$player.name)
                    .textFieldStyle(.roundedBorder)
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                Text(self.playerName())
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .lineLimit(1)
            }

            Text("\(self.player.score)")
                .font(.largeTitle)

            VStack(spacing: self.buttonSpacing) {
                HStack(spacing: self.buttonSpacing) {
                    Button(action: {
                        self.player.score += self.game.isEditing ? -1 : 1
                    }) {
                        Text(self.game.isEditing ? "-1" : "+1")
                            .font(.headline)
                            .frame(width: self.buttonSize, height: self.buttonSize)
                            .foregroundColor(Color.white)
                            .background(Circle().fill(Color.accentColor))
                    }

                    Button(action: {
                        self.player.score += self.game.isEditing ? -5 : 5
                    }) {
                        Text(self.game.isEditing ? "-5" : "+5")
                            .font(.headline)
                            .frame(width: self.buttonSize, height: self.buttonSize)
                            .foregroundColor(Color.white)
                            .background(Circle().fill(Color.accentColor))
                    }
                }
                HStack(spacing: self.buttonSpacing) {
                    Button(action: {
                        self.player.score += self.game.isEditing ? -13 : 13
                    }) {
                        Text(self.game.isEditing ? "-13" : "+13")
                            .font(.headline)
                            .frame(width: self.buttonSize, height: self.buttonSize)
                            .foregroundColor(Color.white)
                            .background(Circle().fill(Color.accentColor))
                    }

                    Button(action: {
                        self.game.shootTheMoon(player: self.player)
                        self.moonBounce += 1
                    }) {
                        Label("Shoot the moon", systemImage: "moon.circle.fill")
                            .font(.system(size: self.buttonSize))
                            .frame(width: self.buttonSize, height: self.buttonSize)
                            .foregroundStyle(Color.white, Color.accentColor)
                    }
                    .symbolEffect(.bounce, value: self.moonBounce)
                    .labelStyle(.iconOnly)
                    .disabled(self.game.isEditing)
                }
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.horizontal)
        .padding(.vertical, self.spacing)
        .background(!self.game.isEditing && self.isDealer() ? Color.accentColor.opacity(0.15) : .clear)
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
            .disabled(self.game.round == 0 || self.game.isEditing)

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
            .disabled(self.game.isEditing)
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
        .environmentObject(self.game)
        .accentColor(self.game.tintColor())
    }
}

#Preview {
    ContentView()
}
