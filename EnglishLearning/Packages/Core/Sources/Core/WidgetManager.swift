//
//  WidgetManager.swift
//  Core
//
//  Created by Han Chen on 2024/12/26.
//

import Foundation
import WidgetKit

public protocol WidgetManagerable {
    func reloadAllTimelines()
}

public struct WidgetManager: WidgetManagerable {
    public init() {}
    
    public func reloadAllTimelines() {
        WidgetCenter.shared.reloadAllTimelines()
    }
}
