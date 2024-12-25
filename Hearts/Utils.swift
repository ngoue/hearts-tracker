//
//  Utils.swift
//  Hearts
//
//  Created by Jordan Gardner on 10/2/24.
//

import SwiftUI
import TinyStorage

let StorageName = "tiny-storage-general-prefs"

enum AppStorageKeys: String, TinyStorageKey {
    case initialized
    case moonRules
    case selectedAccentColor
    case round
}

func savePlayerName(playerIndex: Int, name: String) {
    TinyStorage.appGroup.store(name, forKey: "PlayerName\(playerIndex)")
}

func loadPlayerName(playerIndex: Int) -> String? {
    return TinyStorage.appGroup.retrieve(type: String.self, forKey: "PlayerName\(playerIndex)")
}

func savePlayerScores(playerIndex: Int, scores: [Int]) {
    TinyStorage.appGroup.store(scores, forKey: "PlayerScores\(playerIndex)")
}

func loadPlayerScores(playerIndex: Int) -> [Int]? {
    return TinyStorage.appGroup.retrieve(type: [Int].self, forKey: "PlayerScores\(playerIndex)")
}

enum MoonRules: String, CaseIterable, Identifiable, Codable {
    case old
    case new

    var id: Self { self }
}

enum AccentColor: String, CaseIterable, Identifiable, Codable {
    case red
    case blue
    case green

    var id: Self { self }

    static func colorForAccent(accent: AccentColor) -> Color {
        switch accent {
        case .red:
            return .red
        case .blue:
            return .blue
        case .green:
            return .green
        }
    }
}

// Analytics Events
let AnalyticsEventSendFeedback = "send_feedback"
let AnalyticsEventSettingsButtonTapped = "settings_tapped"
let AnalyticsEventEditButtonTapped = "edit_tapped"
let AnalyticsEventEditDoneButtonTapped = "edit_done_tapped"
let AnalyticsEventResetButtonTapped = "reset_tapped"
let AnalyticsEventReset = "reset"
let AnalyticsEventMoonRulesChanged = "moon_rules_changed"
let AnalyticsEventAccentColorChanged = "accent_color_changed"
let AnalyticsEventNextRoundButtonTapped = "next_round_tapped"
let AnalyticsEventPreviousRoundButtonTapped = "previous_round_tapped"

// Analytics Parameters
let AnalyticsParameterPreviousMoonRule = "previous_moon_rule"
let AnalyticsParameterSelectedMoonRule = "selected_moon_rule"
let AnalyticsParameterPreviousAccentColor = "previous_accent_color"
let AnalyticsParameterSelectedAccentColor = "selected_accent_color"
