//
//  UserDefaultsManagerable.swift
//  Episodes
//
//  Created by Han Chen on 2024/12/21.
//

import Foundation

public protocol UserDefaultsManagerable {
    var favoriteEpisodeIDs: Set<String> { get set }
}
