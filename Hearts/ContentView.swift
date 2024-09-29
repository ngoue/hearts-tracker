//
//  ContentView.swift
//  Hearts
//
//  Created by Jordan Gardner on 9/16/24.
//

import SwiftUI

@Observable
class Player: Identifiable {
    let id = UUID()
    var name: String = ""
    var score: Int = 0 {
        didSet {
            if self.score < 0 {
                self.score = 0
            }
        }
    }
}

@Observable
class GameModel: ObservableObject {
    var accentColor: Color = .red
    var isEditing = false
    var round = 0 {
        didSet {
            if self.round < 0 {
                self.round = 0
            }
        }
    }

    let players = [
        Player(),
        Player(),
        Player(),
        Player(),
    ]

    func shootTheMoon(player: Player) {
        self.players.forEach { otherPlayer in
            if player.id != otherPlayer.id {
                otherPlayer.score += 26
            }
        }
    }

    func dealer() -> Player {
        return self.players[self.roundIndex()]
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
        self.round = 0
        self.players.forEach { player in
            player.score = 0
        }
    }
}

struct Settings: View {
    @EnvironmentObject var game: GameModel
    let availableColors: [Color] = [.red, .blue, .green]

    var body: some View {
        VStack {
            Text("Settings")

            Spacer()

            HStack {
                Text("Accent color")
                Spacer()
                HStack(spacing: 0) {
                    ForEach(self.availableColors, id: \.self) { color in
                        Button {
                            self.game.accentColor = color
                        } label: {
                            Label("\(color) accent", systemImage: "circle.fill")
                                .font(.system(size: 40.0))
                                .labelStyle(.iconOnly)
                                .foregroundStyle(color)
                                .symbolRenderingMode(.monochrome)
                                .overlay {
                                    self.game.accentColor == color
                                        ? Circle().stroke(color, lineWidth: 2.0).opacity(0.5)
                                        : nil
                                }
                        }
                        .buttonStyle(NoOpacityButtonStyle())
                    }
                }
            }

            Spacer()
        }
        .padding()
    }
}

struct HeaderActions: View {
    @EnvironmentObject var game: GameModel
    @State private var showSettings = false
    @State private var showResetAlert = false

    var body: some View {
        HStack {
            Text("Hearts").font(.largeTitle).fontWeight(.heavy)
            Spacer()
            Button(action: {
                withAnimation {
                    self.showSettings.toggle()
                }
            }) {
                Label("Settings", systemImage: "gearshape.circle.fill")
                    .font(.largeTitle)
                    .labelStyle(.iconOnly)
                    .symbolRenderingMode(.hierarchical)
            }
            .disabled(self.game.isEditing)
            Button(action: {
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
                self.showResetAlert = true
            }) {
                Label("Reset", systemImage: "arrow.clockwise.circle.fill")
                    .font(.largeTitle)
                    .labelStyle(.iconOnly)
                    .symbolRenderingMode(.hierarchical)
            }
            .disabled(self.game.isEditing)
        }
        .padding()
        .sheet(isPresented: self.$showSettings) {
            Settings()
                .presentationDetents([.large])
        }
        .actionSheet(isPresented: self.$showResetAlert) {
            ActionSheet(
                title: Text("Reset Game"),
                message: Text("Are you sure you want to reset the game?"),
                buttons: [.destructive(Text("Reset"), action: self.game.reset), .cancel()]
            )
        }
    }
}

struct FooterActions: View {
    @EnvironmentObject var game: GameModel

    var body: some View {
        HStack {
            Button(action: self.game.previousRound) {
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

            Button(action: self.game.nextRound) {
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
            } else {
                Text(self.playerName())
                    .font(.headline)
            }

            Spacer()

            Text("\(self.player.score)")
                .font(.largeTitle)

            Spacer()

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
        .accentColor(self.game.accentColor)
    }
}

#Preview {
    ContentView()
}
