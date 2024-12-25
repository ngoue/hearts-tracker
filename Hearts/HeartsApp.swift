//
//  HeartsApp.swift
//  Hearts
//
//  Created by Jordan Gardner on 9/16/24.
//

import FirebaseCore
import SwiftUI
import TinyStorage

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        FirebaseApp.configure()

        // On first startup, set default settings. This is really just for
        // boolean settings that default to `true`, but figured it doesn't
        // hurt to insert the initial value for all persisted settings.
        if !TinyStorage.appGroup.bool(forKey: AppStorageKeys.initialized) {
            TinyStorage.appGroup.bulkStore(items: [
                AppStorageKeys.initialized: true,
                AppStorageKeys.moonRules: MoonRules.old,
                AppStorageKeys.selectedAccentColor: AccentColor.red,
            ], skipKeyIfAlreadyPresent: true)
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
