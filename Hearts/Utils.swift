//
//  Utils.swift
//  Hearts
//
//  Created by Jordan Gardner on 10/2/24.
//

import SwiftUI

// UserDefaults storage keys
let MoonRuleKey = "MoonRules"
let SelectedAccentColorKey = "SelectedAccentColor"

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
