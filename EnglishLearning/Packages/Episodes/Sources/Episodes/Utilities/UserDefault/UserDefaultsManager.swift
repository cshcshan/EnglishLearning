//
//  UserDefaultsManager.swift
//  Episodes
//
//  Created by Han Chen on 2024/12/21.
//

import Core
import Foundation

struct UserDefaultsManager: UserDefaultsManagerable {
    @UserDefault(key: .favoriteEpisodeIDs)
    var favoriteEpisodeIDs: Set<String> = []
    
    init(store: UserDefaults?) {
        // `@UserDefault` can't directly accept a custom store passed into the initializer, so we
        // re-initialize the property wrapper here to inject the store
        _favoriteEpisodeIDs = UserDefault(wrappedValue: [], key: .favoriteEpisodeIDs, store: store)
    }
}
