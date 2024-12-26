//
//  MockWidgetManager.swift
//  Episodes
//
//  Created by Han Chen on 2024/12/26.
//

import Core
import Foundation

final class MockWidgetManager: WidgetManagerable {
    var reloadAllTimelinesCount = 0
    
    func reloadAllTimelines() {
        reloadAllTimelinesCount += 1
    }
}
