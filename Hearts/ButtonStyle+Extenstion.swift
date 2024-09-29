//
//  NoOpacityButtonStyle.swift
//  Hearts
//
//  Created by Jordan Gardner on 9/29/24.
//

import SwiftUI

struct NoOpacityButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(1.0) // Set opacity to 1.0 always, even when pressed
    }
}
