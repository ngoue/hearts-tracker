//
//  AccentColor.swift
//  Hearts
//
//  Created by Jordan Gardner on 10/2/24.
//

import SwiftUI

enum AccentColor: String {
    case Red
    case Blue
    case Green

    static func all() -> [AccentColor] {
        return [
            .Red,
            .Blue,
            .Green
        ]
    }

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
