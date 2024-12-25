//
//  FileManager+Extension.swift
//  EnglishLearning
//
//  Created by Han Chen on 2024/12/25.
//

import Foundation

extension FileManager {
    var appGroup: URL? {
        self.containerURL(
            forSecurityApplicationGroupIdentifier: Configuration.groupID
        )
    }
}
