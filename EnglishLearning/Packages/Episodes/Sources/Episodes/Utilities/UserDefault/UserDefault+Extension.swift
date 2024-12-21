//
//  UserDefault+Extension.swift
//  Episodes
//
//  Created by Han Chen on 2024/12/21.
//

import Core
import Foundation

extension UserDefault {
    convenience init(
        wrappedValue: T,
        key: UserDefaultKey,
        store: UserDefaults? = nil
    ) {
        self.init(
            wrappedValue: wrappedValue,
            key: key.rawValue,
            notificationName: key.notificationName,
            store: store ?? .standard
        )
    }
}
