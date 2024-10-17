//
//  TinyStorage+Extension.swift
//  Hearts
//
//  Created by Jordan Gardner on 10/16/24.
//

import TinyStorage
import SwiftUI

extension TinyStorage {
    static let appGroup: TinyStorage = {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return .init(insideDirectory: documentsURL, name: StorageName)
    }()
}
