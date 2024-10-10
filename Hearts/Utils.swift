//
//  Utils.swift
//  Hearts
//
//  Created by Jordan Gardner on 10/2/24.
//

import SwiftUI

// UserDefaults storage keys
let InitialSetupKey = "InitialSetup"
let MoonRuleKey = "MoonRules"
let SavePlayerNamesKey = "SavePlayerNames"
let SelectedAccentColorKey = "SelectedAccentColor"

func savePlayerName(playerIndex: Int, name: String) {
    UserDefaults.standard.set(name, forKey: "PlayerName\(playerIndex)")
}

func loadPlayerName(playerIndex: Int) -> String {
    let savePlayerNames = UserDefaults.standard.bool(forKey: SavePlayerNamesKey)

    if !savePlayerNames {
        return ""
    }

    let savedName = UserDefaults.standard.string(forKey: "PlayerName\(playerIndex)")
    return savedName ?? ""
}

// Settings enums
enum MoonRules: String, CaseIterable, Identifiable {
    case Old
    case New

    var id: Self { self }
}

enum AccentColor: String, CaseIterable, Identifiable {
    case Red
    case Blue
    case Green

    var id: Self { self }

    static func colorForAccent(accent: AccentColor) -> Color {
        switch accent {
        case .Red:
            return .red
        case .Blue:
            return .blue
        case .Green:
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
