//
//  UserDefaults+Extension.swift
//  EnglishLearning
//
//  Created by Han Chen on 2024/12/21.
//

import Foundation

extension UserDefaults {
    static var appGroup: UserDefaults? {
        UserDefaults(suiteName: Configuration.groupID)
    }
}
