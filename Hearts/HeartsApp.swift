//
//  HeartsApp.swift
//  Hearts
//
//  Created by Jordan Gardner on 9/16/24.
//

import FirebaseCore
import SwiftUI

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        FirebaseApp.configure()

        // On first startup, set default settings. This is really just for
        // boolean settings that default to `true`, but figured it doesn't
        // hurt to insert the initial value for all persisted settings.
        if !UserDefaults.standard.bool(forKey: InitialSetupKey) {
            UserDefaults.standard.set(MoonRules.Old.rawValue, forKey: MoonRuleKey)
            UserDefaults.standard.set(true, forKey: SavePlayerNamesKey)
            UserDefaults.standard.set(AccentColor.Red.rawValue, forKey: SelectedAccentColorKey)
            // Mark intial setup complete
            UserDefaults.standard.set(true, forKey: InitialSetupKey)
        }

        return true
    }
}

@main
struct HeartsApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
