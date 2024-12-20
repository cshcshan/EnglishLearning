//
//  UserDefault.swift
//  Core
//
//  Created by Han Chen on 2024/12/20.
//

import Foundation

@propertyWrapper
public final class UserDefault<T: Codable> {
    public var wrappedValue: T {
        get {
            guard let data = store.object(forKey: key) as? Data else { return defaultValue }
            let value = try? JSONDecoder().decode(T.self, from: data)
            return value ?? defaultValue
        }
        set {
            let value = try? JSONEncoder().encode(newValue)
            store.set(value, forKey: key)
            
            NotificationCenter.default.post(name: notificationName, object: nil)
        }
    }
    
    private let defaultValue: T
    private let key: String
    private let notificationName: Notification.Name
    private let store: UserDefaults
    
    public init(
        wrappedValue: T,
        key: String,
        notificationName: Notification.Name,
        store: UserDefaults = .standard
    ) {
        self.defaultValue = wrappedValue
        self.key = key
        self.notificationName = notificationName
        self.store = store
    }
}
