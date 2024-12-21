//
//  UserDefaultKey.swift
//  Episodes
//
//  Created by Han Chen on 2024/12/21.
//

import Foundation

enum UserDefaultKey: String {
    case favoriteEpisodeIDs
}

extension UserDefaultKey {
    var notificationName: Notification.Name {
        Notification.Name("UserDefaults-\(rawValue)DidSet")
    }
}
