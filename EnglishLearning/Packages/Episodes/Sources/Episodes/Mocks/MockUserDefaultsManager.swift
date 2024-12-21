//
//  MockUserDefaultsManager.swift
//  Episodes
//
//  Created by Han Chen on 2024/12/21.
//

import Foundation

struct MockUserDefaultsManager: UserDefaultsManagerable {
    var favoriteEpisodeIDs: Set<String> = []
}
