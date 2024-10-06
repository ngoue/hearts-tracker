//
//  Bundle+Extension.swift
//  Hearts
//
//  Credit: https://stackoverflow.com/a/68912269/2419130
//
//  Created by Jordan Gardner on 10/6/24.
//

import SwiftUI

public extension Bundle {
    var appName: String { getInfo("CFBundleName") }
    var displayName: String { getInfo("CFBundleDisplayName") }
    var language: String { getInfo("CFBundleDevelopmentRegion") }
    var identifier: String { getInfo("CFBundleIdentifier") }
    var copyright: String { getInfo("NSHumanReadableCopyright").replacingOccurrences(of: "\\\\n", with: "\n") }

    var appBuild: String { getInfo("CFBundleVersion") }
    var appVersionLong: String { getInfo("CFBundleShortVersionString") }
    var appVersionShort: String { getInfo("CFBundleShortVersion") }

    fileprivate func getInfo(_ str: String) -> String { infoDictionary?[str] as? String ?? "⚠️" }
}
